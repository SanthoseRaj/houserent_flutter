import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/message_repository.dart';

class MessagesTab extends ConsumerStatefulWidget {
  const MessagesTab({super.key});

  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() =>
      ref.read(messageRepositoryProvider).fetchThreads();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _future = _load();
      }),
      child: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerList();
          }
          if (snapshot.hasError) {
            return EmptyStateView(
              title: 'Could not load messages',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          final threads = snapshot.data ?? [];
          if (threads.isEmpty) {
            return const EmptyStateView(
              title: 'No conversations yet',
              subtitle:
                  'Once you start chatting with the admin, messages will appear here.',
              icon: Icons.chat_bubble_outline_rounded,
            );
          }

          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return InkWell(
                onTap: () => context.push(
                  '/chat/${thread.participantId}',
                  extra: {
                    'participantName': thread.participantModel == 'Admin'
                        ? 'Admin Desk'
                        : 'Tenant Conversation',
                  },
                ),
                child: AppSectionCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFEAF4F3),
                        child: Text(
                          thread.participantModel == 'Admin' ? 'A' : 'U',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thread.participantModel == 'Admin'
                                  ? 'Admin Desk'
                                  : 'Tenant Conversation',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              thread.lastMessage.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(formatDateTime(thread.lastMessage.createdAt)),
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

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.participantId,
    this.participantName,
  });

  final String participantId;
  final String? participantName;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _messageController = TextEditingController();
  late Future<List<dynamic>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _load() =>
      ref.read(messageRepositoryProvider).fetchThread(widget.participantId);

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(messageRepositoryProvider)
          .sendMessage(receiverId: widget.participantId, message: message);
      _messageController.clear();
      setState(() {
        _future = _load();
      });
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
      title: widget.participantName ?? 'Conversation',
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingShimmerList(itemCount: 4);
                }
                if (snapshot.hasError) {
                  return EmptyStateView(
                    title: 'Could not load messages',
                    subtitle: snapshot.error.toString(),
                    icon: Icons.error_outline_rounded,
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const EmptyStateView(
                    title: 'No messages yet',
                    subtitle:
                        'Send the first message to start the conversation.',
                    icon: Icons.mark_chat_unread_outlined,
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final item = messages[messages.length - 1 - index];
                    final isMine = item.senderModel != 'Admin';
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMine
                              ? const Color(0xFF173B56)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.message,
                              style: TextStyle(
                                color: isMine ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatDateTime(item.createdAt),
                              style: TextStyle(
                                color: isMine ? Colors.white70 : Colors.black45,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Type a message'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
