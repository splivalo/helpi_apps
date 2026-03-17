import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/features/schedule/utils/availability_helpers.dart';
import 'package:helpi_app/features/schedule/widgets/availability_day_row.dart';

/// Onboarding — student mora postaviti dostupnost prije korištenja app-a.
/// Gumb "Završi" je disabled dok nema barem 1 dan s postavljenim vremenom.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.availabilityNotifier,
    required this.onComplete,
    this.onBack,
  });

  final AvailabilityNotifier availabilityNotifier;
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<DayAvailability> get _days => widget.availabilityNotifier.value;

  bool get _canFinish => _days.any((d) => d.enabled);

  Future<void> _pickTime({
    required DayAvailability day,
    required bool isFrom,
  }) async {
    final changed = await pickAvailabilityTime(
      context: context,
      day: day,
      isFrom: isFrom,
    );
    if (changed) {
      setState(() {});
      widget.availabilityNotifier.notify();
    }
  }

  bool _isSaving = false;

  /// Spremi dostupnost na backend i završi onboarding.
  Future<void> _saveAndComplete() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final userId = await TokenStorage().getUserId();
    if (userId == null || !mounted) {
      setState(() => _isSaving = false);
      return;
    }

    final api = AppApiService();
    final payload = widget.availabilityNotifier.toBackendPayload(userId);
    final result = await api.updateStudentAvailability(payload);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result.success) {
      widget.onComplete();
    } else {
      // Prikaži grešku ali ipak dozvoli nastavak
      debugPrint('[Onboarding] save failed: ${result.error}');
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: HelpiTheme.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Back arrow ──
              if (widget.onBack != null)
                GestureDetector(
                  onTap: widget.onBack,
                  child: const Icon(Icons.arrow_back, size: 28),
                ),
              const SizedBox(height: 24),

              // ── Title ──
              Text(
                AppStrings.onboardingTitle,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.onboardingSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: HelpiTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // ── Day list ──
              Expanded(
                child: ListView.builder(
                  itemCount: _days.length,
                  itemBuilder: (context, index) => _buildDayRow(_days[index]),
                ),
              ),

              // ── CTA button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_canFinish && !_isSaving)
                      ? _saveAndComplete
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HelpiTheme.coral,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: HelpiTheme.border,
                    disabledForegroundColor: const Color(0xFF9E9E9E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(AppStrings.onboardingFinish),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayRow(DayAvailability day) {
    return AvailabilityDayRow(
      day: day,
      onEnabledChanged: (v) {
        setState(() => day.enabled = v);
        widget.availabilityNotifier.notify();
      },
      onPickFrom: () => _pickTime(day: day, isFrom: true),
      onPickTo: () => _pickTime(day: day, isFrom: false),
    );
  }
}
