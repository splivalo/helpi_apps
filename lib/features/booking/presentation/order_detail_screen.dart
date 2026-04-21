import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/constants/pricing.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/utils/formatters.dart';
import 'package:helpi_app/core/utils/snackbar_helper.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/features/schedule/data/review_model.dart'
    as schedule_review;
import 'package:helpi_app/shared/widgets/job_status_badge.dart';
import 'package:helpi_app/shared/widgets/review_inline_card.dart';
import 'package:helpi_app/shared/widgets/star_rating.dart';
import 'package:helpi_app/shared/widgets/status_chip.dart';
import 'package:helpi_app/shared/widgets/summary_row.dart';

/// Order details - full screen with data + Students section + reviews.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.ordersNotifier,
  });

  final OrderModel order;
  final OrdersNotifier ordersNotifier;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _jobsExpanded = false;
  List<schedule_review.ReviewModel> _pendingReviews = [];
  List<Map<String, dynamic>> _seniorCoupons = [];

  @override
  void initState() {
    super.initState();
    _jobsExpanded = true;
    widget.ordersNotifier.addListener(_onChanged);
    _loadPendingReviews();
    _loadSessions();
    _loadSeniorCoupons();
  }

  /// Fetch sessions from API and populate order.jobs.
  Future<void> _loadSessions() async {
    final api = AppApiService();

    // For recurring orders, only fetch current month sessions
    String? from;
    String? to;
    if (!widget.order.isOneTime) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      from =
          '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}';
      to =
          '${monthEnd.year}-${monthEnd.month.toString().padLeft(2, '0')}-${monthEnd.day.toString().padLeft(2, '0')}';
    }

    final result = await api.getSessionsByOrder(
      widget.order.id,
      from: from,
      to: to,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      final order = widget.order;
      order.jobs.clear();
      for (final json in result.data!) {
        // Parse date/time
        final dateStr = json['scheduledDate'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        final startParts = (json['startTime'] as String? ?? '09:00:00').split(
          ':',
        );
        final endParts = (json['endTime'] as String? ?? '11:00:00').split(':');
        final fromH = int.tryParse(startParts[0]) ?? 0;
        final fromM = startParts.length > 1
            ? int.tryParse(startParts[1]) ?? 0
            : 0;
        final toH = int.tryParse(endParts[0]) ?? 0;
        final toM = endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0;
        final durationHours = ((toH * 60 + toM) - (fromH * 60 + fromM)) ~/ 60;

        // Extract student name and assignment status
        String studentName = '';
        String studentId = '';
        bool isAssignmentPending = false;
        final assignment = json['scheduleAssignment'] as Map<String, dynamic>?;
        if (assignment != null) {
          final student = assignment['student'] as Map<String, dynamic>?;
          if (student != null) {
            studentId = student['userId']?.toString() ?? '';
            final contact = student['contact'] as Map<String, dynamic>?;
            studentName = contact?['fullName'] as String? ?? '';
          }
          // AssignmentStatus: 0=PendingAcceptance, 1=Accepted
          final assignmentStatus = (assignment['status'] as num?)?.toInt();
          isAssignmentPending = assignmentStatus == 0;
        }

        // Map backend status to booking JobStatus
        final rawStatus = json['status'];
        JobStatus status;
        if (rawStatus is int) {
          switch (rawStatus) {
            case 2:
              status = JobStatus.completed;
            case 3:
            case 4:
              status = JobStatus.cancelled;
            default:
              status = JobStatus.scheduled;
          }
        } else {
          status = JobStatus.scheduled;
        }

        // Parse review from backend — senior's review of student (seniorReview)
        ReviewModel? review;
        final reviewJson = json['seniorReview'] as Map<String, dynamic>?;
        if (reviewJson != null && reviewJson['isPending'] != true) {
          review = ReviewModel(
            rating: (reviewJson['rating'] as num?)?.toInt() ?? 0,
            comment: reviewJson['comment'] as String? ?? '',
            date:
                DateTime.tryParse(reviewJson['createdAt'] as String? ?? '') ??
                DateTime.now(),
          );
        }

        order.jobs.add(
          JobModel(
            id: (json['id'] as num?)?.toInt(),
            date: date,
            weekday: date.weekday,
            time:
                '${fromH.toString().padLeft(2, '0')}:${fromM.toString().padLeft(2, '0')}',
            durationHours: durationHours > 0 ? durationHours : 1,
            studentName: studentName,
            orderId: (json['orderId'] as num?)?.toInt().toString() ?? '',
            studentId: studentId,
            status: status,
            review: review,
            isAssignmentPending: isAssignmentPending,
          ),
        );
      }
      setState(() {});
    }
  }

  /// Fetch pending reviews for this senior.
  Future<void> _loadPendingReviews() async {
    final seniorId = await TokenStorage().getSeniorId();
    if (seniorId == null || !mounted) return;

    final api = AppApiService();
    final result = await api.getPendingReviewsBySenior(seniorId);

    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() => _pendingReviews = result.data!);
    }
  }

  Future<void> _loadSeniorCoupons() async {
    final seniorId = await TokenStorage().getSeniorId();
    if (seniorId == null || !mounted) return;
    final result = await AppApiService().getMyCoupons(seniorId);
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() {
        _seniorCoupons = result.data!
            .whereType<Map<String, dynamic>>()
            .toList();
      });
    }
  }

  void _onChanged() {
    if (!mounted) return;
    // Re-fetch sessions when orders are refreshed (e.g. via SignalR)
    _loadSessions();
    setState(() {});
  }

  @override
  void dispose() {
    widget.ordersNotifier.removeListener(_onChanged);
    super.dispose();
  }

  /// Check if a session is currently in-progress (active) based on time.
  bool _isSessionActive(JobModel job) {
    if (job.status != JobStatus.scheduled) return false;
    final timeParts = job.time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final jobStart = DateTime(
      job.date.year,
      job.date.month,
      job.date.day,
      hour,
      minute,
    );
    final jobEnd = jobStart.add(Duration(hours: job.durationHours));
    final now = DateTime.now();
    return now.isAfter(jobStart) && now.isBefore(jobEnd);
  }

  /// Check if a session is effectively done (time has passed) even if backend
  /// hasn't marked it completed yet.
  bool _isSessionDone(JobModel job) {
    if (job.status == JobStatus.completed) return true;
    if (job.status != JobStatus.scheduled) return false;
    final timeParts = job.time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final jobEnd = DateTime(
      job.date.year,
      job.date.month,
      job.date.day,
      hour,
      minute,
    ).add(Duration(hours: job.durationHours));
    return DateTime.now().isAfter(jobEnd);
  }

  String _couponLabel(int type, double value, num? remaining) {
    switch (type) {
      case 0: // MonthlyHours
      case 1: // WeeklyHours
      case 2: // OneTimeHours
        final h = remaining?.toStringAsFixed(0) ?? value.toStringAsFixed(0);
        return AppStrings.couponHoursRemaining(h);
      default:
        return '';
    }
  }

  /// Check if a specific job can be cancelled (time > cutoff).
  bool _canCancelJob(JobModel job) {
    if (job.status != JobStatus.scheduled) return false;
    // Exclude sessions that are effectively done (time passed) even if the
    // backend hasn't marked them Completed yet (Hangfire delay).
    if (_isSessionDone(job)) return false;
    final timeParts = job.time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final jobStart = DateTime(
      job.date.year,
      job.date.month,
      job.date.day,
      hour,
      minute,
    );
    return jobStart.difference(DateTime.now()).inMinutes >
        AppPricing.seniorCancelCutoffHours * 60;
  }

  /// Check if the order-level cancel is allowed.
  bool _canCancelOrder(OrderModel order) {
    // Processing = no sessions yet, always cancellable.
    if (order.status == OrderStatus.processing) return true;
    if (order.status != OrderStatus.active) return false;

    // One-time order with known time.
    if (order.isOneTime && order.fromHour != null && order.fromMinute != null) {
      final sessionStart = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
        order.fromHour!,
        order.fromMinute!,
      );
      return sessionStart.difference(DateTime.now()).inMinutes >
          AppPricing.seniorCancelCutoffHours * 60;
    }

    // Recurring order — check nearest upcoming scheduled job.
    // Exclude sessions effectively done (time passed, Hangfire not yet run).
    final upcoming = order.jobs
        .where((j) => j.status == JobStatus.scheduled && !_isSessionDone(j))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (upcoming.isEmpty) return false;
    return _canCancelJob(upcoming.first);
  }

  Future<void> _cancelOrder(int orderId) async {
    final api = AppApiService();
    final result = await api.cancelOrder(orderId);

    if (!mounted) return;

    if (result.success) {
      widget.ordersNotifier.cancelOrder(orderId);
      Navigator.pop(context);
    } else {
      showHelpiSnackBar(
        context,
        result.error ?? AppStrings.error,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.orderDetails)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -- Header --
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.orderNumber(
                              order.orderNumber > 0
                                  ? order.orderNumber.toString()
                                  : order.id.toString(),
                            ),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // -- Summary card --
                    _summaryCard(theme, order),
                    const SizedBox(height: 16),

                    // -- Info banner for processing orders --
                    if (order.status == OrderStatus.processing) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppStrings.processingBanner,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // -- Jobs / sessions --
                    _jobsSection(theme, order),

                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // -- Sticky bottom action buttons --
            if (_canCancelOrder(order))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _cancelOrder(order.id);
                    },
                    icon: const Icon(Icons.close, size: 20),
                    label: Text(AppStrings.cancelOrder),
                    style: AppColors.coralOutlinedStyle,
                  ),
                ),
              ),
            if (order.status == OrderStatus.completed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _repeatOrder(order),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(AppStrings.repeatOrder),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -- Summary card (like Preview) --
  Widget _summaryCard(ThemeData theme, OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frequency
          SummaryRow(
            label: AppStrings.orderSummaryFrequency,
            value: order.frequency,
          ),
          const Divider(height: 24),

          // Date
          SummaryRow(
            label: order.isOneTime
                ? AppStrings.orderSummaryDate
                : AppStrings.orderSummaryStartDate,
            value: AppFormatters.date(order.date),
          ),

          if (order.endDate != null) ...[
            const Divider(height: 24),
            SummaryRow(
              label: AppStrings.orderSummaryEndDate,
              value: AppFormatters.date(order.endDate!),
            ),
          ],

          // One-time: time + duration + price
          if (order.isOneTime) ...[
            const Divider(height: 24),
            SummaryRow(label: AppStrings.orderSummaryTime, value: order.time),
            const Divider(height: 24),
            SummaryRow(
              label: AppStrings.orderSummaryDuration,
              value: order.duration,
            ),
            if (order.durationHours > 0) ...[
              const Divider(height: 24),
              SummaryRow(
                label: AppStrings.orderSummaryPrice,
                value: AppPricing.formatPrice(
                  AppPricing.priceForDay(order.weekday, order.durationHours),
                ),
                bold: true,
              ),
            ],
          ],

          // Recurring: day entries
          if (!order.isOneTime && order.dayEntries.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              AppStrings.orderSummaryDays,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...order.dayEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      AppFormatters.dayMediumName(entry.weekday),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.durationHours > 0
                          ? '${entry.time}  ·  ${entry.durationHours}h  ·  ${AppPricing.formatPrice(AppPricing.priceForDay(entry.weekday, entry.durationHours))}'
                          : '${entry.time}  ·  ${entry.duration}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            // Weekly total
            if (order.dayEntries.any((e) => e.durationHours > 0)) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Text(
                    AppStrings.orderSummaryWeeklyTotal,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppPricing.formatPrice(
                      order.dayEntries.fold<int>(
                        0,
                        (sum, e) =>
                            sum +
                            AppPricing.priceForDay(e.weekday, e.durationHours),
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],

          const Divider(height: 24),

          // Services as text list
          Text(
            AppStrings.orderSummaryServices,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(order.services.join(', '), style: theme.textTheme.bodyMedium),

          // Notes
          if (order.notes.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              AppStrings.orderSummaryNotes,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(order.notes, style: theme.textTheme.bodyMedium),
          ],

          // Coupons
          if (_seniorCoupons.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              AppStrings.couponActive,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 0,
              children: _seniorCoupons.map((c) {
                final code = c['couponCode'] as String? ?? '';
                final type = (c['couponType'] as num?)?.toInt() ?? 0;
                final value = (c['couponValue'] as num?)?.toDouble() ?? 0;
                final remaining = c['remainingValue'] as num?;
                return Chip(
                  avatar: Icon(
                    Icons.local_offer,
                    size: 14,
                    color: AppColors.coral,
                  ),
                  label: Text(
                    '$code · ${_couponLabel(type, value, remaining)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // -- Jobs / sessions section --
  Widget _jobsSection(ThemeData theme, OrderModel order) {
    if (order.jobs.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _jobsExpanded = !_jobsExpanded);
            },
            child: Row(
              children: [
                Text(
                  order.isOneTime
                      ? AppStrings.jobSectionSingular
                      : AppStrings.jobsSection,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  _jobsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (!order.isOneTime) ...[
            const SizedBox(height: 6),
            Text(
              AppStrings.jobsMonthlySubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_jobsExpanded) ...[
            const SizedBox(height: 16),
            ...order.jobs.asMap().entries.map((mapEntry) {
              final jobIndex = mapEntry.key;
              final job = mapEntry.value;
              final isLast = jobIndex == order.jobs.length - 1;
              final price = AppPricing.priceForDay(
                job.weekday,
                job.durationHours,
              );

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: _jobCard(theme, order, jobIndex, job, price),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _jobCard(
    ThemeData theme,
    OrderModel order,
    int jobIndex,
    JobModel job,
    int price,
  ) {
    final isCancelled = job.status == JobStatus.cancelled;
    final isUpcoming = job.status == JobStatus.scheduled;
    final isActive = _isSessionActive(job);
    final effectivelyCompleted = _isSessionDone(job);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: date + status badge
          Row(
            children: [
              Icon(
                effectivelyCompleted
                    ? Icons.check_circle
                    : isCancelled
                    ? Icons.cancel
                    : isActive
                    ? Icons.play_circle_fill
                    : Icons.schedule,
                size: 18,
                color: effectivelyCompleted
                    ? AppColors.teal
                    : isCancelled
                    ? AppColors.coral
                    : isActive
                    ? AppColors.success
                    : AppColors.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppFormatters.dayMediumName(job.weekday)}, ${AppFormatters.date(job.date)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCancelled
                        ? theme.colorScheme.onSurface.withAlpha(150)
                        : theme.colorScheme.onSurface,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              JobStatusBadge(
                status: job.status,
                date: job.date,
                time: job.time,
                durationHours: job.durationHours,
                onPhaseChanged: () {
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: time · duration · price
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              '${job.time}  ·  ${job.durationHours}h  ·  ${AppPricing.formatPrice(price)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isCancelled
                    ? theme.colorScheme.onSurface.withAlpha(120)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Row 3: student name with avatar + assignment status
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? AppColors.teal.withAlpha(12)
                        : job.isAssignmentPending
                        ? AppColors.info.withAlpha(25)
                        : AppColors.teal.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    job.studentName.isEmpty
                        ? Icons.person_off_outlined
                        : job.isAssignmentPending
                        ? Icons.hourglass_top
                        : Icons.person_outline,
                    color: isCancelled
                        ? AppColors.teal.withAlpha(100)
                        : job.isAssignmentPending
                        ? AppColors.info
                        : AppColors.teal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.studentName.isEmpty
                            ? AppStrings.noStudentAssigned
                            : job.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? theme.colorScheme.onSurface.withAlpha(130)
                              : job.studentName.isEmpty
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      if (job.isAssignmentPending && job.studentName.isNotEmpty)
                        Text(
                          AppStrings.awaitingConfirmation,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.info,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Row 4: action buttons
          if (isUpcoming ||
              isActive ||
              (effectivelyCompleted && job.review == null)) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Row(
                children: [
                  // Rate button (completed only, no review yet)
                  if (effectivelyCompleted && job.review == null) ...[
                    const Spacer(),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: () => _showJobReviewSheet(order, jobIndex),
                        icon: const Icon(Icons.star, size: 14),
                        label: Text(AppStrings.rateStudent),
                        style: AppColors.tealSmallOutlinedStyle,
                      ),
                    ),
                  ],

                  // Cancel button (upcoming or active-disabled)
                  // Hidden for one-time orders — use "Otkaži narudžbu" instead.
                  if (!widget.order.isOneTime &&
                      ((isUpcoming && _canCancelJob(job)) || isActive)) ...[
                    const Spacer(),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: isActive
                            ? null
                            : () => _confirmCancelJob(order, jobIndex),
                        icon: const Icon(Icons.close, size: 14),
                        label: Text(AppStrings.cancelJobLabel),
                        style: AppColors.coralSmallOutlinedStyle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Show existing review inline
          if (job.review != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: ReviewInlineCard(
                rating: job.review!.rating,
                date: job.review!.date,
                comment: job.review!.comment,
                compact: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Repeat order: pick new date(s), then create order.
  Future<void> _repeatOrder(OrderModel order) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final lastDate = DateTime(now.year + 2);

    DateTime? startDate;
    DateTime? endDate;

    // Recurring with end date -> date range picker
    if (!order.isOneTime && order.endDate != null) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: now,
        lastDate: lastDate,
        locale: const Locale('hr'),
        confirmText: AppStrings.confirm,
        cancelText: AppStrings.cancel,
      );
      if (!mounted) return;
      if (range == null) return;

      startDate = range.start;
      endDate = range.end;
    } else {
      // One-time or recurring without end date -> single date picker
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: lastDate,
        locale: const Locale('hr'),
        confirmText: AppStrings.confirm,
        cancelText: AppStrings.cancel,
      );
      if (!mounted) return;
      if (picked == null) return;

      startDate = picked;
      endDate = order.isOneTime
          ? picked
          : picked.add(const Duration(days: 365));
    }

    // Build schedule payload from dayEntries or fallback
    final schedules = <Map<String, dynamic>>[];
    if (order.dayEntries.isNotEmpty) {
      for (final entry in order.dayEntries) {
        final fromH = order.fromHour ?? 9;
        final fromM = order.fromMinute ?? 0;
        final dur = entry.durationHours;
        schedules.add({
          'dayOfWeek': entry.weekday,
          'startTime':
              '${fromH.toString().padLeft(2, '0')}:${fromM.toString().padLeft(2, '0')}:00',
          'endTime':
              '${(fromH + dur).toString().padLeft(2, '0')}:${fromM.toString().padLeft(2, '0')}:00',
        });
      }
    } else {
      // Fallback: use weekday and durationHours from order
      final fromH = order.fromHour ?? 9;
      final fromM = order.fromMinute ?? 0;
      final dur = order.durationHours > 0 ? order.durationHours : 1;
      schedules.add({
        'dayOfWeek': startDate.weekday,
        'startTime':
            '${fromH.toString().padLeft(2, '0')}:${fromM.toString().padLeft(2, '0')}:00',
        'endTime':
            '${(fromH + dur).toString().padLeft(2, '0')}:${fromM.toString().padLeft(2, '0')}:00',
      });
    }

    // Build payload
    final seniorId = int.tryParse(order.seniorId) ?? 0;
    String fmtDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final payload = <String, dynamic>{
      'seniorId': seniorId,
      'isRecurring': !order.isOneTime,
      'startDate': fmtDate(startDate),
      'endDate': fmtDate(endDate),
      'notes': order.notes,
      'services': order.serviceIds,
      'schedules': schedules,
      if (!order.isOneTime) 'recurrencePattern': 0,
    };

    // Call API
    final api = AppApiService();
    final result = await api.createOrder(payload);

    if (!mounted) return;

    if (result.success && result.data != null) {
      widget.ordersNotifier.addProcessingOrder(result.data!);
      Navigator.pop(context, 'repeated');
    } else {
      showHelpiSnackBar(
        context,
        result.error ?? AppStrings.orderCreateError,
        isError: true,
      );
    }
  }

  /// Confirm cancel dialog for a job — calls backend API then updates local.
  void _confirmCancelJob(OrderModel order, int jobIndex) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.cancelJobLabel),
        content: Text(AppStrings.cancelJobConfirm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final job = order.jobs[jobIndex];
              if (job.id != null) {
                final result = await AppApiService().cancelSession(job.id!);
                if (!mounted) return;
                if (!result.success) {
                  showHelpiSnackBar(
                    context,
                    result.error ?? AppStrings.error,
                    isError: true,
                  );
                  return;
                }
              }
              widget.ordersNotifier.cancelJob(order.id, jobIndex);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: Text(AppStrings.cancelJobLabel),
          ),
        ],
      ),
    );
  }

  /// Resolve pending review ID for a job — ensures backend has completed
  /// the session and created pending reviews before we try to submit.
  Future<int?> _resolvePendingReviewId(int? jobInstanceId) async {
    // 1. Check local cache first
    if (jobInstanceId != null) {
      for (final pr in _pendingReviews) {
        if (pr.jobInstanceId == jobInstanceId) return pr.id;
      }
    }
    if (_pendingReviews.isNotEmpty) return _pendingReviews.first.id;

    // 2. No local match — re-fetch from backend (Hangfire may have run)
    await _loadPendingReviews();
    if (jobInstanceId != null) {
      for (final pr in _pendingReviews) {
        if (pr.jobInstanceId == jobInstanceId) return pr.id;
      }
    }
    if (_pendingReviews.isNotEmpty) return _pendingReviews.first.id;

    // 3. Still nothing — trigger ensure-completed on backend
    if (jobInstanceId != null) {
      final api = AppApiService();
      final ensureResult = await api.ensureSessionCompleted(jobInstanceId);
      if (ensureResult.success) {
        // Re-fetch pending reviews after backend created them
        await _loadPendingReviews();
        for (final pr in _pendingReviews) {
          if (pr.jobInstanceId == jobInstanceId) return pr.id;
        }
        if (_pendingReviews.isNotEmpty) return _pendingReviews.first.id;
      }
    }

    return null;
  }

  /// Review bottom sheet for a specific job.
  void _showJobReviewSheet(OrderModel order, int jobIndex) {
    final job = order.jobs[jobIndex];

    int selectedRating = 0;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 +
                    MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).viewPadding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppStrings.rateStudent}: ${job.studentName}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppFormatters.dayMediumName(job.weekday)}, ${AppFormatters.date(job.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stars
                  StarRating(
                    rating: selectedRating,
                    size: 40,
                    onTap: (rating) {
                      HapticFeedback.selectionClick();
                      setSheetState(() => selectedRating = rating);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Comment
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppStrings.reviewHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (selectedRating > 0 && !isSubmitting)
                          ? () async {
                              setSheetState(() => isSubmitting = true);

                              final api = AppApiService();

                              // Bulletproof: resolve pending review
                              final resolvedId = await _resolvePendingReviewId(
                                job.id,
                              );

                              if (!ctx.mounted) return;

                              if (resolvedId != null) {
                                final result = await api.submitReview({
                                  'reviewId': resolvedId,
                                  'rating': selectedRating.toDouble(),
                                  'comment': commentCtrl.text.trim(),
                                });

                                if (!ctx.mounted) return;

                                if (!result.success) {
                                  setSheetState(() => isSubmitting = false);
                                  showHelpiSnackBar(
                                    ctx,
                                    result.error ?? AppStrings.error,
                                    isError: true,
                                  );
                                  return;
                                }

                                _pendingReviews.removeWhere(
                                  (r) => r.id == resolvedId,
                                );
                              } else {
                                // Backend can't create review yet
                                setSheetState(() => isSubmitting = false);
                                showHelpiSnackBar(
                                  ctx,
                                  AppStrings.reviewNotReady,
                                  isError: true,
                                );
                                return;
                              }

                              // Lokalno ažuriraj UI — direktno na objektu
                              final submittedReview = ReviewModel(
                                rating: selectedRating,
                                comment: commentCtrl.text.trim(),
                                date: DateTime.now(),
                              );
                              job.review = submittedReview;
                              widget.ordersNotifier.addJobReview(
                                order.id,
                                jobIndex,
                                submittedReview,
                              );

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);

                              // Rebuild parent after sheet closes
                              if (mounted) setState(() {});
                            }
                          : null,
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppStrings.sendReview),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
