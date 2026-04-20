import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/pricing.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/utils/snackbar_helper.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/utils/availability_helpers.dart';
import 'package:helpi_app/features/schedule/widgets/availability_day_row.dart';

/// Sub-screen: student weekly availability grid with edit/save.
class ProfileAvailabilityScreen extends StatefulWidget {
  const ProfileAvailabilityScreen({
    super.key,
    required this.availabilityNotifier,
    this.studentUserId,
  });

  final AvailabilityNotifier availabilityNotifier;
  final int? studentUserId;

  @override
  State<ProfileAvailabilityScreen> createState() =>
      _ProfileAvailabilityScreenState();
}

class _ProfileAvailabilityScreenState extends State<ProfileAvailabilityScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  /// Snapshot of availability before editing (to detect harmful changes).
  Map<int, _DaySnap> _oldAvail = {};

  /// Cached upcoming sessions fetched when editing starts.
  List<Job> _cachedSessions = [];

  List<DayAvailability> get _availability => widget.availabilityNotifier.value;

  Future<void> _startEditing() async {
    // Capture current state before user edits
    _oldAvail = {};
    for (final day in _availability) {
      final wd = AvailabilityNotifier.dayKeyToWeekday(day.dayKey);
      _oldAvail[wd] = _DaySnap(
        enabled: day.enabled,
        from: day.from,
        to: day.to,
      );
    }

    // Pre-fetch upcoming sessions for instant conflict checks
    final userId = widget.studentUserId ?? await TokenStorage().getUserId();
    if (!mounted) return;
    if (userId != null) {
      final result = await AppApiService().getUpcomingSessionsByStudent(userId);
      if (!mounted) return;
      _cachedSessions = (result.success && result.data != null)
          ? result.data!
          : [];
    }

    setState(() => _isEditing = true);
  }

  void _restoreOldAvail() {
    for (final day in _availability) {
      final wd = AvailabilityNotifier.dayKeyToWeekday(day.dayKey);
      final snap = _oldAvail[wd];
      if (snap == null) continue;
      day.enabled = snap.enabled;
      day.from = snap.from;
      day.to = snap.to;
    }
    widget.availabilityNotifier.notify();
  }

  Future<void> _pickTime({
    required DayAvailability day,
    required bool isFrom,
  }) async {
    // Save current times in case we need to revert
    final prevFrom = day.from;
    final prevTo = day.to;

    final changed = await pickAvailabilityTime(
      context: context,
      day: day,
      isFrom: isFrom,
    );
    if (!changed) return;
    if (!mounted) return;

    // Instant conflict check against cached sessions
    if (_hasConflictOnDay(day)) {
      // Revert to previous times
      day.from = prevFrom;
      day.to = prevTo;
      showHelpiSnackBar(
        context,
        AppStrings.availabilityChangeDisabled,
        isError: true,
      );
      return;
    }

    setState(() {});
    widget.availabilityNotifier.notify();
  }

  /// Checks whether the current [day] availability would NOT cover
  /// a session that was previously covered (old snapshot).
  bool _hasConflictOnDay(DayAvailability day) {
    final wd = AvailabilityNotifier.dayKeyToWeekday(day.dayKey);
    final oldDay = _oldAvail[wd];
    final now = DateTime.now();

    for (final job in _cachedSessions) {
      if (job.date.weekday != wd) continue;

      final jobStart = DateTime(
        job.date.year,
        job.date.month,
        job.date.day,
        job.from.hour,
        job.from.minute,
      );
      if (!jobStart.isAfter(now)) continue;

      final wasCovered =
          oldDay != null &&
          oldDay.enabled &&
          _timeLeq(oldDay.from, job.from) &&
          _timeLeq(job.to, oldDay.to);

      final nowCovered =
          day.enabled &&
          _timeLeq(day.from, job.from) &&
          _timeLeq(job.to, day.to);

      if (wasCovered && !nowCovered) {
        if (!AppPricing.availabilityChangeEnabled) return true;
        final hoursUntil = jobStart.difference(now).inMinutes / 60;
        if (hoursUntil < AppPricing.availabilityChangeCutoffHours) return true;
      }
    }
    return false;
  }

  Future<void> _save() async {
    final userId = widget.studentUserId ?? await TokenStorage().getUserId();
    if (userId == null) return;
    if (!mounted) return;

    // Check upcoming sessions for cutoff rules — only block if
    // the new availability would NOT cover an existing session.
    final api = AppApiService();
    final sessionsResult = await api.getUpcomingSessionsByStudent(userId);
    if (!mounted) return;

    if (sessionsResult.success && sessionsResult.data != null) {
      final now = DateTime.now();
      // Build a weekday→DayAvailability map from the NEW (edited) state
      final Map<int, DayAvailability> newMap = {};
      for (final day in _availability) {
        final wd = AvailabilityNotifier.dayKeyToWeekday(day.dayKey);
        newMap[wd] = day;
      }

      for (final job in sessionsResult.data!) {
        final jobStart = DateTime(
          job.date.year,
          job.date.month,
          job.date.day,
          job.from.hour,
          job.from.minute,
        );
        if (!jobStart.isAfter(now)) continue;

        final wd = job.date.weekday; // 1=Mon … 7=Sun
        final newDay = newMap[wd];
        final oldDay = _oldAvail[wd];

        // Did the OLD availability cover this session?
        final wasCovered =
            oldDay != null &&
            oldDay.enabled &&
            _timeLeq(oldDay.from, job.from) &&
            _timeLeq(job.to, oldDay.to);

        // Does the NEW availability still cover it?
        final nowCovered =
            newDay != null &&
            newDay.enabled &&
            _timeLeq(newDay.from, job.from) &&
            _timeLeq(job.to, newDay.to);

        // Only block if previously covered → now NOT covered
        if (wasCovered && !nowCovered) {
          // This change would jeopardise the session
          final hoursUntil = jobStart.difference(now).inMinutes / 60;

          if (!AppPricing.availabilityChangeEnabled) {
            // Toggle OFF → can never change if it affects a session
            _restoreOldAvail();
            setState(() => _isEditing = false);
            showHelpiSnackBar(
              context,
              AppStrings.availabilityChangeDisabled,
              isError: true,
            );
            return;
          }

          // Toggle ON → must respect cutoff hours
          if (hoursUntil < AppPricing.availabilityChangeCutoffHours) {
            _restoreOldAvail();
            setState(() => _isEditing = false);
            showHelpiSnackBar(
              context,
              AppStrings.availabilityChangeCutoff(
                AppPricing.availabilityChangeCutoffHours,
              ),
              isError: true,
            );
            return;
          }
        }
      }
    }

    if (!mounted) return;

    setState(() => _isSaving = true);

    final payload = widget.availabilityNotifier.toBackendPayload(userId);
    final result = await api.updateStudentAvailability(payload);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (result.success) _isEditing = false;
    });

    if (!result.success) {
      _restoreOldAvail();
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? AppStrings.error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.availabilitySection),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.availabilityDescription,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ..._availability.map(
            (day) => AvailabilityDayRow(
              day: day,
              enabled: _isEditing,
              onEnabledChanged: (v) {
                final prev = day.enabled;
                day.enabled = v;
                if (_hasConflictOnDay(day)) {
                  day.enabled = prev;
                  showHelpiSnackBar(
                    context,
                    AppStrings.availabilityChangeDisabled,
                    isError: true,
                  );
                  return;
                }
                setState(() {});
                widget.availabilityNotifier.notify();
              },
              onPickFrom: () => _pickTime(day: day, isFrom: true),
              onPickTo: () => _pickTime(day: day, isFrom: false),
            ),
          ),
          const SizedBox(height: 24),

          if (_isEditing) ...[
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppStrings.save),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _restoreOldAvail();
                setState(() => _isEditing = false);
              },
              child: Text(AppStrings.cancel),
            ),
          ],
        ],
      ),
    );
  }

  /// TimeOfDay a <= b ?
  static bool _timeLeq(TimeOfDay a, TimeOfDay b) =>
      a.hour < b.hour || (a.hour == b.hour && a.minute <= b.minute);
}

/// Snapshot of one day's availability before edit started.
class _DaySnap {
  const _DaySnap({required this.enabled, required this.from, required this.to});
  final bool enabled;
  final TimeOfDay from;
  final TimeOfDay to;
}
