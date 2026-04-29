import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/app_models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

class ApplicationDetailContent extends StatelessWidget {
  const ApplicationDetailContent({
    super.key,
    required this.application,
    this.showApplicant = false,
    this.showAdminRemarks = true,
  });

  final RentalApplicationItem application;
  final bool showApplicant;
  final bool showAdminRemarks;

  @override
  Widget build(BuildContext context) {
    final property = application.property;
    final personalDetails = application.personalDetails;
    final location = [
      if (property.addressLine.isNotEmpty) property.addressLine,
      if (property.city.isNotEmpty) property.city,
    ].join(', ');
    final applicantDetails = <_DetailItem>[
      _DetailItem('Applicant', application.user?.name),
      _DetailItem('Email', application.user?.email),
      _DetailItem('Phone', application.user?.phone),
      _DetailItem('Occupation', application.user?.occupation),
      _DetailItem(
        'Income',
        application.user?.income == null
            ? null
            : formatCurrency(application.user!.income!),
      ),
    ].where((item) => _hasValue(item.value)).toList();
    final noteItems = <_DetailItem>[
      _DetailItem('Applicant remarks', application.remarks),
      if (showAdminRemarks)
        _DetailItem('Admin remarks', application.adminRemarks),
    ].where((item) => _hasValue(item.value)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(location.isEmpty ? '-' : location),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(application.status),
                ],
              ),
              const SizedBox(height: 14),
              _DetailGrid(
                items: [
                  _DetailItem(
                    'Applied on',
                    formatDate(application.applicationDate),
                  ),
                  _DetailItem(
                    'Rental start',
                    formatDate(personalDetails?.requiredRentalStartDate),
                  ),
                  _DetailItem('Property type', _readable(property.type)),
                  _DetailItem(
                    'Available from',
                    formatDate(property.availableFrom),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Property details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              _DetailGrid(
                items: [
                  _DetailItem('Monthly rent', formatCurrency(property.rent)),
                  _DetailItem('Deposit', formatCurrency(property.deposit)),
                  _DetailItem('Bedrooms', property.bedrooms?.toString()),
                  _DetailItem('Bathrooms', property.bathrooms?.toString()),
                  _DetailItem('Floor size', property.floorSize),
                  _DetailItem('Shop size', property.shopSize),
                  _DetailItem(
                    'Business suitability',
                    property.businessSuitability,
                  ),
                  _DetailItem(
                    'Amenities',
                    property.amenities.isEmpty
                        ? null
                        : property.amenities.join(', '),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showApplicant && applicantDetails.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applicant account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                _DetailGrid(items: applicantDetails),
              ],
            ),
          ),
        ],
        if (personalDetails != null) ...[
          const SizedBox(height: 14),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submitted details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                _DetailGrid(
                  items: [
                    _DetailItem('Full name', personalDetails.fullName),
                    _DetailItem(
                      'Father / guardian',
                      personalDetails.fatherName,
                    ),
                    _DetailItem('Mobile number', personalDetails.mobileNumber),
                    _DetailItem(
                      'Alternate mobile',
                      personalDetails.alternateMobileNumber,
                    ),
                    _DetailItem('Email', personalDetails.email),
                    _DetailItem('Occupation', personalDetails.occupation),
                    _DetailItem(
                      'Monthly income',
                      personalDetails.monthlyIncome == null
                          ? null
                          : formatCurrency(personalDetails.monthlyIncome!),
                    ),
                    _DetailItem(
                      'Family members',
                      personalDetails.familyMembersCount?.toString(),
                    ),
                    _DetailItem('Business type', personalDetails.businessType),
                    _DetailItem(
                      'Aadhaar number',
                      personalDetails.aadhaarNumber,
                    ),
                    _DetailItem(
                      'Current address',
                      personalDetails.currentAddress,
                    ),
                    _DetailItem(
                      'Permanent address',
                      personalDetails.permanentAddress,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uploaded documents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (application.documents.isEmpty)
                const Text('No uploaded documents found.')
              else
                ...application.documents.map(
                  (document) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ApplicationDocumentTile(document: document),
                  ),
                ),
            ],
          ),
        ),
        if (noteItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remarks', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                ...noteItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DetailBlock(label: item.label, value: item.value!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ApplicationDocumentTile extends StatelessWidget {
  const _ApplicationDocumentTile({required this.document});

  final ApplicationDocument document;

  Future<void> _openDocument(BuildContext context) async {
    final uri = Uri.tryParse(document.url);
    if (uri == null || !await launchUrl(uri)) {
      if (context.mounted) {
        showAppSnackBar(context, 'Could not open document', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (_hasValue(document.mimeType)) document.mimeType!,
      if (document.size != null) _formatFileSize(document.size!),
      if (_hasValue(document.notes)) document.notes!,
    ].join(' | ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.description_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  document.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openDocument(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open'),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[const SizedBox(height: 8), Text(meta)],
          if (_hasValue(document.verificationStatus)) ...[
            const SizedBox(height: 10),
            StatusChip(document.verificationStatus!),
          ],
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.items});

  final List<_DetailItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => _hasValue(item.value))
        .toList(growable: false);
    if (visibleItems.isEmpty) {
      return const Text('-');
    }

    return Column(
      children: visibleItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DetailRow(label: item.label, value: item.value!),
            ),
          )
          .toList(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Text(value),
      ],
    );
  }
}

class _DetailItem {
  const _DetailItem(this.label, this.value);

  final String label;
  final String? value;
}

String _formatFileSize(num size) {
  if (size < 1024) {
    return '${size.toStringAsFixed(0)} B';
  }
  if (size < 1024 * 1024) {
    return '${(size / 1024).toStringAsFixed(1)} KB';
  }
  return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _readable(String? value) {
  if (!_hasValue(value)) {
    return '-';
  }
  return value!.replaceAll('_', ' ');
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
