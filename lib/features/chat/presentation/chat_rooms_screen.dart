import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/features/chat/data/chat_models.dart';
import 'package:helpi_app/features/chat/presentation/chat_conversation_screen.dart';
import 'package:helpi_app/features/chat/providers/chat_provider.dart';

/// Chat rooms list — shows all conversations for the user.
/// Used by both Student and Senior tabs.
class ChatRoomsScreen extends ConsumerStatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  ConsumerState<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends ConsumerState<ChatRoomsScreen> {
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
    ref.read(chatRoomsProvider.notifier).loadRooms();
    refreshChatUnreadCount(ref);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return AppStrings.chatAdmin;
      case 'student':
        return AppStrings.chatStudent;
      case 'senior':
        return AppStrings.chatSenior;
      default:
        return role;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'sad';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${local.day}.${local.month}.';
  }

  void _openRoom(ChatRoom room) {
    if (_myUserId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatConversationScreen(room: room, myUserId: _myUserId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.chatRooms)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.rooms.isEmpty
          ? _buildEmpty(theme)
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(chatRoomsProvider.notifier).loadRooms();
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.rooms.length,
                separatorBuilder: (context, idx) => Divider(
                  height: 1,
                  indent: 72,
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
                itemBuilder: (context, index) {
                  final room = state.rooms[index];
                  return _RoomTile(
                    room: room,
                    myUserId: _myUserId ?? 0,
                    roleLabel: _roleLabel(room.otherRole(_myUserId ?? 0)),
                    timeAgo: _timeAgo(room.lastMessageAt),
                    onTap: () => _openRoom(room),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.chatNoRooms,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.chatNoRoomsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.myUserId,
    required this.roleLabel,
    required this.timeAgo,
    required this.onTap,
  });

  final ChatRoom room;
  final int myUserId;
  final String roleLabel;
  final String timeAgo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = room.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          room.otherName(myUserId).isNotEmpty
              ? room.otherName(myUserId)[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              room.otherName(myUserId),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeAgo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasUnread
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              room.lastMessageText ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${room.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
