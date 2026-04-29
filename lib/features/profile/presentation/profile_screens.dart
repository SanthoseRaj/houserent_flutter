import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../applications/data/application_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final user = session?.user;

    if (user == null) {
      return const EmptyStateView(
        title: 'Profile unavailable',
        subtitle: 'Please sign in again to restore your session.',
        icon: Icons.person_off_outlined,
      );
    }

    return ListView(
      children: [
        GlassHeader(title: user.name, subtitle: user.email),
        const SizedBox(height: 18),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('Phone: ${user.phone ?? '-'}'),
              Text('Occupation: ${user.occupation ?? '-'}'),
              Text('Current address: ${user.currentAddress ?? '-'}'),
              Text('Permanent address: ${user.permanentAddress ?? '-'}'),
              Text('Aadhaar: ${user.aadhaarNumber ?? '-'}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.support_agent_rounded),
                title: const Text('Complaints & maintenance'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/complaints'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Rental agreements'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/agreements'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen> {
  late Future<_ComplaintsViewData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ComplaintsViewData> _load() async {
    final complaints = await ref
        .read(profileRepositoryProvider)
        .fetchComplaints();
    final applications = await ref
        .read(applicationRepositoryProvider)
        .fetchMyApplications();
    return _ComplaintsViewData(
      complaints: complaints,
      applications: applications,
    );
  }

  Future<void> _openComplaintForm(_ComplaintsViewData data) async {
    if (data.applications.isEmpty) {
      showAppSnackBar(
        context,
        'No linked property available for complaint submission',
        isError: true,
      );
      return;
    }
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String propertyId = data.applications.first.property.id;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New complaint',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: propertyId,
                items: data.applications
                    .map<DropdownMenuItem<String>>(
                      (item) => DropdownMenuItem<String>(
                        value: item.property.id,
                        child: Text(item.property.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => propertyId = value ?? propertyId),
                decoration: const InputDecoration(labelText: 'Property'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'Submit complaint',
                onPressed: () async {
                  await ref
                      .read(profileRepositoryProvider)
                      .createComplaint(
                        propertyId: propertyId,
                        subject: subjectController.text.trim(),
                        description: descriptionController.text.trim(),
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted == true) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Complaints & support',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final data = await _future;
          if (mounted) {
            _openComplaintForm(data);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New complaint'),
      ),
      body: FutureBuilder<_ComplaintsViewData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList();
          }
          if (snapshot.hasError) {
            return EmptyStateView(
              title: 'Could not load complaints',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          final complaints = snapshot.data!.complaints;
          if (complaints.isEmpty) {
            return const EmptyStateView(
              title: 'No complaints raised',
              subtitle:
                  'You can submit maintenance issues, support requests and follow-ups from here.',
              icon: Icons.support_agent_outlined,
            );
          }

          return ListView.separated(
            itemCount: complaints.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            complaint.subject,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(complaint.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(complaint.propertyTitle),
                    const SizedBox(height: 8),
                    Text(complaint.description),
                    if ((complaint.adminReply ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Admin reply: ${complaint.adminReply}'),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AgreementsScreen extends ConsumerStatefulWidget {
  const AgreementsScreen({super.key});

  @override
  ConsumerState<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends ConsumerState<AgreementsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(profileRepositoryProvider).fetchAgreements();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Rental agreements',
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList();
          }
          if (snapshot.hasError) {
            return EmptyStateView(
              title: 'Could not load agreements',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          final agreements = snapshot.data ?? [];
          if (agreements.isEmpty) {
            return const EmptyStateView(
              title: 'No agreements uploaded',
              subtitle:
                  'Approved agreements shared by the admin will appear here.',
              icon: Icons.description_outlined,
            );
          }
          return ListView.separated(
            itemCount: agreements.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = agreements[index];
              return AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(item.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.propertyTitle),
                    const SizedBox(height: 8),
                    Text(
                      'From ${formatDate(item.startDate)} to ${formatDate(item.endDate)}',
                    ),
                    if ((item.fileUrl ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => launchUrl(Uri.parse(item.fileUrl!)),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Open document'),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ComplaintsViewData {
  const _ComplaintsViewData({
    required this.complaints,
    required this.applications,
  });

  final List<dynamic> complaints;
  final List<dynamic> applications;
}
