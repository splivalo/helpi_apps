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
import 'package:helpi_app/shared/widgets/service_chips_wrap.dart';
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

  @override
  void initState() {
    super.initState();
    widget.ordersNotifier.addListener(_onChanged);
    _loadPendingReviews();
    _loadSessions();
  }

  /// Fetch sessions from API and populate order.jobs.
  Future<void> _loadSessions() async {
    final api = AppApiService();
    final result = await api.getSessionsByOrder(widget.order.id);

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

        // Extract student name from scheduleAssignment.student.contact.fullName
        String studentName = '';
        String studentId = '';
        final assignment = json['scheduleAssignment'] as Map<String, dynamic>?;
        if (assignment != null) {
          final student = assignment['student'] as Map<String, dynamic>?;
          if (student != null) {
            studentId = student['userId']?.toString() ?? '';
            final contact = student['contact'] as Map<String, dynamic>?;
            studentName = contact?['fullName'] as String? ?? '';
          }
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

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.ordersNotifier.removeListener(_onChanged);
    super.dispose();
  }

  /// Check if a specific job can be cancelled (time > cutoff).
  bool _canCancelJob(JobModel job) {
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
    final upcoming =
        order.jobs.where((j) => j.status == JobStatus.scheduled).toList()
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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

              // -- Student + Review card (one-time completed) --
              _studentReviewCard(theme, order),
              if (order.isOneTime &&
                  order.status == OrderStatus.completed &&
                  order.jobs.isNotEmpty)
                const SizedBox(height: 16),

              // -- Jobs / sessions (recurring only, not processing) --
              if (order.status != OrderStatus.processing && !order.isOneTime)
                _jobsSection(theme, order),
              if (order.status != OrderStatus.processing && !order.isOneTime)
                const SizedBox(height: 20),

              // -- Action buttons --
              if (_canCancelOrder(order))
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _cancelOrder(order.id);
                  },
                  icon: const Icon(Icons.close, size: 20),
                  label: Text(AppStrings.cancelOrder),
                  style: AppColors.coralOutlinedStyle,
                ),
              if (order.status == OrderStatus.completed)
                OutlinedButton.icon(
                  onPressed: () => _repeatOrder(order),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: Text(AppStrings.repeatOrder),
                ),
            ],
          ),
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

          // Services as chips
          Text(
            AppStrings.orderSummaryServices,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ServiceChipsWrap(labels: order.services),

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
        ],
      ),
    );
  }

  // -- Student + Review card (separate, like student screen's "Senior" card) --
  Widget _studentReviewCard(ThemeData theme, OrderModel order) {
    if (!order.isOneTime ||
        order.status != OrderStatus.completed ||
        order.jobs.isEmpty) {
      return const SizedBox.shrink();
    }

    final job = order.jobs.first;

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
          Text(
            AppStrings.jobStudent,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Student name + Rate button
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  job.studentName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (job.review == null)
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => _showJobReviewSheet(order, 0),
                    icon: const Icon(Icons.star, size: 16, color: Colors.white),
                    label: Text(AppStrings.rateStudent),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      minimumSize: Size.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Review display
          if (job.review != null) ...[
            const SizedBox(height: 12),
            ReviewInlineCard(
              rating: job.review!.rating,
              date: job.review!.date,
              comment: job.review!.comment,
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
                  AppStrings.jobsSection,
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
    final isCompleted = job.status == JobStatus.completed;
    final isCancelled = job.status == JobStatus.cancelled;
    final isUpcoming = job.status == JobStatus.scheduled;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCancelled
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
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
                isCompleted
                    ? Icons.check_circle
                    : isCancelled
                    ? Icons.cancel
                    : Icons.schedule,
                size: 18,
                color: isCompleted
                    ? AppColors.success
                    : isCancelled
                    ? AppColors.coral
                    : AppColors.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppFormatters.dayMediumName(job.weekday)}, ${AppFormatters.date(job.date)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCancelled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              JobStatusBadge(status: job.status),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: time · duration · price
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              '${job.time}  ·  ${job.durationHours}h  ·  ${AppPricing.formatPrice(price)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Row 3: student name with avatar
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.teal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.studentName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Row 4: action buttons
          if (isUpcoming || (isCompleted && job.review == null)) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Row(
                children: [
                  // Rate button (completed only, no review yet)
                  if (isCompleted && job.review == null)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => _showJobReviewSheet(order, jobIndex),
                        icon: const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(AppStrings.rateStudent),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          minimumSize: Size.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                  // Cancel button (upcoming only, outside cutoff)
                  if (isUpcoming && _canCancelJob(job)) ...[
                    const Spacer(),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmCancelJob(order, jobIndex),
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

  /// Review bottom sheet for a specific job.
  void _showJobReviewSheet(OrderModel order, int jobIndex) {
    // Pronađi pending review za ovaj order
    // (ako job ima id, match po jobInstanceId; inače koristi prvi available)
    int? pendingReviewId;
    final job = order.jobs[jobIndex];

    if (job.id != null) {
      // Match by jobInstanceId
      for (final pr in _pendingReviews) {
        if (pr.jobInstanceId == job.id) {
          pendingReviewId = pr.id;
          break;
        }
      }
    }

    // Fallback: koristi prvi pending review ako nema exact match
    if (pendingReviewId == null && _pendingReviews.isNotEmpty) {
      pendingReviewId = _pendingReviews.first.id;
    }

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

                              // Ako imamo pendingReviewId, pošalji na backend
                              if (pendingReviewId != null) {
                                final api = AppApiService();
                                final result = await api.submitReview({
                                  'reviewId': pendingReviewId,
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

                                // Ukloni iz pending liste
                                _pendingReviews.removeWhere(
                                  (r) => r.id == pendingReviewId,
                                );
                              }

                              // Lokalno ažuriraj UI
                              widget.ordersNotifier.addJobReview(
                                order.id,
                                jobIndex,
                                ReviewModel(
                                  rating: selectedRating,
                                  comment: commentCtrl.text.trim(),
                                  date: DateTime.now(),
                                ),
                              );

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
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
