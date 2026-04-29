import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../applications/data/application_repository.dart';
import '../../applications/presentation/application_detail_widgets.dart';
import '../../notifications/data/notification_repository.dart';
import '../../payments/data/payment_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../properties/data/property_repository.dart';
import '../data/admin_repository.dart';

class AdminDashboardTab extends ConsumerStatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _future = ref.read(adminRepositoryProvider).fetchDashboard();
      }),
      child: FutureBuilder<DashboardSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList(itemCount: 4);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return EmptyStateView(
              title: 'Could not load dashboard',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          final data = snapshot.data!;
          return ListView(
            children: [
              const GlassHeader(
                title: 'Rental portfolio command center',
                subtitle:
                    'Monitor occupancy, applications, payments and tenant support from one place.',
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 760;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.18 : 0.92,
                    children: [
                      _StatTile(
                        label: 'Total properties',
                        value: '${data.totalProperties}',
                        icon: Icons.apartment_rounded,
                      ),
                      _StatTile(
                        label: 'Available',
                        value: '${data.availableProperties}',
                        icon: Icons.home_work_rounded,
                      ),
                      _StatTile(
                        label: 'Occupied',
                        value: '${data.occupiedProperties}',
                        icon: Icons.house_siding_rounded,
                      ),
                      _StatTile(
                        label: 'Pending applications',
                        value: '${data.pendingApplications}',
                        icon: Icons.assignment_rounded,
                      ),
                      _StatTile(
                        label: 'Approved tenants',
                        value: '${data.approvedTenants}',
                        icon: Icons.groups_rounded,
                      ),
                      _StatTile(
                        label: 'Monthly collection',
                        value: formatCurrency(data.monthlyRentCollection),
                        icon: Icons.payments_rounded,
                      ),
                      _StatTile(
                        label: 'Due payments',
                        value: '${data.duePayments}',
                        icon: Icons.warning_amber_rounded,
                      ),
                      _StatTile(
                        label: 'Complaints',
                        value: '${data.totalComplaints}',
                        icon: Icons.support_agent_rounded,
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PropertyCardCover extends StatelessWidget {
  const _PropertyCardCover({
    required this.imageUrl,
    required this.propertyType,
    required this.imageCount,
    required this.status,
  });

  final String? imageUrl;
  final String propertyType;
  final int imageCount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          SizedBox(
            height: 176,
            width: double.infinity,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _PropertyCardCoverPlaceholder(
                          propertyType: propertyType,
                        ),
                  )
                : _PropertyCardCoverPlaceholder(propertyType: propertyType),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.36),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                propertyType == 'shop' ? 'Shop space' : 'House listing',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(right: 14, top: 14, child: StatusChip(status)),
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                imageCount == 0
                    ? 'Add photos to make this card stand out'
                    : '$imageCount listing photo${imageCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCardCoverPlaceholder extends StatelessWidget {
  const _PropertyCardCoverPlaceholder({required this.propertyType});

  final String propertyType;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sky, AppColors.sand.withValues(alpha: 0.92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                propertyType == 'shop'
                    ? Icons.storefront_rounded
                    : Icons.house_siding_rounded,
                color: AppColors.navy,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Preview not added yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPropertiesTab extends ConsumerStatefulWidget {
  const AdminPropertiesTab({super.key});

  @override
  ConsumerState<AdminPropertiesTab> createState() => _AdminPropertiesTabState();
}

class _AdminPropertiesTabState extends ConsumerState<AdminPropertiesTab> {
  late Future<List<PropertyItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(propertyRepositoryProvider).fetchManagedProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => setState(() {
            _future = ref
                .read(propertyRepositoryProvider)
                .fetchManagedProperties();
          }),
          child: FutureBuilder<List<PropertyItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingShimmerList();
              }
              if (snapshot.hasError) {
                return EmptyStateView(
                  title: 'Could not load properties',
                  subtitle: snapshot.error.toString(),
                  icon: Icons.error_outline_rounded,
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const EmptyStateView(
                  title: 'No properties added',
                  subtitle:
                      'Use the add button to create the first house or shop listing.',
                  icon: Icons.add_home_work_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: items.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PropertyCardCover(
                          imageUrl: item.images.isNotEmpty
                              ? item.images.first
                              : null,
                          propertyType: item.type,
                          imageCount: item.images.length,
                          status: item.status,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (item.images.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sky,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${item.images.length} photo${item.images.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${item.addressLine}, ${item.city}'),
                        const SizedBox(height: 8),
                        Text(
                          formatCurrency(item.rent),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context.push(
                                '/admin/property-form',
                                extra: item,
                              ),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(propertyRepositoryProvider)
                                    .deleteProperty(item.id);
                                if (!context.mounted) {
                                  return;
                                }
                                showAppSnackBar(context, 'Property deleted');
                                setState(
                                  () => _future = ref
                                      .read(propertyRepositoryProvider)
                                      .fetchManagedProperties(),
                                );
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/admin/property-form'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add property'),
          ),
        ),
      ],
    );
  }
}

class AdminPropertyFormScreen extends ConsumerStatefulWidget {
  const AdminPropertyFormScreen({super.key, this.property});

  final PropertyItem? property;

  @override
  ConsumerState<AdminPropertyFormScreen> createState() =>
      _AdminPropertyFormScreenState();
}

class _AdminPropertyFormScreenState
    extends ConsumerState<AdminPropertyFormScreen> {
  static const _supportedImageExtensions = [
    'jpg',
    'jpeg',
    'jpe',
    'jfif',
    'png',
    'webp',
    'gif',
    'bmp',
    'avif',
    'tif',
    'tiff',
    'heic',
    'heif',
    'svg',
    'ico',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amenitiesController;
  late final TextEditingController _floorSizeController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _shopSizeController;
  late final TextEditingController _businessTypeController;
  String _type = 'house';
  String _status = 'available';
  final List<String> _existingImages = [];
  final List<PlatformFile> _newImages = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final property = widget.property;
    _titleController = TextEditingController(text: property?.title ?? '');
    _addressController = TextEditingController(
      text: property?.addressLine ?? '',
    );
    _cityController = TextEditingController(text: property?.city ?? '');
    _areaController = TextEditingController(text: property?.area ?? '');
    _rentController = TextEditingController(
      text: property?.rent.toString() ?? '',
    );
    _depositController = TextEditingController(
      text: property?.deposit.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: property?.description ?? '',
    );
    _amenitiesController = TextEditingController(
      text: property?.amenities.join(', ') ?? '',
    );
    _floorSizeController = TextEditingController(
      text: property?.floorSize ?? '',
    );
    _bedroomsController = TextEditingController(
      text: property?.bedrooms?.toString() ?? '',
    );
    _bathroomsController = TextEditingController(
      text: property?.bathrooms?.toString() ?? '',
    );
    _shopSizeController = TextEditingController(text: property?.shopSize ?? '');
    _businessTypeController = TextEditingController(
      text: property?.businessSuitability ?? '',
    );
    _type = property?.type ?? 'house';
    _status = property?.status ?? 'available';
    _existingImages.addAll(property?.images ?? const <String>[]);
  }

  @override
  void dispose() {
    for (final controller in [
      _titleController,
      _addressController,
      _cityController,
      _areaController,
      _rentController,
      _depositController,
      _descriptionController,
      _amenitiesController,
      _floorSizeController,
      _bedroomsController,
      _bathroomsController,
      _shopSizeController,
      _businessTypeController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _supportedImageExtensions,
      withData: true,
    );
    if (result == null) {
      return;
    }
    setState(() {
      _newImages.addAll(
        result.files.where(
          (file) =>
              file.bytes != null ||
              (file.path != null && file.path!.isNotEmpty),
        ),
      );
    });
  }

  void _removePickedImage(PlatformFile file) {
    setState(() => _newImages.remove(file));
  }

  void _removeExistingImageAt(int index) {
    setState(() => _existingImages.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final imageUrls = [..._existingImages];
      if (_newImages.isNotEmpty) {
        imageUrls.addAll(
          await ref
              .read(propertyRepositoryProvider)
              .uploadPropertyImages(_newImages),
        );
      }

      final property = PropertyItem(
        id: widget.property?.id ?? '',
        title: _titleController.text.trim(),
        type: _type,
        rent: num.tryParse(_rentController.text.trim()) ?? 0,
        deposit: num.tryParse(_depositController.text.trim()) ?? 0,
        description: _descriptionController.text.trim(),
        status: _status,
        addressLine: _addressController.text.trim(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        images: imageUrls,
        amenities: _amenitiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        floorSize: _floorSizeController.text.trim(),
        bedrooms: int.tryParse(_bedroomsController.text.trim()),
        bathrooms: int.tryParse(_bathroomsController.text.trim()),
        shopSize: _shopSizeController.text.trim(),
        businessSuitability: _businessTypeController.text.trim(),
        availableFrom: DateTime.now().toIso8601String(),
      );
      await ref
          .read(propertyRepositoryProvider)
          .saveProperty(property, id: widget.property?.id);
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Property saved successfully');
      context.pop();
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImages = _existingImages;
    final originalImageCount = widget.property?.images.length ?? 0;
    final removedImageCount = originalImageCount - existingImages.length;

    return AppScaffold(
      title: widget.property == null ? 'Add property' : 'Edit property',
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _titleController,
              validator: (value) => requiredValidator(value, label: 'Title'),
              decoration: const InputDecoration(labelText: 'Property title'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: const [
                DropdownMenuItem(value: 'house', child: Text('House')),
                DropdownMenuItem(value: 'shop', child: Text('Shop')),
              ],
              onChanged: (value) => setState(() => _type = value ?? 'house'),
              decoration: const InputDecoration(labelText: 'Property type'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              validator: (value) => requiredValidator(value, label: 'Address'),
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    validator: (value) =>
                        requiredValidator(value, label: 'City'),
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(labelText: 'Area'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rentController,
                    validator: (value) =>
                        requiredValidator(value, label: 'Rent'),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rent amount'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _depositController,
                    validator: (value) =>
                        requiredValidator(value, label: 'Deposit'),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Deposit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              validator: (value) =>
                  requiredValidator(value, label: 'Description'),
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amenitiesController,
              decoration: const InputDecoration(
                labelText: 'Amenities (comma separated)',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'available', child: Text('Available')),
                DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                DropdownMenuItem(
                  value: 'maintenance',
                  child: Text('Maintenance'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _status = value ?? 'available'),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 14),
            if (_type == 'house') ...[
              TextFormField(
                controller: _floorSizeController,
                decoration: const InputDecoration(labelText: 'Floor / size'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bedrooms'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bathrooms'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextFormField(
                controller: _shopSizeController,
                decoration: const InputDecoration(labelText: 'Shop size'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _businessTypeController,
                decoration: const InputDecoration(
                  labelText: 'Business suitability',
                ),
              ),
            ],
            const SizedBox(height: 14),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.sky,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Property gallery',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload bright, clear photos. They will preview here before you save the listing.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Upload'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GalleryCountChip(
                        icon: Icons.cloud_done_outlined,
                        label: '${existingImages.length} saved',
                      ),
                      if (removedImageCount > 0)
                        _GalleryCountChip(
                          icon: Icons.delete_outline_rounded,
                          label: '$removedImageCount removed',
                        ),
                      _GalleryCountChip(
                        icon: Icons.auto_awesome_mosaic_outlined,
                        label: '${_newImages.length} selected',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (existingImages.isEmpty && _newImages.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.sky.withValues(alpha: 0.92),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 30,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No photos added yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Front view, hall, kitchen and exterior photos make the listing feel complete.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (existingImages.isNotEmpty) ...[
                      _GallerySectionHeader(
                        title: 'Saved photos',
                        subtitle: removedImageCount == 0
                            ? '${existingImages.length} already attached to this property'
                            : '$removedImageCount photo change${removedImageCount == 1 ? '' : 's'} pending until you save',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 154,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: existingImages.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final imageUrl = existingImages[index];
                            return _GalleryPreviewCard(
                              imageUrl: imageUrl,
                              title: index == 0 ? 'Cover photo' : 'Saved photo',
                              badgeLabel: index == 0 ? 'Cover' : 'Saved',
                              badgeColor: index == 0
                                  ? AppColors.navy
                                  : AppColors.success,
                              onRemove: () => _removeExistingImageAt(index),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_newImages.isNotEmpty) ...[
                      if (existingImages.isNotEmpty) const SizedBox(height: 16),
                      _GallerySectionHeader(
                        title: 'Ready to upload',
                        subtitle:
                            '${_newImages.length} new photo${_newImages.length == 1 ? '' : 's'} selected',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 154,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImages.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final file = _newImages[index];
                            final isCover =
                                existingImages.isEmpty && index == 0;
                            return _GalleryPreviewCard(
                              memoryBytes: file.bytes,
                              title: file.name,
                              badgeLabel: isCover ? 'Cover' : 'New',
                              badgeColor: isCover
                                  ? AppColors.navy
                                  : AppColors.teal,
                              onRemove: () => _removePickedImage(file),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Save property',
              onPressed: _save,
              icon: Icons.save_rounded,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryCountChip extends StatelessWidget {
  const _GalleryCountChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.navy),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GallerySectionHeader extends StatelessWidget {
  const _GallerySectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _GalleryPreviewCard extends StatelessWidget {
  const _GalleryPreviewCard({
    required this.title,
    required this.badgeLabel,
    required this.badgeColor,
    this.imageUrl,
    this.memoryBytes,
    this.onRemove,
  });

  final String title;
  final String badgeLabel;
  final Color badgeColor;
  final String? imageUrl;
  final Uint8List? memoryBytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(child: _buildImage()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.38),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (onRemove != null)
              Positioned(
                right: 10,
                top: 10,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.36),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (memoryBytes != null) {
      return Image.memory(
        memoryBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.sky),
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.navy, size: 28),
      ),
    );
  }
}

class AdminApplicationsTab extends ConsumerStatefulWidget {
  const AdminApplicationsTab({super.key});

  @override
  ConsumerState<AdminApplicationsTab> createState() =>
      _AdminApplicationsTabState();
}

class _AdminApplicationsTabState extends ConsumerState<AdminApplicationsTab> {
  late Future<List<RentalApplicationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(applicationRepositoryProvider).fetchAdminApplications();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _future = ref
            .read(applicationRepositoryProvider)
            .fetchAdminApplications();
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
              title: 'No applications received',
              subtitle:
                  'Tenant applications will show up here for review and approval.',
              icon: Icons.assignment_outlined,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => context.push('/admin/application/${item.id}'),
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
                      Text(item.user?.name ?? 'Applicant'),
                      const SizedBox(height: 8),
                      Text('Applied on ${formatDate(item.applicationDate)}'),
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

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).fetchUsers();
  }

  Future<void> _openCreateUserSheet() async {
    final formKey = GlobalKey<FormState>();
    final fullName = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController(text: 'User@123');

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fullName,
                validator: (value) =>
                    requiredValidator(value, label: 'Full name'),
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: email,
                validator: emailValidator,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                validator: (value) => requiredValidator(value, label: 'Phone'),
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: password,
                validator: passwordValidator,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Create user',
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  await ref.read(adminRepositoryProvider).createUser({
                    'fullName': fullName.text.trim(),
                    'email': email.text.trim(),
                    'phone': phone.text.trim(),
                    'password': password.text,
                  });
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

    if (created == true) {
      setState(() {
        _future = ref.read(adminRepositoryProvider).fetchUsers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<AppUser>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingShimmerList();
            }
            if (snapshot.hasError) {
              return EmptyStateView(
                title: 'Could not load users',
                subtitle: snapshot.error.toString(),
                icon: Icons.error_outline_rounded,
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const EmptyStateView(
                title: 'No users created',
                subtitle:
                    'Tenant and applicant records will appear here as accounts are created.',
                icon: Icons.group_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = items[index];
                return AppSectionCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFEAF4F3),
                        child: Text(
                          user.name.isEmpty
                              ? 'U'
                              : user.name.characters.first.toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(user.email),
                            if (user.phone != null) Text(user.phone!),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          await ref
                              .read(adminRepositoryProvider)
                              .updateUserStatus(user.id, value);
                          if (mounted) {
                            setState(
                              () => _future = ref
                                  .read(adminRepositoryProvider)
                                  .fetchUsers(),
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'active',
                            child: Text('Mark active'),
                          ),
                          PopupMenuItem(
                            value: 'suspended',
                            child: Text('Suspend'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: FloatingActionButton.extended(
            onPressed: _openCreateUserSheet,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add user'),
          ),
        ),
      ],
    );
  }
}

class AdminMoreTab extends StatelessWidget {
  const AdminMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const GlassHeader(
          title: 'Operations tools',
          subtitle:
              'Move between collections, support, reports and announcements.',
        ),
        const SizedBox(height: 18),
        AppSectionCard(
          child: Column(
            children: [
              _AdminNavTile(
                icon: Icons.payments_rounded,
                title: 'Payment management',
                route: '/admin/payments',
              ),
              _AdminNavTile(
                icon: Icons.support_agent_rounded,
                title: 'Complaint management',
                route: '/admin/complaints',
              ),
              _AdminNavTile(
                icon: Icons.bar_chart_rounded,
                title: 'Reports',
                route: '/admin/reports',
              ),
              _AdminNavTile(
                icon: Icons.campaign_rounded,
                title: 'Announcements',
                route: '/admin/announcements',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.navy, size: 22),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(route),
    );
  }
}

class AdminApplicationReviewScreen extends ConsumerStatefulWidget {
  const AdminApplicationReviewScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<AdminApplicationReviewScreen> createState() =>
      _AdminApplicationReviewScreenState();
}

class _AdminApplicationReviewScreenState
    extends ConsumerState<AdminApplicationReviewScreen> {
  late Future<RentalApplicationItem> _future;
  final _remarksController = TextEditingController();
  bool _assignTenant = true;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(applicationRepositoryProvider)
        .fetchApplication(widget.applicationId);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ref
          .read(applicationRepositoryProvider)
          .updateApplicationStatus(
            id: widget.applicationId,
            status: status,
            adminRemarks: _remarksController.text.trim(),
            assignTenant: _assignTenant,
          );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Application updated');
      setState(() {
        _future = ref
            .read(applicationRepositoryProvider)
            .fetchApplication(widget.applicationId);
      });
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    }
  }

  Future<void> _uploadAgreement(RentalApplicationItem application) async {
    final titleController = TextEditingController(
      text: '${application.property.title} agreement',
    );
    final startController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final endController = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 365))
          .toIso8601String()
          .split('T')
          .first,
    );
    PlatformFile? pickedFile;

    final uploaded = await showModalBottomSheet<bool>(
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
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Agreement title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Start date (YYYY-MM-DD)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'End date (YYYY-MM-DD)',
                ),
              ),
              const SizedBox(height: 12),
              AppSectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickedFile == null
                            ? 'No file chosen'
                            : pickedFile!.name,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                          withData: kIsWeb,
                        );
                        if (result == null) {
                          return;
                        }
                        final file = result.files.single;
                        if (file.bytes != null ||
                            (file.path != null && file.path!.isNotEmpty)) {
                          setState(() => pickedFile = file);
                        }
                      },
                      child: const Text('Choose PDF'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Upload agreement',
                onPressed: () async {
                  await ref
                      .read(adminRepositoryProvider)
                      .uploadAgreement(
                        userId: application.user!.id,
                        propertyId: application.property.id,
                        title: titleController.text.trim(),
                        startDate: startController.text.trim(),
                        endDate: endController.text.trim(),
                        rent: application.property.rent,
                        file: pickedFile,
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

    if (uploaded == true && mounted) {
      showAppSnackBar(context, 'Agreement uploaded successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Application review',
      body: FutureBuilder<RentalApplicationItem>(
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

          final application = snapshot.data!;
          if (_remarksController.text.isEmpty &&
              (application.adminRemarks ?? '').isNotEmpty) {
            _remarksController.text = application.adminRemarks!;
          }
          return ListView(
            children: [
              ApplicationDetailContent(
                application: application,
                showApplicant: true,
                showAdminRemarks: false,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _remarksController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Admin remarks'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _assignTenant,
                onChanged: (value) => setState(() => _assignTenant = value),
                title: const Text('Assign tenant to property on approval'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    onPressed: () => _updateStatus('under_review'),
                    child: const Text('Mark under review'),
                  ),
                  FilledButton(
                    onPressed: () => _updateStatus('approved'),
                    child: const Text('Approve'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _updateStatus('rejected'),
                    child: const Text('Reject'),
                  ),
                ],
              ),
              if (application.user != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _uploadAgreement(application),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Upload agreement'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  late Future<List<PaymentItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(paymentRepositoryProvider).fetchAdminPayments();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Payment management',
      body: FutureBuilder<List<PaymentItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList();
          }
          if (snapshot.hasError) {
            return EmptyStateView(
              title: 'Could not load payments',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No payment records yet',
              subtitle:
                  'Transactions and rent receipts will appear here as rent is collected.',
              icon: Icons.receipt_long_outlined,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.property.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(item.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.month),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency(item.amount),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if ((item.transactionId ?? '').isNotEmpty)
                      Text('Txn: ${item.transactionId}'),
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

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).fetchPaymentReport();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports',
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList();
          }
          if (snapshot.hasError) {
            return EmptyStateView(
              title: 'Could not load reports',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No report data yet',
              subtitle:
                  'Monthly payment aggregates will appear after the first successful collection.',
              icon: Icons.bar_chart_outlined,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return AppSectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateTime(
                          2026,
                          (item['_id'] as num).toInt(),
                        ).month.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text('${item['count']} payments'),
                    const SizedBox(width: 14),
                    Text(formatCurrency(item['totalAmount'] as num? ?? 0)),
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

class AdminComplaintsScreen extends ConsumerStatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  ConsumerState<AdminComplaintsScreen> createState() =>
      _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends ConsumerState<AdminComplaintsScreen> {
  late Future<List<ComplaintItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(profileRepositoryProvider).fetchComplaints();
  }

  Future<void> _reply(ComplaintItem complaint) async {
    final replyController = TextEditingController(
      text: complaint.adminReply ?? '',
    );
    String status = complaint.status;
    final saved = await showModalBottomSheet<bool>(
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
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In progress'),
                  ),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (value) => setState(() => status = value ?? status),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Admin reply'),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Save response',
                onPressed: () async {
                  await ref
                      .read(adminRepositoryProvider)
                      .updateComplaint(
                        complaint.id,
                        status,
                        replyController.text.trim(),
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

    if (saved == true) {
      setState(
        () => _future = ref.read(profileRepositoryProvider).fetchComplaints(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Complaint management',
      body: FutureBuilder<List<ComplaintItem>>(
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
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No complaints to manage',
              subtitle:
                  'Open service requests and maintenance issues will appear here.',
              icon: Icons.support_agent_outlined,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.subject,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(item.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.propertyTitle),
                    const SizedBox(height: 8),
                    Text(item.description),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _reply(item),
                      icon: const Icon(Icons.reply_rounded),
                      label: const Text('Respond'),
                    ),
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

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'users';
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(notificationRepositoryProvider)
          .sendAnnouncement(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            audience: _audience,
          );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Announcement sent successfully');
      _titleController.clear();
      _bodyController.clear();
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Announcements',
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const GlassHeader(
              title: 'Broadcast updates',
              subtitle:
                  'Send reminders, notices and announcements to users or admins.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              validator: (value) => requiredValidator(value, label: 'Title'),
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              items: const [
                DropdownMenuItem(value: 'users', child: Text('All users')),
                DropdownMenuItem(value: 'admins', child: Text('Admins only')),
              ],
              onChanged: (value) =>
                  setState(() => _audience = value ?? 'users'),
              decoration: const InputDecoration(labelText: 'Audience'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bodyController,
              validator: (value) => requiredValidator(value, label: 'Message'),
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Announcement body'),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Send announcement',
              onPressed: _send,
              icon: Icons.campaign_rounded,
              isLoading: _sending,
            ),
          ],
        ),
      ),
    );
  }
}
