import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/providers/realtime_sync_provider.dart';
import 'package:helpi_app/core/utils/snackbar_helper.dart';
import 'package:helpi_app/features/chat/providers/chat_provider.dart';
import 'package:helpi_app/features/chat/data/chat_api_service.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/l10n/theme_notifier.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/features/booking/presentation/order_screen.dart';
import 'package:helpi_app/features/booking/presentation/orders_screen.dart';
import 'package:helpi_app/features/chat/presentation/senior_chat_list_screen.dart';
import 'package:helpi_app/features/profile/presentation/profile_menu_screen.dart';

/// Senior shell - 4 tabs: Order, Orders, Messages, Profile.
class SeniorShell extends ConsumerStatefulWidget {
  const SeniorShell({
    super.key,
    required this.localeNotifier,
    required this.themeNotifier,
    required this.onLogout,
    required this.ordersNotifier,
  });

  final LocaleNotifier localeNotifier;
  final ThemeNotifier themeNotifier;
  final VoidCallback onLogout;
  final OrdersNotifier ordersNotifier;

  @override
  ConsumerState<SeniorShell> createState() => _SeniorShellState();
}

class _SeniorShellState extends ConsumerState<SeniorShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      OrderScreen(
        ordersNotifier: widget.ordersNotifier,
        onOrderCreated: () => setState(() => _currentIndex = 1),
      ),
      OrdersScreen(ordersNotifier: widget.ordersNotifier),
      const ChatScreen(),
      ProfileMenuScreen(
        localeNotifier: widget.localeNotifier,
        themeNotifier: widget.themeNotifier,
        onLogout: widget.onLogout,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Show in-app banner when a notification arrives via SignalR.
    ref.listen<Map<String, dynamic>?>(inAppNotificationProvider, (prev, next) {
      if (next == null) return;
      final title = next['title'] as String? ?? '';
      final body = next['body'] as String? ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showHelpiSnackBar(context, '$title\n$body');
        ref.read(inAppNotificationProvider.notifier).state = null;
      });
    });

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
            if (index == 2) _clearChatBadge();
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: AppStrings.navOrder,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_outlined, size: 28),
              label: AppStrings.navOrders,
            ),
            BottomNavigationBarItem(
              icon: _badgedIcon(Icons.chat_bubble_outline, 28),
              label: AppStrings.navMessages,
            ),
            BottomNavigationBarItem(
              icon: _notifBadgedIcon(Icons.account_circle_outlined, 28),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgedIcon(IconData icon, double size) {
    final count = ref.watch(chatUnreadCountProvider);
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Icon(icon, size: size),
    );
  }

  Widget _notifBadgedIcon(IconData icon, double size) {
    final count = ref.watch(notificationsUnreadProvider);
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 9 ? '9+' : '$count'),
      child: Icon(icon, size: size),
    );
  }

  void _clearChatBadge() {
    ref.read(chatUnreadCountProvider.notifier).state = 0;
    final roomId = ref.read(chatMessagesProvider.notifier).currentRoomId;
    if (roomId != null) {
      ref.read(chatRoomsProvider.notifier).clearUnread(roomId);
      ref.read(chatMessagesProvider.notifier).markAsRead();
      ChatApiService().markAsRead(roomId);
    }
  }
}
