import 'dart:async';

import 'package:flutter/material.dart';

import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/utils/job_helpers.dart';

/// Status chip za Job - colored capsule with label.
///
/// Automatically transitions scheduled→active→completed based on time.
class JobStatusBadge extends StatefulWidget {
  const JobStatusBadge({
    super.key,
    required this.status,
    this.date,
    this.from,
    this.to,
  });

  final JobStatus status;
  final DateTime? date;
  final TimeOfDay? from;
  final TimeOfDay? to;

  @override
  State<JobStatusBadge> createState() => _JobStatusBadgeState();
}

class _JobStatusBadgeState extends State<JobStatusBadge>
    with WidgetsBindingObserver {
  Timer? _timer;
  late _Phase _phase;

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
    }
  }

  @override
  void didUpdateWidget(JobStatusBadge old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status ||
        old.date != widget.date ||
        old.from != widget.from ||
        old.to != widget.to) {
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

    if (widget.status == JobStatus.scheduled &&
        startsAt != null &&
        endsAt != null) {
      if (now.isBefore(startsAt)) {
        _phase = _Phase.upcoming;
        _scheduleAt(startsAt);
      } else if (now.isBefore(endsAt)) {
        _phase = _Phase.active;
        _scheduleAt(endsAt);
      } else {
        _phase = _Phase.completed;
      }
    } else if (widget.status == JobStatus.completed) {
      _phase = _Phase.completed;
    } else if (widget.status == JobStatus.cancelled) {
      _phase = _Phase.cancelled;
    } else {
      _phase = _Phase.upcoming;
    }
  }

  void _scheduleAt(DateTime target) {
    final delay = target.difference(DateTime.now());
    if (delay.isNegative) {
      _computeAndSchedule();
      return;
    }
    _timer = Timer(delay, () {
      if (mounted) setState(() => _computeAndSchedule());
    });
  }

  DateTime? get _startsAt {
    if (widget.date == null || widget.from == null) return null;
    return DateTime(
      widget.date!.year,
      widget.date!.month,
      widget.date!.day,
      widget.from!.hour,
      widget.from!.minute,
    );
  }

  DateTime? get _endsAt {
    if (widget.date == null || widget.to == null) return null;
    return DateTime(
      widget.date!.year,
      widget.date!.month,
      widget.date!.day,
      widget.to!.hour,
      widget.to!.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final JobStatus effectiveStatus;
    switch (_phase) {
      case _Phase.upcoming:
        effectiveStatus = JobStatus.scheduled;
      case _Phase.active:
        effectiveStatus = JobStatus.scheduled; // use active colors below
      case _Phase.completed:
        effectiveStatus = JobStatus.completed;
      case _Phase.cancelled:
        effectiveStatus = JobStatus.cancelled;
    }

    final Color bg;
    final Color fg;
    final String label;

    if (_phase == _Phase.active) {
      final isDark = brightness == Brightness.dark;
      bg = isDark
          ? const Color(0xFF009D9D).withAlpha(30)
          : const Color(0xFFE0F5F5);
      fg = isDark ? const Color(0xFF80CBC4) : const Color(0xFF009D9D);
      label = JobHelpers.activeLabel;
    } else {
      bg = JobHelpers.statusBgColor(effectiveStatus, brightness);
      fg = JobHelpers.statusColor(effectiveStatus, brightness);
      label = JobHelpers.statusLabel(effectiveStatus);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

enum _Phase { upcoming, active, completed, cancelled }
