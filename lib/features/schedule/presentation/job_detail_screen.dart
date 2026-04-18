import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/data/review_model.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/utils/job_helpers.dart';
import 'package:helpi_app/core/utils/snackbar_helper.dart';
import 'package:helpi_app/features/schedule/widgets/job_status_badge.dart';
import 'package:helpi_app/features/schedule/widgets/star_rating.dart';
import 'package:helpi_app/shared/widgets/review_inline_card.dart';
import 'package:helpi_app/shared/widgets/sponsor_banner.dart';

/// Job details - displays all info + section for rating senior.
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.job,
    required this.onJobUpdated,
  });

  final Job job;
  final ValueChanged<Job> onJobUpdated;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Job _job;
  int? _pendingReviewId;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _loadPendingReviewId();
  }

  /// Učitaj pending review ID za ovaj job.
  Future<void> _loadPendingReviewId() async {
    if (_job.sessionId == null) return;

    final sessionIdInt = int.tryParse(_job.sessionId!);
    if (sessionIdInt == null) return;

    final userId = await TokenStorage().getUserId();
    if (userId == null || !mounted) return;

    final api = AppApiService();
    final result = await api.getPendingReviewsByStudent(userId);

    if (!mounted) return;

    if (result.success && result.data != null) {
      // Find review for this job instance
      for (final review in result.data!) {
        if (review.jobInstanceId == sessionIdInt) {
          setState(() => _pendingReviewId = review.id);
          break;
        }
      }
    }
  }

  void _showReviewSheet() {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppStrings.rateSenior}: ${_job.seniorName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    StarRating(
                      rating: selectedRating,
                      size: 40,
                      onTap: (rating) {
                        HapticFeedback.selectionClick();
                        setSheetState(() => selectedRating = rating);
                      },
                    ),
                    const SizedBox(height: 20),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedRating > 0
                            ? () {
                                final dateStr = Formatters.formatDateFull(
                                  DateTime.now(),
                                );
                                final review = ReviewModel(
                                  rating: selectedRating,
                                  comment: commentCtrl.text.trim(),
                                  date: dateStr,
                                );
                                Navigator.pop(ctx);
                                _onReviewSubmitted(review);
                              }
                            : null,
                        child: Text(AppStrings.sendReview),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onReviewSubmitted(ReviewModel review) async {
    if (!context.mounted) return;

    // Bulletproof: resolve pending review ID
    int? reviewId = _pendingReviewId;

    if (reviewId == null && _job.sessionId != null) {
      final sessionIdInt = int.tryParse(_job.sessionId!);
      if (sessionIdInt != null) {
        // Re-fetch pending reviews (Hangfire may have run)
        await _loadPendingReviewId();
        reviewId = _pendingReviewId;

        if (reviewId == null && mounted) {
          // Trigger ensure-completed on backend
          final api = AppApiService();
          final ensureResult = await api.ensureSessionCompleted(sessionIdInt);
          if (!mounted) return;
          if (ensureResult.success) {
            await _loadPendingReviewId();
            reviewId = _pendingReviewId;
          }
        }
      }
    }

    if (!mounted) return;

    if (reviewId != null) {
      final api = AppApiService();
      final result = await api.submitReview({
        'reviewId': reviewId,
        'rating': review.rating.toDouble(),
        'comment': review.comment,
      });

      if (!mounted) return;

      if (!result.success) {
        showHelpiSnackBar(
          context,
          result.error ?? AppStrings.error,
          isError: true,
        );
        return;
      }
    } else {
      showHelpiSnackBar(context, AppStrings.reviewNotReady, isError: true);
      return;
    }

    // Locally update display
    final updatedJob = Job(
      id: _job.id,
      date: _job.date,
      from: _job.from,
      to: _job.to,
      serviceTypes: _job.serviceTypes,
      seniorName: _job.seniorName,
      address: _job.address,
      status: _job.status,
      notes: _job.notes,
      review: review,
    );
    setState(() {
      _job = updatedJob;
      _pendingReviewId = null; // Reset - review submitted
    });
    widget.onJobUpdated(updatedJob);

    showHelpiSnackBar(context, AppStrings.reviewSent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.jobDetailTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══ CARD 1: Detalji posla (isti layout kao _JobCard) ═══
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -- Date + status chip --
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: teal,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Formatters.formatDateFull(_job.date),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              JobStatusBadge(
                                status: _job.status,
                                date: _job.date,
                                from: _job.from,
                                to: _job.to,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // -- Time --
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${Formatters.formatTime(_job.from)} – ${Formatters.formatTime(_job.to)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

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
                                  _job.address,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // -- Services (icon + chips) --
                        if (_job.serviceTypes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _job.serviceTypes
                                        .map(JobHelpers.serviceLabel)
                                        .join(', '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // -- Notes --
                        if (_job.notes != null &&
                            _job.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.notes_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _job.notes!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ═══ CARD 2: User (Senior) + Review ═══
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.jobSenior,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // -- Senior name + Rate button --
                        Row(
                          children: [
                            // Circle avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: teal.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: teal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _job.seniorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Rate button - only for completed without reviews
                            if (_job.status == JobStatus.completed &&
                                _job.review == null)
                              SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: _showReviewSheet,
                                  icon: const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(AppStrings.rateSenior),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.coral,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
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

                        // -- Review display (if exists) --
                        if (_job.review != null) ...[
                          const SizedBox(height: 12),
                          ReviewInlineCard(
                            rating: _job.review!.rating,
                            date:
                                DateTime.tryParse(_job.review!.date) ??
                                DateTime.now(),
                            comment: _job.review!.comment,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // -- Can't attend button (for assigned, >cutoff hours) --
                  if (_job.canDecline) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeclineFromDetail(),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(AppStrings.jobDecline),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HelpiTheme.coral,
                          side: const BorderSide(color: HelpiTheme.coral),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ] else if (_job.status == JobStatus.scheduled) ...[
                    const SizedBox.shrink(),
                  ],
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 32, top: 8),
            child: SponsorBanner(),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeclineFromDetail() async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.cancelJobLabel),
        content: Text(AppStrings.cancelJobConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.confirm),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirmed != true) return;

    final api = AppApiService();
    final result = await api.cancelSession(int.parse(_job.id));

    if (!context.mounted) return;

    if (result.success) {
      final updatedJob = Job(
        id: _job.id,
        orderId: _job.orderId,
        sessionId: _job.sessionId,
        studentId: _job.studentId,
        seniorId: _job.seniorId,
        date: _job.date,
        from: _job.from,
        to: _job.to,
        serviceTypes: _job.serviceTypes,
        seniorName: _job.seniorName,
        address: _job.address,
        status: JobStatus.cancelled,
        notes: _job.notes,
      );
      setState(() => _job = updatedJob);
      widget.onJobUpdated(updatedJob);

      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.jobDeclineSuccess),
          backgroundColor: HelpiTheme.teal,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Error'),
          backgroundColor: HelpiTheme.coral,
        ),
      );
    }
  }
}
