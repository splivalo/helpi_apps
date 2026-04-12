import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/providers/jobs_provider.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/widgets/helpi_card.dart';
import 'package:helpi_app/features/schedule/widgets/star_rating.dart';

/// Statistics screen - weekly/monthly hours overview + average rating.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  late DateTime _currentWeekStart;
  late DateTime _currentMonthStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    _currentMonthStart = DateTime(now.year, now.month);
  }

  // Data helpers

  List<Job> get _allJobs => ref.read(jobsProvider).jobs;

  List<Job> get _completedJobs =>
      _allJobs.where((j) => j.status == JobStatus.completed).toList();

  double _hoursForJobs(List<Job> jobs) {
    double sum = 0;
    for (final j in jobs) {
      final fromMin = j.from.hour * 60 + j.from.minute;
      final toMin = j.to.hour * 60 + j.to.minute;
      sum += (toMin - fromMin) / 60;
    }
    return sum;
  }

  List<Job> _jobsInRange(DateTime from, DateTime to) {
    return _completedJobs.where((j) {
      final d = DateTime(j.date.year, j.date.month, j.date.day);
      return !d.isBefore(from) && d.isBefore(to);
    }).toList();
  }

  List<double> _weeklyHours(DateTime weekStart) {
    final result = List.filled(7, 0.0);
    final jobs = _jobsInRange(
      weekStart,
      weekStart.add(const Duration(days: 7)),
    );
    for (final j in jobs) {
      final d = DateTime(j.date.year, j.date.month, j.date.day);
      final dayIndex = d.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        final fromMin = j.from.hour * 60 + j.from.minute;
        final toMin = j.to.hour * 60 + j.to.minute;
        result[dayIndex] += (toMin - fromMin) / 60;
      }
    }
    return result;
  }

  List<_WeekRange> _monthlyWeeks(DateTime monthStart) {
    final weeks = <_WeekRange>[];
    var weekStart = monthStart.subtract(Duration(days: monthStart.weekday - 1));
    final nextMonth = (monthStart.month == 12)
        ? DateTime(monthStart.year + 1, 1)
        : DateTime(monthStart.year, monthStart.month + 1);

    while (weekStart.isBefore(nextMonth)) {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final jobs = _jobsInRange(weekStart, weekEnd);
      final hours = _hoursForJobs(jobs);
      weeks.add(
        _WeekRange(
          from: weekStart,
          to: weekEnd.subtract(const Duration(days: 1)),
          hours: hours,
        ),
      );
      weekStart = weekEnd;
    }
    return weeks;
  }

  double _averageRating() {
    final reviewed = _completedJobs.where((j) => j.review != null).toList();
    if (reviewed.isEmpty) return 0;
    final sum = reviewed.fold<int>(0, (s, j) => s + j.review!.rating);
    return sum / reviewed.length;
  }

  // Format helpers

  String _fmtDate(DateTime d) => Formatters.formatDateCompact(d);

  String _fmtDateFull(DateTime d) => Formatters.formatDateFull(d);

  List<String> get _dayLabels => AppStrings.statsDayLabels;

  List<String> get _monthNames => [
    AppStrings.monthName(1),
    AppStrings.monthName(2),
    AppStrings.monthName(3),
    AppStrings.monthName(4),
    AppStrings.monthName(5),
    AppStrings.monthName(6),
    AppStrings.monthName(7),
    AppStrings.monthName(8),
    AppStrings.monthName(9),
    AppStrings.monthName(10),
    AppStrings.monthName(11),
    AppStrings.monthName(12),
  ];

  // Navigation

  void _prevWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      final m = _currentMonthStart.month;
      final y = _currentMonthStart.year;
      _currentMonthStart = m == 1 ? DateTime(y - 1, 12) : DateTime(y, m - 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      final m = _currentMonthStart.month;
      final y = _currentMonthStart.year;
      _currentMonthStart = m == 12 ? DateTime(y + 1, 1) : DateTime(y, m + 1);
    });
  }

  // Build

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);

    if (jobsState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.statsTitle),
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.statsTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          _buildWeeklySection(theme),
          const SizedBox(height: 24),
          _buildMonthlySection(theme),
          const SizedBox(height: 24),
          _buildRatingSection(theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Weekly section

  Widget _buildWeeklySection(ThemeData theme) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final dailyHours = _weeklyHours(_currentWeekStart);
    final totalHours = dailyHours.fold(0.0, (a, b) => a + b);
    final maxH = dailyHours.reduce((a, b) => a > b ? a : b);

    final prevWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    final prevHours = _weeklyHours(prevWeekStart);
    final prevTotal = prevHours.fold(0.0, (a, b) => a + b);

    return HelpiCard(
      child: Column(
        children: [
          Text(
            AppStrings.statsWeeklyReview,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _prevWeek,
                splashRadius: 20,
              ),
              Text(
                '${_fmtDate(_currentWeekStart)} – ${_fmtDateFull(weekEnd)}',
                style: theme.textTheme.bodyMedium,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _nextWeek,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = dailyHours[i];
                final barRatio = maxH > 0 ? h / maxH : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (h > 0)
                          Text(
                            '${h.toStringAsFixed(0)}h',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: maxH > 0 ? 100 * barRatio : 0,
                          constraints: const BoxConstraints(minHeight: 4),
                          decoration: BoxDecoration(
                            color: h > 0
                                ? HelpiTheme.teal
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _buildComparison(
            theme,
            totalHours,
            prevTotal,
            AppStrings.statsPeriodWeek,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppStrings.statsTotalHoursValue(totalHours.toStringAsFixed(1)),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Monthly section

  Widget _buildMonthlySection(ThemeData theme) {
    final weeks = _monthlyWeeks(_currentMonthStart);
    final totalHours = weeks.fold(0.0, (s, w) => s + w.hours);
    final maxH = weeks.isEmpty
        ? 1.0
        : weeks.map((w) => w.hours).reduce((a, b) => a > b ? a : b);

    final prevMonth = _currentMonthStart.month == 1
        ? DateTime(_currentMonthStart.year - 1, 12)
        : DateTime(_currentMonthStart.year, _currentMonthStart.month - 1);
    final prevWeeks = _monthlyWeeks(prevMonth);
    final prevTotal = prevWeeks.fold(0.0, (s, w) => s + w.hours);

    return HelpiCard(
      child: Column(
        children: [
          Text(
            AppStrings.statsMonthlyReview,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _prevMonth,
                splashRadius: 20,
              ),
              Text(
                _monthNames[_currentMonthStart.month - 1],
                style: theme.textTheme.bodyMedium,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _nextMonth,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeks.asMap().entries.map((entry) {
                final w = entry.value;
                final barRatio = maxH > 0 ? w.hours / maxH : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (w.hours > 0)
                          Flexible(
                            child: Text(
                              '${w.hours.toStringAsFixed(0)}h',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: maxH > 0 ? 100 * barRatio : 0,
                          constraints: const BoxConstraints(minHeight: 4),
                          decoration: BoxDecoration(
                            color: w.hours > 0
                                ? HelpiTheme.teal
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_fmtDate(w.from)}\n${_fmtDate(w.to)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildComparison(
            theme,
            totalHours,
            prevTotal,
            AppStrings.statsPeriodMonth,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppStrings.statsTotalHoursValue(totalHours.toStringAsFixed(1)),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Comparison widget

  Widget _buildComparison(
    ThemeData theme,
    double current,
    double previous,
    String period,
  ) {
    if (previous == 0 && current == 0) {
      return const SizedBox.shrink();
    }

    String text;
    Color color;
    IconData icon;

    if (previous == 0) {
      text = AppStrings.statsCompareMore('100', period);
      color = HelpiTheme.teal;
      icon = Icons.trending_up;
    } else if (current == previous) {
      text = AppStrings.statsCompareSame(period);
      color = theme.colorScheme.onSurfaceVariant;
      icon = Icons.trending_flat;
    } else {
      final pct = (((current - previous).abs() / previous) * 100).round();
      if (current > previous) {
        text = AppStrings.statsCompareMore(pct.toString(), period);
        color = HelpiTheme.teal;
        icon = Icons.trending_up;
      } else {
        text = AppStrings.statsCompareLess(pct.toString(), period);
        color = HelpiTheme.coral;
        icon = Icons.trending_down;
      }
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // Rating section

  Widget _buildRatingSection(ThemeData theme) {
    final avg = _averageRating();

    return HelpiCard(
      child: Column(
        children: [
          Text(
            AppStrings.statsAvgRating,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StarRating(rating: avg.round(), size: 36),
          const SizedBox(height: 8),
          Text(
            avg > 0 ? avg.toStringAsFixed(1) : '–',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: HelpiTheme.teal,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper classes

class _WeekRange {
  const _WeekRange({required this.from, required this.to, required this.hours});

  final DateTime from;
  final DateTime to;
  final double hours;
}
