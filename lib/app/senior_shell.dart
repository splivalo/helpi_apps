import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/features/booking/presentation/order_screen.dart';
import 'package:helpi_app/features/booking/presentation/orders_screen.dart';
import 'package:helpi_app/features/chat/presentation/senior_chat_list_screen.dart';
import 'package:helpi_app/features/profile/presentation/senior_profile_screen.dart';

/// Senior shell — 4 taba: Naruči, Narudžbe, Poruke, Profil.
class SeniorShell extends StatefulWidget {
  const SeniorShell({
    super.key,
    required this.localeNotifier,
    required this.onLogout,
    required this.ordersNotifier,
  });

  final LocaleNotifier localeNotifier;
  final VoidCallback onLogout;
  final OrdersNotifier ordersNotifier;

  @override
  State<SeniorShell> createState() => _SeniorShellState();
}

class _SeniorShellState extends State<SeniorShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      OrderScreen(ordersNotifier: widget.ordersNotifier),
      OrdersScreen(ordersNotifier: widget.ordersNotifier),
      const ChatScreen(),
      ProfileScreen(
        localeNotifier: widget.localeNotifier,
        onLogout: widget.onLogout,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.chat_bubble_outline, size: 28),
              label: AppStrings.navMessages,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle_outlined, size: 28),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
