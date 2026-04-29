import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() =>
      ref.read(notificationRepositoryProvider).fetchNotifications();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notifications',
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList();
          }
          if (snapshot.hasError) {
            return EmptyStateView(
              title: 'Could not load notifications',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No notifications yet',
              subtitle:
                  'Application updates, reminders and admin messages will show here.',
              icon: Icons.notifications_none_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              _future = _load();
            }),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () async {
                    if (!item.isRead) {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markRead(item.id);
                      setState(() {
                        _future = _load();
                      });
                    }
                  },
                  child: AppSectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? const Color(0xFFF3F6F9)
                                : const Color(0xFFEAF4F3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.notifications_active_rounded),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(item.body),
                              const SizedBox(height: 8),
                              Text(formatDateTime(item.createdAt)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
