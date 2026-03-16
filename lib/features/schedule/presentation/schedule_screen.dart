import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/widgets/job_status_badge.dart';
import 'package:helpi_app/features/schedule/presentation/job_detail_screen.dart';

/// Raspored ekran — tjedni strip + lista poslova za odabrani dan.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _selectedDate;
  late DateTime _weekStart;
  List<Job> _jobs = [];
  Set<DateTime> _datesWithJobs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _weekStart = _getWeekStart(_selectedDate);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final userId = await TokenStorage().getUserId();
    if (userId == null || !mounted) return;

    final api = AppApiService();
    final result = await api.getSessionsByStudent(userId);
    if (!mounted) return;

    if (result.success && result.data != null) {
      _jobs = result.data!;
    } else {
      _jobs = List.of(MockJobs.all);
    }
    _datesWithJobs = {
      for (final j in _jobs)
        DateTime(j.date.year, j.date.month, j.date.day),
    };
    setState(() => _isLoading = false);
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

  List<Job> _jobsForDate(DateTime date) {
    return _jobs
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

  bool _hasJobs(DateTime date) {
    return _datesWithJobs.contains(DateTime(date.year, date.month, date.day));
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
            setState(() {
              final idx = _jobs.indexWhere((j) => j.id == updated.id);
              if (idx != -1) {
                _jobs[idx] = updated;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.scheduleTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final teal = theme.colorScheme.secondary;
    final todayJobs = _jobsForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.scheduleTitle)),
      body: Column(
        children: [
          // ── Tjedni strip ──
          _WeekStrip(
            weekStart: _weekStart,
            selectedDate: _selectedDate,
            hasJobs: _hasJobs,
            onDateSelected: _selectDate,
            onPreviousWeek: _previousWeek,
            onNextWeek: _nextWeek,
            teal: teal,
          ),

          // ── Odabrani dan label ──
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

          // ── Lista poslova ──
          Expanded(
            child: todayJobs.isEmpty
                ? _EmptyDayState(theme: theme, teal: teal)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: todayJobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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
//  WEEKLY STRIP — horizontalni tjedan s navigacijom
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: HelpiTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // ── Month + arrows ──
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

          // ── Days row ──
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
                                ? Colors.white
                                : HelpiTheme.textSecondary,
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
                                  ? Colors.white
                                  : isToday
                                  ? teal
                                  : const Color(0xFF2D2D2D),
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
                                ? (isSelected ? Colors.white : HelpiTheme.coral)
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
    // Prikaži mjesec + godinu sredine tjedna
    final mid = weekStart.add(const Duration(days: 3));
    return '${AppStrings.monthName(mid.month)} ${mid.year}';
  }
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY STATE — kada nema poslova za odabrani dan
// ═══════════════════════════════════════════════════════════════

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({required this.theme, required this.teal});

  final ThemeData theme;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 80,
              color: teal.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.scheduleNoJobs,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.scheduleNoJobsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: HelpiTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  JOB CARD — kartica jednog posla
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HelpiTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gornji dio: vrijeme + status chip ──
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
                    JobStatusBadge(status: job.status),
                  ],
                ),
              ),

              const Divider(height: 20, thickness: 0.5),

              // ── Korisnik ──
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

              // ── Adresa ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: HelpiTheme.textSecondary,
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

              // ── Prikaži više ──
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
