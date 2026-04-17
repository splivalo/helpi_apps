import 'dart:async';

import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';

/// Badge displaying job/session status with live time-based transitions.
///
/// When [status] is [JobStatus.scheduled], the badge automatically switches
/// to "Aktivan" while the session is in progress and "Završen" after it ends,
/// using exact timers (no polling).
class JobStatusBadge extends StatefulWidget {
  const JobStatusBadge({
    super.key,
    required this.status,
    this.date,
    this.time,
    this.durationHours,
    this.onPhaseChanged,
  });

  final JobStatus status;

  /// Session date, time string (e.g. "08:00"), and duration — needed for
  /// live scheduled→active→completed transitions.
  final DateTime? date;
  final String? time;
  final int? durationHours;

  /// Called when the live phase changes (e.g. upcoming→active→completed).
  final VoidCallback? onPhaseChanged;

  @override
  State<JobStatusBadge> createState() => _JobStatusBadgeState();
}

class _JobStatusBadgeState extends State<JobStatusBadge>
    with WidgetsBindingObserver {
  Timer? _timer;

  /// Effective display status (may differ from backend status).
  late _DisplayStatus _display;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _computeAndSchedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timer?.cancel();
      setState(() => _computeAndSchedule());
      widget.onPhaseChanged?.call();
    }
  }

  @override
  void didUpdateWidget(JobStatusBadge old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status ||
        old.date != widget.date ||
        old.time != widget.time ||
        old.durationHours != widget.durationHours) {
      _timer?.cancel();
      _computeAndSchedule();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _computeAndSchedule() {
    final now = DateTime.now();
    final startsAt = _startsAt;
    final endsAt = _endsAt;

    debugPrint(
      '[JobStatusBadge] status=${widget.status}, now=$now, '
      'startsAt=$startsAt, endsAt=$endsAt',
    );

    // Only apply live logic when backend says scheduled AND we have time data.
    if (widget.status == JobStatus.scheduled &&
        startsAt != null &&
        endsAt != null) {
      if (now.isBefore(startsAt)) {
        _display = _DisplayStatus.upcoming;
        _scheduleAt(startsAt);
      } else if (now.isBefore(endsAt)) {
        _display = _DisplayStatus.active;
        _scheduleAt(endsAt);
      } else {
        _display = _DisplayStatus.completed;
      }
    } else if (widget.status == JobStatus.completed) {
      _display = _DisplayStatus.completed;
    } else if (widget.status == JobStatus.cancelled) {
      _display = _DisplayStatus.cancelled;
    } else {
      _display = _DisplayStatus.upcoming;
    }
  }

  void _scheduleAt(DateTime target) {
    final delay = target.difference(DateTime.now());
    if (delay.isNegative) {
      _computeAndSchedule();
      return;
    }
    _timer = Timer(delay, () {
      if (mounted) {
        setState(() => _computeAndSchedule());
        widget.onPhaseChanged?.call();
      }
    });
  }

  DateTime? get _startsAt {
    if (widget.date == null || widget.time == null) return null;
    final parts = widget.time!.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(
      widget.date!.year,
      widget.date!.month,
      widget.date!.day,
      hour,
      minute,
    );
  }

  DateTime? get _endsAt {
    final start = _startsAt;
    if (start == null || widget.durationHours == null) return null;
    return start.add(Duration(hours: widget.durationHours!));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg;
    final Color fg;
    final String label;

    switch (_display) {
      case _DisplayStatus.completed:
        bg = isDark ? AppColors.teal.withAlpha(30) : const Color(0xFFE0F5F5);
        fg = isDark ? const Color(0xFF80CBC4) : AppColors.teal;
        label = AppStrings.jobCompleted;
      case _DisplayStatus.upcoming:
        bg = isDark ? AppColors.info.withAlpha(30) : AppColors.statusBlueBg;
        fg = isDark ? const Color(0xFF64B5F6) : AppColors.info;
        label = AppStrings.jobUpcoming;
      case _DisplayStatus.active:
        bg = isDark ? AppColors.success.withAlpha(30) : AppColors.statusGreenBg;
        fg = isDark ? const Color(0xFF81C784) : AppColors.success;
        label = AppStrings.jobActive;
      case _DisplayStatus.cancelled:
        bg = isDark ? AppColors.coral.withAlpha(30) : AppColors.statusRedBg;
        fg = AppColors.coral;
        label = AppStrings.jobCancelled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _DisplayStatus { upcoming, active, completed, cancelled }
