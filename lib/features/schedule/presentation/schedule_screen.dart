import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/providers/realtime_sync_provider.dart';
import 'package:helpi_app/features/notifications/presentation/notifications_screen.dart';
import 'package:helpi_app/shared/widgets/helpi_empty_state.dart';
import 'package:helpi_app/core/providers/jobs_provider.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/widgets/job_status_badge.dart';
import 'package:helpi_app/features/schedule/presentation/job_detail_screen.dart';

/// Schedule screen - weekly strip + job list for selected day.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _selectedDate;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _weekStart = _getWeekStart(_selectedDate);

    // Trigger initial load
    Future.microtask(() => ref.read(jobsProvider.notifier).loadJobs());
  }

  DateTime _getWeekStart(DateTime date) {
    // Ponedjeljak = 1
    final diff = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: diff));
  }

  List<Job> _jobsForDate(DateTime date, List<Job> jobs) {
    return jobs
        .where(
          (j) =>
              j.date.year == date.year &&
              j.date.month == date.month &&
              j.date.day == date.day,
        )
        .toList()
      ..sort(
        (a, b) => (a.from.hour * 60 + a.from.minute).compareTo(
          b.from.hour * 60 + b.from.minute,
        ),
      );
  }

  bool _hasJobs(DateTime date, Set<DateTime> datesWithJobs) {
    return datesWithJobs.contains(DateTime(date.year, date.month, date.day));
  }

  void _selectDate(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = date);
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _selectedDate = _weekStart;
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _selectedDate = _weekStart;
    });
  }

  String _formatDate(DateTime date) => Formatters.formatDateShort(date);

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) return AppStrings.scheduleToday;
    if (date == tomorrow) return AppStrings.scheduleTomorrow;

    final dayNames = [
      AppStrings.dayMonShort,
      AppStrings.dayTueShort,
      AppStrings.dayWedShort,
      AppStrings.dayThuShort,
      AppStrings.dayFriShort,
      AppStrings.daySatShort,
      AppStrings.daySunShort,
    ];
    return '${dayNames[date.weekday - 1]}, ${_formatDate(date)}';
  }

  void _openJobDetail(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => JobDetailScreen(
          job: job,
          onJobUpdated: (updated) {
            // Refresh from API to keep in sync
            ref.read(jobsProvider.notifier).loadJobs();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);

    if (jobsState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.scheduleTitle),
          actions: [_NotifBell(ref: ref)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final jobs = jobsState.jobs;
    final datesWithJobs = {
      for (final j in jobs) DateTime(j.date.year, j.date.month, j.date.day),
    };

    final theme = Theme.of(context);
    final teal = theme.colorScheme.secondary;
    final todayJobs = _jobsForDate(_selectedDate, jobs);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.scheduleTitle),
        actions: [_NotifBell(ref: ref)],
      ),
      body: Column(
        children: [
          // -- Weekly strip --
          _WeekStrip(
            weekStart: _weekStart,
            selectedDate: _selectedDate,
            hasJobs: (date) => _hasJobs(date, datesWithJobs),
            onDateSelected: _selectDate,
            onPreviousWeek: _previousWeek,
            onNextWeek: _nextWeek,
            teal: teal,
          ),

          // -- Selected day label --
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _dayLabel(_selectedDate),
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),

          // -- Jobs list --
          Expanded(
            child: todayJobs.isEmpty
                ? HelpiEmptyState(
                    icon: Icons.event_available_outlined,
                    title: AppStrings.scheduleNoJobs,
                    subtitle: AppStrings.scheduleNoJobsSubtitle,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: todayJobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final job = todayJobs[index];
                      return _JobCard(
                        job: job,
                        theme: theme,
                        teal: teal,
                        onTap: () => _openJobDetail(job),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WEEKLY STRIP - horizontalni tjedan s navigacijom
// ═══════════════════════════════════════════════════════════════

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.weekStart,
    required this.selectedDate,
    required this.hasJobs,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.teal,
  });

  final DateTime weekStart;
  final DateTime selectedDate;
  final bool Function(DateTime) hasJobs;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dayLabels = [
      AppStrings.dayMonShort,
      AppStrings.dayTueShort,
      AppStrings.dayWedShort,
      AppStrings.dayThuShort,
      AppStrings.dayFriShort,
      AppStrings.daySatShort,
      AppStrings.daySunShort,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // -- Month + arrows --
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  onPressed: onPreviousWeek,
                  color: teal,
                ),
                Text(
                  _monthLabel(context),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 28),
                  onPressed: onNextWeek,
                  color: teal,
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // -- Days row --
          Row(
            children: List.generate(7, (i) {
              final date = weekStart.add(Duration(days: i));
              final isSelected =
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final hasDot = hasJobs(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isToday && !isSelected
                                ? Border.all(color: teal, width: 2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : isToday
                                  ? teal
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Dot indicator za dane s poslom
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasDot
                                ? (isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : HelpiTheme.coral)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _monthLabel(BuildContext context) {
    // Show month + year of week middle
    final mid = weekStart.add(const Duration(days: 3));
    return '${AppStrings.monthName(mid.month)} ${mid.year}';
  }
}

// ═══════════════════════════════════════════════════════════════
//  JOB CARD - single job card
// ═══════════════════════════════════════════════════════════════

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.theme,
    required this.teal,
    this.onTap,
  });

  final Job job;
  final ThemeData theme;
  final Color teal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Top: time + status chip --
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: teal),
                    const SizedBox(width: 8),
                    Text(
                      '${Formatters.formatTime(job.from)} – ${Formatters.formatTime(job.to)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    JobStatusBadge(
                      status: job.status,
                      date: job.date,
                      from: job.from,
                      to: job.to,
                    ),
                  ],
                ),
              ),

              const Divider(height: 20, thickness: 0.5),

              // -- User --
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: teal),
                    const SizedBox(width: 8),
                    Text(
                      job.seniorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20, thickness: 0.5),

              // -- Address --
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.address,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20, thickness: 0.5),

              // -- Show more --
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.showMore,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: teal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 20, color: teal),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable notification bell icon for AppBar actions.
class _NotifBell extends ConsumerWidget {
  const _NotifBell({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationsUnreadProvider);
    return IconButton(
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 9 ? '9+' : '$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: AppStrings.notificationsTitle,
    );
  }
}
