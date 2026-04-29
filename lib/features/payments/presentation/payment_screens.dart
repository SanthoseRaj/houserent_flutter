import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/app_models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../applications/data/application_repository.dart';
import '../data/payment_repository.dart';

class PaymentsTab extends ConsumerStatefulWidget {
  const PaymentsTab({super.key});

  @override
  ConsumerState<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<PaymentsTab> {
  late Future<_PaymentViewData> _future;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PaymentViewData> _load() async {
    final payments = await ref
        .read(paymentRepositoryProvider)
        .fetchMyPayments();
    final applications = await ref
        .read(applicationRepositoryProvider)
        .fetchMyApplications();
    PropertyItem? activeProperty;

    if (payments.isNotEmpty) {
      activeProperty = payments.first.property;
    } else if (applications.isNotEmpty) {
      activeProperty = applications.first.property;
    }

    return _PaymentViewData(payments: payments, activeProperty: activeProperty);
  }

  Future<void> _payRent(PropertyItem property) async {
    setState(() => _processing = true);
    try {
      final month = DateFormat('MMMM yyyy').format(DateTime.now());
      final result = await ref
          .read(paymentRepositoryProvider)
          .createCheckout(
            propertyId: property.id,
            amount: property.rent,
            month: month,
          );
      final url = result.checkoutUrl;
      if (url != null && url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          showAppSnackBar(context, 'Demo payment marked successful');
        }
      }
      setState(() {
        _future = _load();
      });
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _future = _load();
      }),
      child: FutureBuilder<_PaymentViewData>(
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
          final data = snapshot.data!;
          return ListView(
            children: [
              GlassHeader(
                title: 'Rent payments',
                subtitle: data.activeProperty == null
                    ? 'No active property linked yet. History will appear here once payments begin.'
                    : 'Pay monthly rent, track receipts and keep your ledger clean.',
              ),
              const SizedBox(height: 18),
              if (data.activeProperty != null)
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current rent due',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(data.activeProperty!.title),
                      const SizedBox(height: 12),
                      Text(
                        formatCurrency(data.activeProperty!.rent),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        label: 'Pay now',
                        onPressed: () => _payRent(data.activeProperty!),
                        icon: Icons.payments_rounded,
                        isLoading: _processing,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Payment history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (data.payments.isEmpty)
                const EmptyStateView(
                  title: 'No payments yet',
                  subtitle:
                      'Paid rent receipts and transaction details will appear here.',
                  icon: Icons.receipt_long_rounded,
                )
              else
                ...data.payments.map(
                  (payment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  payment.property.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              StatusChip(payment.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(payment.month),
                          const SizedBox(height: 8),
                          Text(
                            formatCurrency(payment.amount),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Paid on ${formatDate(payment.paidDate)}'),
                          if ((payment.receiptUrl ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () =>
                                  launchUrl(Uri.parse(payment.receiptUrl!)),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Open receipt'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentViewData {
  const _PaymentViewData({
    required this.payments,
    required this.activeProperty,
  });

  final List<PaymentItem> payments;
  final PropertyItem? activeProperty;
}
