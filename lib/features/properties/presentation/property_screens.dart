import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/property_repository.dart';

class PropertiesHomeTab extends ConsumerStatefulWidget {
  const PropertiesHomeTab({super.key});

  @override
  ConsumerState<PropertiesHomeTab> createState() => _PropertiesHomeTabState();
}

class _PropertiesHomeTabState extends ConsumerState<PropertiesHomeTab> {
  final _searchController = TextEditingController();
  String _type = '';
  String _city = '';
  Future<List<PropertyItem>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PropertyItem>> _load() {
    return ref
        .read(propertyRepositoryProvider)
        .fetchProperties(
          search: _searchController.text.trim(),
          type: _type.isEmpty ? null : _type,
          city: _city.isEmpty ? null : _city,
        );
  }

  Future<void> _openFilterSheet() async {
    final cityController = TextEditingController(text: _city);
    final selectedType = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String tempType = _type;
        return Padding(
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
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: tempType.isEmpty ? null : tempType,
                  items: const [
                    DropdownMenuItem(value: 'house', child: Text('House')),
                    DropdownMenuItem(value: 'shop', child: Text('Shop')),
                  ],
                  onChanged: (value) => setState(() => tempType = value ?? ''),
                  decoration: const InputDecoration(labelText: 'Property type'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City / area'),
                ),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  label: 'Apply filters',
                  onPressed: () => Navigator.of(
                    context,
                  ).pop({'type': tempType, 'city': cityController.text.trim()}),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedType != null) {
      setState(() {
        _type = selectedType['type'] ?? '';
        _city = selectedType['city'] ?? '';
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _future = _load();
      }),
      child: ListView(
        children: [
          const GlassHeader(
            title: 'Find the right rental',
            subtitle:
                'Browse available houses and shops with a clean, premium experience.',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by title or locality',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (_) => setState(() {
                    _future = _load();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: _openFilterSheet,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _type.isEmpty,
                onSelected: (_) => setState(() {
                  _type = '';
                  _future = _load();
                }),
              ),
              ChoiceChip(
                label: const Text('House'),
                selected: _type == 'house',
                onSelected: (_) => setState(() {
                  _type = 'house';
                  _future = _load();
                }),
              ),
              ChoiceChip(
                label: const Text('Shop'),
                selected: _type == 'shop',
                onSelected: (_) => setState(() {
                  _type = 'shop';
                  _future = _load();
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<PropertyItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingShimmerList(itemCount: 3);
              }
              if (snapshot.hasError) {
                return EmptyStateView(
                  title: 'Could not load properties',
                  subtitle: snapshot.error.toString(),
                  icon: Icons.error_outline_rounded,
                );
              }
              final properties = snapshot.data ?? [];
              if (properties.isEmpty) {
                return const EmptyStateView(
                  title: 'No properties found',
                  subtitle:
                      'Try a different filter or check back soon for new listings.',
                  icon: Icons.home_work_outlined,
                );
              }

              return Column(
                children: properties
                    .map(
                      (property) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PropertyCard(property: property),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  late Future<PropertyItem> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(propertyRepositoryProvider)
        .fetchProperty(widget.propertyId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: FutureBuilder<PropertyItem>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList(itemCount: 1);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return EmptyStateView(
              title: 'Property unavailable',
              subtitle:
                  snapshot.error?.toString() ??
                  'We could not load this property.',
              icon: Icons.error_outline_rounded,
            );
          }

          final property = snapshot.data!;
          final phone = property.ownerContactPhone;
          final email = property.ownerContactEmail;
          return ListView(
            children: [
              _PropertyImageGallery(images: property.images),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      property.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusChip(property.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(_formatAddress(property)),
              const SizedBox(height: 18),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCurrency(property.rent),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('Deposit ${formatCurrency(property.deposit)}'),
                    const SizedBox(height: 14),
                    _PropertyHighlights(property: property),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (property.amenities.isEmpty)
                      const Text('No amenities added.')
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: property.amenities
                            .map((item) => Chip(label: Text(item)))
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full property details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    _PropertyDetailRows(
                      items: [
                        _PropertyDetailItem('Property name', property.title),
                        _PropertyDetailItem(
                          'Property type',
                          _readable(property.type),
                        ),
                        _PropertyDetailItem(
                          'Status',
                          _readable(property.status),
                        ),
                        _PropertyDetailItem(
                          'Monthly rent',
                          formatCurrency(property.rent),
                        ),
                        _PropertyDetailItem(
                          'Deposit',
                          formatCurrency(property.deposit),
                        ),
                        _PropertyDetailItem('Address', property.addressLine),
                        _PropertyDetailItem('City', property.city),
                        _PropertyDetailItem('Area', property.area),
                        _PropertyDetailItem(
                          'Available from',
                          formatDate(property.availableFrom),
                        ),
                        _PropertyDetailItem('Floor / size', property.floorSize),
                        _PropertyDetailItem(
                          'Bedrooms',
                          property.bedrooms?.toString(),
                        ),
                        _PropertyDetailItem(
                          'Bathrooms',
                          property.bathrooms?.toString(),
                        ),
                        _PropertyDetailItem('Shop size', property.shopSize),
                        _PropertyDetailItem(
                          'Business suitability',
                          property.businessSuitability,
                        ),
                        _PropertyDetailItem(
                          'Owner phone',
                          property.ownerContactPhone,
                        ),
                        _PropertyDetailItem(
                          'Owner email',
                          property.ownerContactEmail,
                        ),
                        _PropertyDetailItem(
                          'Featured',
                          property.featured ? 'Yes' : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasText(property.description)
                          ? property.description
                          : 'No description added.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Apply for this property',
                      onPressed: property.status == 'available'
                          ? () => context.push('/apply/${property.id}')
                          : null,
                      icon: Icons.assignment_rounded,
                    ),
                  ),
                ],
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Contact owner'),
                ),
              ],
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('mailto:$email')),
                  icon: const Icon(Icons.email_rounded),
                  label: const Text('Email owner'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PropertyImageGallery extends StatefulWidget {
  const _PropertyImageGallery({required this.images});

  final List<String> images;

  @override
  State<_PropertyImageGallery> createState() => _PropertyImageGalleryState();
}

class _PropertyImageGalleryState extends State<_PropertyImageGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) {
      return const AppNetworkImage(imageUrl: '', height: 260);
    }

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                right: index == images.length - 1 ? 0 : 8,
              ),
              child: AppNetworkImage(imageUrl: images[index], height: 260),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_index + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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

class _PropertyHighlights extends StatelessWidget {
  const _PropertyHighlights({required this.property});

  final PropertyItem property;

  @override
  Widget build(BuildContext context) {
    final highlights = [
      if (property.bedrooms != null) '${property.bedrooms} Bedrooms',
      if (property.bathrooms != null) '${property.bathrooms} Bathrooms',
      if (_hasText(property.floorSize)) property.floorSize!,
      if (_hasText(property.shopSize)) property.shopSize!,
      if (_hasText(property.businessSuitability)) property.businessSuitability!,
      if (_hasText(property.availableFrom))
        'Available ${formatDate(property.availableFrom)}',
      _readable(property.type).toUpperCase(),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: highlights.map((item) => Chip(label: Text(item))).toList(),
    );
  }
}

class _PropertyDetailRows extends StatelessWidget {
  const _PropertyDetailRows({required this.items});

  final List<_PropertyDetailItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => _hasText(item.value))
        .toList(growable: false);
    if (visibleItems.isEmpty) {
      return const Text('-');
    }

    return Column(
      children: visibleItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.value!,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PropertyDetailItem {
  const _PropertyDetailItem(this.label, this.value);

  final String label;
  final String? value;
}

String _formatAddress(PropertyItem property) {
  return [
    property.addressLine,
    property.city,
    if (_hasText(property.area)) property.area!,
  ].where(_hasText).join(', ');
}

String _readable(String value) => value.replaceAll('_', ' ');

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final PropertyItem property;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/property/${property.id}'),
      borderRadius: BorderRadius.circular(24),
      child: AppSectionCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  imageUrl: property.images.isNotEmpty
                      ? property.images.first
                      : '',
                  height: 190,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusChip(property.status),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(property.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(_formatAddress(property)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatCurrency(property.rent),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.navy),
                  ),
                ),
                if (property.bedrooms != null) Text('${property.bedrooms} bed'),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: property.amenities
                  .take(3)
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
