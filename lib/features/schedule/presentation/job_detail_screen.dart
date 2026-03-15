import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/data/review_model.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/utils/job_helpers.dart';
import 'package:helpi_app/core/utils/snackbar_helper.dart';
import 'package:helpi_app/features/schedule/widgets/job_status_badge.dart';
import 'package:helpi_app/features/schedule/widgets/star_rating.dart';

/// Detalji jednog posla — prikazuje sve info + sekcija za ocjenu seniora.
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

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  void _showReviewSheet() {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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

  void _onReviewSubmitted(ReviewModel review) {
    if (!context.mounted) return;
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
    setState(() => _job = updatedJob);
    widget.onJobUpdated(updatedJob);

    showHelpiSnackBar(context, AppStrings.reviewSent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.jobDetailTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ CARD 1: Detalji posla (isti layout kao _JobCard) ═══
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HelpiTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Datum + status chip ──
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
                        JobStatusBadge(status: _job.status),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Vrijeme ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 20,
                          color: HelpiTheme.textSecondary,
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
                            _job.address,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Usluge (ikona + chipovi) ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.work_outline,
                          size: 20,
                          color: HelpiTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _job.serviceTypes.map((type) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: HelpiTheme.barBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  JobHelpers.serviceLabel(type),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: HelpiTheme.textSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Napomene ──
                  if (_job.notes != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_outlined,
                            size: 20,
                            color: HelpiTheme.textSecondary,
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

            // ═══ CARD 2: Korisnik (Senior) + Review ═══
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HelpiTheme.border),
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

                  // ── Ime seniora + Ocijeni gumb ──
                  Row(
                    children: [
                      // Circle avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: HelpiTheme.avatarBg,
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Ocijeni gumb — samo za completed bez reviewova
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
                              backgroundColor: HelpiTheme.coral,
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

                  // ── Prikaz recenzije (ako postoji) ──
                  if (_job.review != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.yourReview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: HelpiTheme.offWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StarRating(rating: _job.review!.rating, size: 16),
                              const Spacer(),
                              Text(
                                _job.review!.date,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (_job.review!.comment.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _job.review!.comment,
                                style: theme.textTheme.bodySmall,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Ne mogu gumb (za assigned, >24h) ──
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
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDeclineFromDetail() async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.jobDeclineTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: AppStrings.jobDeclineHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(AppStrings.jobDeclineConfirm),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppStrings.cancel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;

    if (confirmed == true) {
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
    }
  }
}
