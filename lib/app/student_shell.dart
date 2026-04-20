import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/providers/pending_assignments_provider.dart';
import 'package:helpi_app/core/utils/snackbar_helper.dart';
import 'package:helpi_app/features/chat/providers/chat_provider.dart';
import 'package:helpi_app/features/chat/data/chat_api_service.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/l10n/theme_notifier.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/features/chat/presentation/student_chat_screen.dart';
import 'package:helpi_app/features/profile/presentation/student_menu_screen.dart';
import 'package:helpi_app/features/schedule/presentation/schedule_screen.dart';
import 'package:helpi_app/features/schedule/presentation/pending_assignment_overlay.dart';
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
  bool _overlayShown = false;
  bool _processingAction = false;
  int _acceptedCount = 0;
  int _declinedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingAssignments();
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

  void _loadPendingAssignments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingAssignmentsProvider.notifier).load();
    });
  }

  void _showOverlayIfNeeded(List<PendingAssignment> pending) {
    if (pending.isEmpty || _overlayShown || _processingAction) return;
    _overlayShown = true;
    _acceptedCount = 0;
    _declinedCount = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showAssignmentDialog(pending.first);
    });
  }

  Future<void> _showAssignmentDialog(PendingAssignment assignment) async {
    final rootNav = Navigator.of(context, rootNavigator: true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PendingAssignmentOverlay(
        assignment: assignment,
        onAccept: () => _handleAccept(assignment.assignmentId, rootNav),
        onDecline: () => _handleDecline(assignment.assignmentId, rootNav),
      ),
    );
  }

  Future<void> _handleAccept(int id, NavigatorState nav) async {
    if (_processingAction) return;
    _processingAction = true;
    nav.pop();
    final success = await ref
        .read(pendingAssignmentsProvider.notifier)
        .accept(id);
    if (!mounted) return;
    _overlayShown = false;
    // Defer snackbar + next dialog to next frame (dialog still unmounting)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _processingAction = false;
      if (!success) {
        showHelpiSnackBar(context, AppStrings.pendingError, isError: true);
        return;
      }
      _acceptedCount++;
      final remaining = ref.read(pendingAssignmentsProvider);
      if (remaining.isNotEmpty) {
        _showAssignmentDialog(remaining.first);
      } else {
        _showQueueSummary();
      }
    });
  }

  Future<void> _handleDecline(int id, NavigatorState nav) async {
    if (_processingAction) return;
    _processingAction = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.pendingDecline),
        content: Text(AppStrings.pendingDeclineConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      _processingAction = false;
      return;
    }

    nav.pop();
    final success = await ref
        .read(pendingAssignmentsProvider.notifier)
        .decline(id);
    if (!mounted) return;
    _overlayShown = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _processingAction = false;
      if (!success) {
        showHelpiSnackBar(context, AppStrings.pendingError, isError: true);
        return;
      }
      _declinedCount++;
      final remaining = ref.read(pendingAssignmentsProvider);
      if (remaining.isNotEmpty) {
        _showAssignmentDialog(remaining.first);
      } else {
        _showQueueSummary();
      }
    });
  }

  void _showQueueSummary() {
    final total = _acceptedCount + _declinedCount;
    if (total == 1) {
      // Single order — simple message
      final msg = _acceptedCount == 1
          ? AppStrings.pendingAccepted
          : AppStrings.pendingDeclined;
      showHelpiSnackBar(context, msg);
    } else {
      // Multiple orders — summary
      showHelpiSnackBar(
        context,
        AppStrings.pendingSummary(_acceptedCount, _declinedCount),
      );
    }
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    if (index == 1) _clearChatBadge();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingAssignmentsProvider);

    // Dismiss overlay if admin revoked (replaced) the assignment while dialog
    // is showing — the SignalR handler calls load() which empties the state.
    ref.listen<List<PendingAssignment>>(pendingAssignmentsProvider, (
      prev,
      next,
    ) {
      if (!_overlayShown || _processingAction) return;
      if (prev != null && prev.isNotEmpty && prev.length > next.length) {
        _overlayShown = false;
        Navigator.of(context, rootNavigator: true).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (next.isNotEmpty) {
            _showOverlayIfNeeded(next);
          } else {
            showHelpiSnackBar(context, AppStrings.pendingRevoked);
          }
        });
      }
    });

    _showOverlayIfNeeded(pending);

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
