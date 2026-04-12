import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/l10n/theme_notifier.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/features/chat/presentation/student_chat_screen.dart';
import 'package:helpi_app/features/profile/presentation/student_profile_screen.dart';
import 'package:helpi_app/features/schedule/presentation/schedule_screen.dart';
import 'package:helpi_app/features/statistics/presentation/statistics_screen.dart';

/// Student shell - 4 tabs: Schedule, Messages, Statistics, Profile.
class StudentShell extends StatefulWidget {
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
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ScheduleScreen(),
      const ChatScreen(),
      const StatisticsScreen(),
      ProfileScreen(
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
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
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
}
