import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/application_repository.dart';
import 'application_detail_widgets.dart';

class ApplicationsTab extends ConsumerStatefulWidget {
  const ApplicationsTab({super.key});

  @override
  ConsumerState<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends ConsumerState<ApplicationsTab> {
  late Future<List<RentalApplicationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RentalApplicationItem>> _load() =>
      ref.read(applicationRepositoryProvider).fetchMyApplications();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _future = _load();
      }),
      child: FutureBuilder<List<RentalApplicationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList();
          }
          if (snapshot.hasError) {
            return EmptyStateView(
              title: 'Could not load applications',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No applications yet',
              subtitle:
                  'Apply to an available house or shop and track the review here.',
              icon: Icons.assignment_outlined,
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.push('/user/application/${item.id}'),
                child: AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.property.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusChip(item.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item.property.addressLine),
                      const SizedBox(height: 10),
                      Text('Applied on ${formatDate(item.applicationDate)}'),
                      if ((item.adminRemarks ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Admin note: ${item.adminRemarks}'),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'View full details',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UserApplicationDetailScreen extends ConsumerStatefulWidget {
  const UserApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<UserApplicationDetailScreen> createState() =>
      _UserApplicationDetailScreenState();
}

class _UserApplicationDetailScreenState
    extends ConsumerState<UserApplicationDetailScreen> {
  late Future<RentalApplicationItem> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<RentalApplicationItem> _load() => ref
      .read(applicationRepositoryProvider)
      .fetchApplication(widget.applicationId);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Application details',
      body: RefreshIndicator(
        onRefresh: () async => setState(() {
          _future = _load();
        }),
        child: FutureBuilder<RentalApplicationItem>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingShimmerList(itemCount: 1);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return EmptyStateView(
                title: 'Could not load application',
                subtitle: snapshot.error.toString(),
                icon: Icons.error_outline_rounded,
              );
            }

            return ListView(
              children: [ApplicationDetailContent(application: snapshot.data!)],
            );
          },
        ),
      ),
    );
  }
}

class ApplicationFormScreen extends ConsumerStatefulWidget {
  const ApplicationFormScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'fullName': TextEditingController(),
    'fatherName': TextEditingController(),
    'mobileNumber': TextEditingController(),
    'alternateMobileNumber': TextEditingController(),
    'email': TextEditingController(),
    'currentAddress': TextEditingController(),
    'permanentAddress': TextEditingController(),
    'aadhaarNumber': TextEditingController(),
    'occupation': TextEditingController(),
    'monthlyIncome': TextEditingController(),
    'familyMembersCount': TextEditingController(),
    'businessType': TextEditingController(),
    'remarks': TextEditingController(),
  };
  final Map<String, PlatformFile> _documents = {};
  DateTime? _startDate;
  bool _submitting = false;

  static const _requiredLabels = [
    'Aadhaar card front',
    'Aadhaar card back',
    'Smart card / ration card',
    'Passport size photo',
    'Salary slip or income proof',
    'Address proof',
  ];

  static const _optionalLabels = [
    'PAN card',
    'Shop license proof',
    'Additional supporting document',
  ];

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDocument(String label) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: kIsWeb,
    );
    if (result == null) {
      return;
    }

    final file = result.files.single;
    if (file.bytes == null && (file.path == null || file.path!.isEmpty)) {
      return;
    }

    setState(() {
      _documents[label] = file;
    });
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate == null) {
      showAppSnackBar(context, 'Choose a rental start date', isError: true);
      return;
    }
    final missingDocs = _requiredLabels
        .where((label) => !_documents.containsKey(label))
        .toList();
    if (missingDocs.isNotEmpty) {
      showAppSnackBar(
        context,
        'Upload all required documents before submitting',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final documentIds = await ref
          .read(applicationRepositoryProvider)
          .uploadDocuments(
            _documents.entries
                .map(
                  (entry) =>
                      UploadableDocument(label: entry.key, file: entry.value),
                )
                .toList(),
          );

      await ref
          .read(applicationRepositoryProvider)
          .submitApplication(
            propertyId: widget.propertyId,
            remarks: _controllers['remarks']!.text.trim(),
            documentIds: documentIds,
            personalDetails: {
              'fullName': _controllers['fullName']!.text.trim(),
              'fatherName': _controllers['fatherName']!.text.trim(),
              'mobileNumber': _controllers['mobileNumber']!.text.trim(),
              'alternateMobileNumber': _controllers['alternateMobileNumber']!
                  .text
                  .trim(),
              'email': _controllers['email']!.text.trim(),
              'currentAddress': _controllers['currentAddress']!.text.trim(),
              'permanentAddress': _controllers['permanentAddress']!.text.trim(),
              'aadhaarNumber': _controllers['aadhaarNumber']!.text.trim(),
              'occupation': _controllers['occupation']!.text.trim(),
              'monthlyIncome':
                  num.tryParse(_controllers['monthlyIncome']!.text.trim()) ?? 0,
              'familyMembersCount':
                  int.tryParse(
                    _controllers['familyMembersCount']!.text.trim(),
                  ) ??
                  0,
              'businessType': _controllers['businessType']!.text.trim(),
              'requiredRentalStartDate': _startDate!.toIso8601String(),
            },
          );

      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Application submitted successfully');
      context.go('/user');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Rental application',
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text('Personal details'),
            const SizedBox(height: 14),
            ...[
              ('Full name', 'fullName', requiredValidator),
              ('Father / guardian name', 'fatherName', requiredValidator),
              ('Mobile number', 'mobileNumber', requiredValidator),
              (
                'Alternate mobile number',
                'alternateMobileNumber',
                requiredValidator,
              ),
              ('Email', 'email', emailValidator),
              ('Current address', 'currentAddress', requiredValidator),
              ('Permanent address', 'permanentAddress', requiredValidator),
              ('Aadhaar number', 'aadhaarNumber', aadhaarValidator),
              ('Occupation', 'occupation', requiredValidator),
              ('Monthly income', 'monthlyIncome', requiredValidator),
              ('Family members count', 'familyMembersCount', requiredValidator),
              ('Business type (for shops)', 'businessType', null),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  controller: _controllers[item.$2],
                  validator: item.$3,
                  keyboardType: item.$2 == 'email'
                      ? TextInputType.emailAddress
                      : item.$2.contains('income') ||
                            item.$2.contains('Count') ||
                            item.$2.contains('aadhaar')
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: item.$1),
                ),
              ),
            ),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(18),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Required rental start date',
                  suffixIcon: Icon(Icons.calendar_month_rounded),
                ),
                child: Text(
                  _startDate == null
                      ? 'Choose date'
                      : formatDate(_startDate!.toIso8601String()),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _controllers['remarks'],
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Remarks / notes'),
            ),
            const SizedBox(height: 22),
            Text(
              'Document uploads',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._requiredLabels.map(
              (label) => _DocumentTile(
                label: label,
                file: _documents[label],
                onTap: () => _pickDocument(label),
              ),
            ),
            const SizedBox(height: 8),
            Text('Optional', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._optionalLabels.map(
              (label) => _DocumentTile(
                label: label,
                file: _documents[label],
                onTap: () => _pickDocument(label),
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Submit application',
              onPressed: _submit,
              icon: Icons.send_rounded,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.label,
    required this.file,
    required this.onTap,
  });

  final String label;
  final PlatformFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSectionCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: file == null
                    ? const Color(0xFFF3F6F9)
                    : const Color(0xFFE7F7EF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                file == null
                    ? Icons.upload_file_rounded
                    : Icons.check_circle_rounded,
                color: file == null ? Colors.black54 : Colors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(file == null ? 'Tap to upload' : file!.name),
                ],
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(file == null ? 'Upload' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }
}
