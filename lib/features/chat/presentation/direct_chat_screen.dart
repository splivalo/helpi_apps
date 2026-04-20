import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/features/chat/data/chat_models.dart';
import 'package:helpi_app/features/chat/providers/chat_provider.dart';

/// Direct chat screen — skips room list, opens conversation with Helpi.
/// Used by both Student and Senior chat tabs.
class DirectChatScreen extends ConsumerStatefulWidget {
  const DirectChatScreen({super.key});

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _isLoadingRoom = true;
  String? _error;
  ChatRoom? _room;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final userId = await TokenStorage().getUserId();
    if (!mounted) return;
    setState(() => _myUserId = userId);

    // GET /rooms — backend auto-creates room with admin
    await ref.read(chatRoomsProvider.notifier).loadRooms();
    if (!mounted) return;

    final rooms = ref.read(chatRoomsProvider).rooms;
    if (rooms.isNotEmpty) {
      _room = rooms.first;
      ref.read(chatRoomsProvider.notifier).clearUnread(_room!.id);
      ref.read(chatUnreadCountProvider.notifier).state = 0;
      await ref.read(chatMessagesProvider.notifier).loadMessages(_room!.id);
      if (!mounted) return;
      await ref.read(chatMessagesProvider.notifier).markAsRead();
      if (!mounted) return;
      await refreshChatUnreadCount(ref);
      if (!mounted) return;
    } else {
      _error = AppStrings.chatLoadError;
    }

    setState(() => _isLoadingRoom = false);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingRoom) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.chatRooms)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _room == null || _myUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.chatRooms)),
        body: Center(
          child: Text(
            _error ?? AppStrings.chatLoadError,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final state = ref.watch(chatMessagesProvider);

    ref.listen<ChatMessagesState>(chatMessagesProvider, (prev, next) {
      if (prev != null &&
          next.messages.length > prev.messages.length &&
          !next.isLoading) {
        _scrollToBottom();
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.chatRooms)),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
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
                            isMe: msg.isMine(_myUserId!),
                            time: msg.timeFormatted,
                            senderName: msg.senderName,
                          );
                        },
                      ),
              ),
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
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.senderName,
  });

  final String text;
  final bool isMe;
  final String time;
  final String senderName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        senderName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isMe
                              ? Colors.white.withAlpha(180)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
