import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/chat/providers/chat_provider.dart';
import 'package:helpi_app/features/chat/data/chat_api_service.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/l10n/theme_notifier.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/features/chat/presentation/student_chat_screen.dart';
import 'package:helpi_app/features/profile/presentation/student_menu_screen.dart';
import 'package:helpi_app/features/schedule/presentation/schedule_screen.dart';
import 'package:helpi_app/features/statistics/presentation/statistics_screen.dart';

/// Student shell - 4 tabs: Schedule, Messages, Statistics, Profile.
class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({
    super.key,
    required this.onLogout,
    required this.localeNotifier,
    required this.themeNotifier,
    required this.availabilityNotifier,
  });

  final VoidCallback onLogout;
  final LocaleNotifier localeNotifier;
  final ThemeNotifier themeNotifier;
  final AvailabilityNotifier availabilityNotifier;

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ScheduleScreen(),
      const ChatScreen(),
      const StatisticsScreen(),
      StudentMenuScreen(
        localeNotifier: widget.localeNotifier,
        themeNotifier: widget.themeNotifier,
        onLogout: widget.onLogout,
        availabilityNotifier: widget.availabilityNotifier,
      ),
    ];
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    if (index == 1) _clearChatBadge();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          iconSize: 28,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_today_outlined),
              activeIcon: const Icon(Icons.calendar_today),
              label: AppStrings.navSchedule,
            ),
            BottomNavigationBarItem(
              icon: _badgedIcon(Icons.chat_bubble_outline),
              activeIcon: _badgedIcon(Icons.chat_bubble),
              label: AppStrings.navMessages,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: const Icon(Icons.bar_chart),
              label: AppStrings.navStatistics,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgedIcon(IconData icon) {
    final count = ref.watch(chatUnreadCountProvider);
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Icon(icon),
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
