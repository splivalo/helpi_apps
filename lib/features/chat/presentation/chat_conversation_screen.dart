import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/chat/data/chat_models.dart';
import 'package:helpi_app/features/chat/providers/chat_provider.dart';

/// Chat conversation screen — shows messages for a specific room.
class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({
    super.key,
    required this.room,
    required this.myUserId,
  });

  final ChatRoom room;
  final int myUserId;

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadMessages() async {
    ref.read(chatMessagesProvider.notifier).loadMessages(widget.room.id);
    // Označi pročitanim
    ref.read(chatMessagesProvider.notifier).markAsRead();
    ref.read(chatRoomsProvider.notifier).clearUnread(widget.room.id);
  }

  void _onScroll() {
    // Lazy load starijih poruka kad dođeš na vrh
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 50) {
      ref.read(chatMessagesProvider.notifier).loadMore();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    final msg = await ref.read(chatMessagesProvider.notifier).sendMessage(text);
    if (!mounted) return;

    setState(() => _isSending = false);

    if (msg != null) {
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.chatSendError)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    ref.read(chatMessagesProvider.notifier).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chatMessagesProvider);

    // Auto-scroll kad stigne nova poruka
    ref.listen<ChatMessagesState>(chatMessagesProvider, (prev, next) {
      if (prev != null &&
          next.messages.length > prev.messages.length &&
          !next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.room.otherName(widget.myUserId),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Messages
            Expanded(
              child: state.isLoading && state.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.messages.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.noMessages,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        return _ChatBubble(
                          text: msg.content,
                          isMe: msg.isMine(widget.myUserId),
                          time: msg.timeFormatted,
                        );
                      },
                    ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: AppStrings.typeMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Material(
                      color: theme.colorScheme.secondary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _isSending ? null : _sendMessage,
                        customBorder: const CircleBorder(),
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });

  final String text;
  final bool isMe;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? theme.colorScheme.secondary
                : theme.colorScheme.surfaceContainerHighest,
            border: isMe
                ? null
                : Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMe ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: isMe
                      ? Colors.white.withAlpha(180)
                      : theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
