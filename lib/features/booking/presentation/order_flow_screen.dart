import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/constants/pricing.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/utils/formatters.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/shared/widgets/info_card.dart';
import 'package:helpi_app/shared/widgets/selectable_chip.dart';
import 'package:helpi_app/shared/widgets/service_chips_wrap.dart';
import 'package:helpi_app/shared/widgets/summary_row.dart';
import 'package:helpi_app/shared/widgets/tab_bar_selector.dart';
import 'package:helpi_app/shared/widgets/helpi_switch.dart';

// ─── Model za jednu stavku dana s vremenom ──────────────────────
class _DayEntry {
  _DayEntry({required this.day});

  final int day; // 1=Mon … 7=Sun
  int? fromHour; // 8–20
  int? fromMinute; // 0, 15, 30, 45
  int? duration; // 1–4
}

// ─── Booking mode enum ──────────────────────────────────────────
enum _BookingMode { oneTime, recurring }

/// 3-step order flow:
///   1) Kada?       — frekvencija, datum, dani + vrijeme
///   2) Što vam treba?  — usluge (placeholder)
///   3) Pregled         — summary + poruka (placeholder)
class OrderFlowScreen extends StatefulWidget {
  const OrderFlowScreen({super.key, required this.ordersNotifier});

  final OrdersNotifier ordersNotifier;

  @override
  State<OrderFlowScreen> createState() => _OrderFlowScreenState();
}

class _OrderFlowScreenState extends State<OrderFlowScreen> {
  int _currentStep = 0;

  // ── Scroll controller for auto-focus ──────────
  final ScrollController _step1Scroll = ScrollController();

  // ── Step 1 state ──────────────────────────────
  _BookingMode _bookingMode = _BookingMode.oneTime;

  // One-time
  DateTime? _oneTimeDate;
  int? _oneTimeFromHour;
  int? _oneTimeFromMinute;
  int? _oneTimeDuration;

  // Recurring
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasEndDate = false;
  final List<_DayEntry> _dayEntries = [];
  bool _showingDayPicker = false;

  // ── Step 2 state ──────────────────────────────
  final Set<String> _selectedServices = {};
  final TextEditingController _serviceNoteController = TextEditingController();

  // ── Step 3 state ──────────────────────────────
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;

  // Kartice iz API-ja
  List<Map<String, dynamic>> _cards = [];
  int _selectedCardIndex = 0;

  // ── Constants ─────────────────────────────────
  static const _timeHours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
  static const _timeMinutes = [0, 15, 30, 45];
  static const _durations = [1, 2, 3, 4];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final userId = await TokenStorage().getUserId();
    if (userId == null || !mounted) return;

    final result = await AppApiService().getPaymentMethods(userId);
    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() => _cards = result.data!);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _promoCodeController.dispose();
    _serviceNoteController.dispose();
    _step1Scroll.dispose();
    super.dispose();
  }

  // ── Auto-scroll helper ────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_step1Scroll.hasClients) {
        _step1Scroll.animateTo(
          _step1Scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Helpers ───────────────────────────────────
  Set<int> get _usedDays => _dayEntries.map((e) => e.day).toSet();

  List<int> get _availableDays {
    final all = [1, 2, 3, 4, 5, 6, 7].where((d) => !_usedDays.contains(d));
    // When end date is set, only show days that fall within the range
    if (_hasEndDate && _endDate != null && _startDate != null) {
      return all.where((d) => _isDayInRange(d)).toList();
    }
    return all.toList();
  }

  /// Returns true if [weekday] has at least one occurrence between
  /// [_startDate] and [_endDate].
  bool _isDayInRange(int weekday) {
    if (_startDate == null) return true;
    final first = AppFormatters.firstOccurrence(weekday, _startDate!);
    if (!_hasEndDate || _endDate == null) return true;
    return !first.isAfter(_endDate!);
  }

  /// Removes day entries whose weekday no longer falls between
  /// [_startDate] and [_endDate].
  void _removeInvalidDayEntries() {
    if (_startDate == null) return;
    _dayEntries.removeWhere((e) => !_isDayInRange(e.day));
  }

  String _durationLabel(int hours) {
    switch (hours) {
      case 1:
        return AppStrings.hour1;
      case 2:
        return AppStrings.hour2;
      case 3:
        return AppStrings.hour3;
      case 4:
        return AppStrings.hour4;
      default:
        return '$hours h';
    }
  }

  bool get _step1Valid {
    if (_bookingMode == _BookingMode.oneTime) {
      return _oneTimeDate != null &&
          _oneTimeFromHour != null &&
          _oneTimeFromMinute != null &&
          _oneTimeDuration != null;
    }
    if (_startDate == null) return false;
    if (_hasEndDate && _endDate == null) return false;
    if (_dayEntries.isEmpty) return false;
    // Safety: ensure all day entries actually fall within the date range
    if (_hasEndDate && _endDate != null) {
      if (!_dayEntries.every((e) => _isDayInRange(e.day))) return false;
    }
    return _dayEntries.every(
      (e) => e.fromHour != null && e.fromMinute != null && e.duration != null,
    );
  }

  Future<void> _pickOneTimeDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _oneTimeDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('hr'),
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
    );
    if (!context.mounted) return;
    if (picked != null) {
      setState(() => _oneTimeDate = picked);
      _scrollToBottom();
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('hr'),
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
    );
    if (!context.mounted) return;
    if (picked != null) {
      setState(() {
        _endDate = picked;
        // Remove day entries that no longer fit in the date range
        _removeInvalidDayEntries();
      });
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('hr'),
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
    );
    if (!context.mounted) return;
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before start
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
        // Remove day entries that no longer fit in the date range
        _removeInvalidDayEntries();
      });
    }
  }

  // ═════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppStrings.newOrder),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Step indicator bar
            _buildStepIndicator(),

            // Step content
            Expanded(
              child: _currentStep == 0
                  ? _buildStep1(theme)
                  : _currentStep == 1
                  ? _buildStep2(theme)
                  : _buildStep3(theme),
            ),

            // CTA
            _buildCTA(theme),
          ],
        ),
      ),
    );
  }

  // ── Step indicator (3 bars) ───────────────────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.coral : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  STEP 1 — KADA?
  // ═════════════════════════════════════════════════════════════════
  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      controller: _step1Scroll,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppStrings.orderFlowStep1,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),

          // ── Frequency ──
          Text(
            AppStrings.frequency,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _buildFrequencyChips(),
          const SizedBox(height: 24),

          // ── Mode-specific content ──
          if (_bookingMode == _BookingMode.oneTime)
            _buildOneTimeContent(theme)
          else
            _buildRecurringContent(theme),
        ],
      ),
    );
  }

  Widget _buildFrequencyChips() {
    final labels = [AppStrings.oneTime, AppStrings.recurring];
    final modes = [_BookingMode.oneTime, _BookingMode.recurring];
    return TabBarSelector(
      tabs: labels,
      selectedIndex: modes.indexOf(_bookingMode),
      onTap: (i) {
        setState(() {
          _bookingMode = modes[i];
          _showingDayPicker = false;
        });
      },
    );
  }

  // ── One-time: datum + Od + Trajanje ───────────
  Widget _buildOneTimeContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datum
        Text(
          AppStrings.selectDate,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _buildDateButton(date: _oneTimeDate, onTap: _pickOneTimeDate),

        if (_oneTimeDate != null) ...[
          const SizedBox(height: 16),

          // ── Card container (matches recurring day card) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: day name + X to cancel
                Row(
                  children: [
                    Text(
                      AppFormatters.dayFullName(_oneTimeDate!.weekday),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _oneTimeDate = null;
                          _oneTimeFromHour = null;
                          _oneTimeFromMinute = null;
                          _oneTimeDuration = null;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppFormatters.date(_oneTimeDate!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                // Od
                Text(
                  AppStrings.hourLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTimeChips(
                  selectedHour: _oneTimeFromHour,
                  onSelected: (h) {
                    setState(() {
                      _oneTimeFromHour = h;
                      _oneTimeFromMinute = null;
                    });
                    _scrollToBottom();
                  },
                ),

                if (_oneTimeFromHour != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    AppStrings.minuteLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMinuteChips(
                    selectedMinute: _oneTimeFromMinute,
                    onSelected: (m) {
                      setState(() => _oneTimeFromMinute = m);
                      _scrollToBottom();
                    },
                  ),
                ],

                if (_oneTimeFromHour != null && _oneTimeFromMinute != null) ...[
                  const SizedBox(height: 14),

                  // Trajanje
                  Text(
                    AppStrings.durationChoice,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDurationChips(
                    selectedDuration: _oneTimeDuration,
                    onSelected: (d) => setState(() => _oneTimeDuration = d),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Recurring: start date + end date (if untilDate) + day entries + add day ──
  Widget _buildRecurringContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start date — always shown
        Text(
          AppStrings.selectStartDate,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _buildDateButton(date: _startDate, onTap: _pickStartDate),

        // Everything below only after start date is picked
        if (_startDate != null) ...[
          const SizedBox(height: 16),

          // Switch: Do određenog datuma
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.hasEndDate,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              HelpiSwitch(
                value: _hasEndDate,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _hasEndDate = val;
                    if (!val) _endDate = null;
                  });
                },
              ),
            ],
          ),

          // End date — only when switch is ON
          if (_hasEndDate) ...[
            const SizedBox(height: 8),
            _buildDateButton(date: _endDate, onTap: _pickEndDate),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 8),

          // Existing day entries
          ..._dayEntries.asMap().entries.map((mapEntry) {
            return _buildDayCard(theme, mapEntry.value, mapEntry.key);
          }),

          // Day picker — auto-show when no days yet, or after "+" tap
          if ((_dayEntries.isEmpty || _showingDayPicker) &&
              _availableDays.isNotEmpty)
            _buildDayPickerSection(theme),

          // "+ Dodaj dan" button — only when all existing entries are complete
          if (_dayEntries.isNotEmpty &&
              !_showingDayPicker &&
              _availableDays.isNotEmpty &&
              _dayEntries.every(
                (e) =>
                    e.fromHour != null &&
                    e.fromMinute != null &&
                    e.duration != null,
              ))
            _buildAddDayButton(),
        ],
      ],
    );
  }

  // ── Date button ──────────────────────────────
  Widget _buildDateButton({
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: AppColors.teal),
            const SizedBox(width: 12),
            Text(
              date != null ? AppFormatters.date(date) : AppStrings.selectDate,
              style: TextStyle(
                fontSize: 16,
                color: date != null
                    ? AppColors.textPrimary
                    : AppColors.inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Time chips (08:00 – 19:00) ───────────────
  Widget _buildTimeChips({
    required int? selectedHour,
    required ValueChanged<int> onSelected,
  }) {
    // 12 hours → rows of 4: 4+4+4
    const perRow = 4;
    final rows = <List<int>>[
      for (int s = 0; s < _timeHours.length; s += perRow)
        _timeHours.sublist(
          s,
          (s + perRow > _timeHours.length) ? _timeHours.length : s + perRow,
        ),
    ];
    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < rows[r].length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: SelectableChip(
                    label: '${rows[r][i].toString().padLeft(2, '0')}:00',
                    isSelected: selectedHour == rows[r][i],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(rows[r][i]);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // ── Duration chips (1–4 h) ───────────────────
  Widget _buildMinuteChips({
    required int? selectedMinute,
    required ValueChanged<int> onSelected,
  }) {
    return Row(
      children: [
        for (int i = 0; i < _timeMinutes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: SelectableChip(
              label: ':${_timeMinutes[i].toString().padLeft(2, '0')}',
              isSelected: selectedMinute == _timeMinutes[i],
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(_timeMinutes[i]);
              },
            ),
          ),
        ],
      ],
    );
  }

  // ── Duration chips (1–4 h) ───────────────────
  Widget _buildDurationChips({
    required int? selectedDuration,
    required ValueChanged<int> onSelected,
  }) {
    return Row(
      children: [
        for (int i = 0; i < _durations.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: SelectableChip(
              label: _durationLabel(_durations[i]),
              isSelected: selectedDuration == _durations[i],
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(_durations[i]);
              },
            ),
          ),
        ],
      ],
    );
  }

  // ── Day card (one per added day) ─────────────
  Widget _buildDayCard(ThemeData theme, _DayEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: day name + ✕
          Row(
            children: [
              Text(
                AppFormatters.dayFullName(entry.day),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _dayEntries.removeAt(index));
                },
                child: const Icon(
                  Icons.close,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Info: first service date
          if (_startDate != null) ...[
            const SizedBox(height: 6),
            Text(
              AppStrings.firstServiceDate(
                AppFormatters.date(
                  AppFormatters.firstOccurrence(entry.day, _startDate!),
                ),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Od
          Text(
            AppStrings.hourLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildTimeChips(
            selectedHour: entry.fromHour,
            onSelected: (h) {
              setState(() {
                entry.fromHour = h;
                entry.fromMinute = null;
              });
              _scrollToBottom();
            },
          ),

          if (entry.fromHour != null) ...[
            const SizedBox(height: 14),
            Text(
              AppStrings.minuteLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildMinuteChips(
              selectedMinute: entry.fromMinute,
              onSelected: (m) {
                setState(() => entry.fromMinute = m);
                _scrollToBottom();
              },
            ),
          ],

          if (entry.fromHour != null && entry.fromMinute != null) ...[
            const SizedBox(height: 14),

            // Trajanje
            Text(
              AppStrings.durationChoice,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildDurationChips(
              selectedDuration: entry.duration,
              onSelected: (d) {
                setState(() => entry.duration = d);
                _scrollToBottom();
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Day picker (shown after "+" tap) ─────────
  Widget _buildDayPickerSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.selectDay,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_dayEntries.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showingDayPicker = false);
                  },
                  child: const Icon(
                    Icons.close,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < _availableDays.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: SelectableChip(
                    label: AppFormatters.dayShortName(_availableDays[i]),
                    isSelected: false,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _dayEntries.add(_DayEntry(day: _availableDays[i]));
                        _showingDayPicker = false;
                      });
                      // Auto-scroll to show the new card
                      _scrollToBottom();
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── "+ Dodaj dan" button ──────────────────────
  Widget _buildAddDayButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showingDayPicker = true);
        // Auto-scroll to show the day picker
        _scrollToBottom();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.teal, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: AppColors.teal,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.addDay,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  STEP 2 — ŠTO VAM TREBA?
  // ═════════════════════════════════════════════════════════════════

  // Service chip definitions: key → label getter
  static final _serviceChips = <String, String Function()>{
    'shopping': () => AppStrings.bookingChipShopping,
    'house_help': () => AppStrings.bookingChipCleaning,
    'companionship': () => AppStrings.bookingChipCompanionship,
    'walking': () => AppStrings.bookingChipWalk,
    'escort': () => AppStrings.bookingChipEscort,
    'other': () => AppStrings.bookingChipOther,
  };

  Widget _buildStep2(ThemeData theme) {
    final entries = _serviceChips.entries.toList();
    // 2 per row → 4 rows (7 items + 1 empty slot)
    const perRow = 2;
    final rows = <List<MapEntry<String, String Function()>>>[];
    for (var i = 0; i < entries.length; i += perRow) {
      rows.add(
        entries.sublist(
          i,
          (i + perRow > entries.length) ? entries.length : i + perRow,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.orderFlowStep2,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),

          // Service chips — 2 per row, edge-to-edge
          for (int r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 0; i < rows[r].length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: SelectableChip(
                      label: rows[r][i].value(),
                      isSelected: _selectedServices.contains(rows[r][i].key),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          final key = rows[r][i].key;
                          if (_selectedServices.contains(key)) {
                            _selectedServices.remove(key);
                          } else {
                            _selectedServices.add(key);
                          }
                        });
                      },
                    ),
                  ),
                ],
                // Pad odd row
                if (rows[r].length < perRow)
                  for (int p = 0; p < perRow - rows[r].length; p++) ...[
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ── Escort info card (shown when Pratnja is selected) ──
          if (_selectedServices.contains('escort')) ...[
            InfoCard(text: AppStrings.escortInfo),
            const SizedBox(height: 24),
          ],

          // Text field for additional description
          TextField(
            controller: _serviceNoteController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: AppStrings.serviceNoteHint,
              hintMaxLines: 3,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  STEP 3 — PREGLED
  // ═════════════════════════════════════════════════════════════════
  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.orderFlowStep3,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),

          // ── Summary card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Frequency
                SummaryRow(
                  label: AppStrings.orderSummaryFrequency,
                  value: _bookingModeLabel(),
                ),
                const Divider(height: 24),

                // Date / Start+End
                if (_bookingMode == _BookingMode.oneTime) ...[
                  SummaryRow(
                    label: AppStrings.orderSummaryDate,
                    value: _oneTimeDate != null
                        ? AppFormatters.date(_oneTimeDate!)
                        : '-',
                  ),
                  const Divider(height: 24),
                  SummaryRow(
                    label: AppStrings.orderSummaryTime,
                    value: _oneTimeFromHour != null
                        ? '${_oneTimeFromHour.toString().padLeft(2, '0')}:${(_oneTimeFromMinute ?? 0).toString().padLeft(2, '0')}'
                        : '-',
                  ),
                  const Divider(height: 24),
                  SummaryRow(
                    label: AppStrings.orderSummaryDuration,
                    value: _oneTimeDuration != null
                        ? _durationLabel(_oneTimeDuration!)
                        : '-',
                  ),
                  if (_oneTimeDate != null && _oneTimeDuration != null) ...[
                    const Divider(height: 24),
                    SummaryRow(
                      label: AppStrings.orderSummaryPrice,
                      value: AppPricing.formatPrice(
                        AppPricing.priceForDay(
                          _oneTimeDate!.weekday,
                          _oneTimeDuration!,
                        ),
                      ),
                      bold: true,
                    ),
                  ],
                ] else ...[
                  SummaryRow(
                    label: AppStrings.orderSummaryStartDate,
                    value: _startDate != null && _dayEntries.isNotEmpty
                        ? () {
                            DateTime? earliest;
                            for (final entry in _dayEntries) {
                              final occ = AppFormatters.firstOccurrence(
                                entry.day,
                                _startDate!,
                              );
                              if (earliest == null || occ.isBefore(earliest)) {
                                earliest = occ;
                              }
                            }
                            return AppFormatters.date(earliest!);
                          }()
                        : _startDate != null
                        ? AppFormatters.date(_startDate!)
                        : '-',
                  ),
                  if (_hasEndDate && _endDate != null) ...[
                    const Divider(height: 24),
                    SummaryRow(
                      label: AppStrings.orderSummaryEndDate,
                      value: _endDate != null
                          ? AppFormatters.date(_endDate!)
                          : '-',
                    ),
                  ],
                  const Divider(height: 24),

                  // Days
                  Text(
                    AppStrings.orderSummaryDays,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._dayEntries.map((entry) {
                    final timeStr = entry.fromHour != null
                        ? '${entry.fromHour.toString().padLeft(2, '0')}:${(entry.fromMinute ?? 0).toString().padLeft(2, '0')}'
                        : '-';
                    final durStr = entry.duration != null
                        ? '${entry.duration}h'
                        : '-';
                    final priceStr = entry.duration != null
                        ? AppPricing.formatPrice(
                            AppPricing.priceForDay(entry.day, entry.duration!),
                          )
                        : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            AppFormatters.dayMediumName(entry.day),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$timeStr  ·  $durStr  ·  $priceStr',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }),
                  // Weekly total
                  if (_dayEntries.every((e) => e.duration != null)) ...[
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
                            _dayEntries.fold<int>(
                              0,
                              (sum, e) =>
                                  sum +
                                  AppPricing.priceForDay(e.day, e.duration!),
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

                // Services
                Text(
                  AppStrings.orderSummaryServices,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ServiceChipsWrap(
                  labels: _selectedServices.map((key) {
                    return _serviceChips[key]?.call() ?? key;
                  }).toList(),
                ),

                // Service note
                if (_serviceNoteController.text.trim().isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    AppStrings.orderSummaryNotes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _serviceNoteController.text.trim(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Payment method section ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.paymentMethod,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ..._cards.asMap().entries.map((entry) {
                  final i = entry.key;
                  final card = entry.value;
                  final isSelected = _selectedCardIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCardIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.selectedChipBg
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.teal : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.credit_card,
                            color: isSelected
                                ? AppColors.teal
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${card['brand']}  ••••  ${card['last4']}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.teal,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    // Prototype — would open dedicated PaymentMethodScreen
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.teal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.addCard,
                        style: TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Promo code ──
                const Divider(height: 24),
                Text(
                  AppStrings.promoCode,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_appliedPromoCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _appliedPromoCode!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _appliedPromoCode = null;
                              _promoCodeController.clear();
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoCodeController,
                          decoration: InputDecoration(
                            hintText: AppStrings.promoCodeHint,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.teal,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final code = _promoCodeController.text.trim();
                          if (code.isNotEmpty) {
                            setState(() => _appliedPromoCode = code);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        child: Text(AppStrings.promoCodeApply),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── General overtime disclaimer ──
          InfoCard(text: AppStrings.overtimeDisclaimer),
        ],
      ),
    );
  }

  // ── Submit order ─────────────────────────────────
  void _submitOrder() {
    final bool isOneTime = _bookingMode == _BookingMode.oneTime;

    DateTime date;
    String time = '';
    String duration = '';
    DateTime? endDate;
    List<OrderDayEntry> dayEntries = [];

    if (isOneTime) {
      date = _oneTimeDate ?? DateTime.now();
      time = _oneTimeFromHour != null
          ? '${_oneTimeFromHour.toString().padLeft(2, '0')}:${(_oneTimeFromMinute ?? 0).toString().padLeft(2, '0')}'
          : '-';
      duration = _oneTimeDuration != null
          ? _durationLabel(_oneTimeDuration!)
          : '-';
    } else {
      // First occurrence date
      if (_startDate != null && _dayEntries.isNotEmpty) {
        // Find the earliest first occurrence across all days
        DateTime? earliest;
        for (final entry in _dayEntries) {
          final occ = AppFormatters.firstOccurrence(entry.day, _startDate!);
          if (earliest == null || occ.isBefore(earliest)) {
            earliest = occ;
          }
        }
        date = earliest!;
      } else {
        date = _startDate ?? DateTime.now();
      }

      if (_hasEndDate && _endDate != null) {
        endDate = _endDate;
      }

      // Build structured day entries
      dayEntries = _dayEntries.map((entry) {
        final timeStr = entry.fromHour != null
            ? '${entry.fromHour.toString().padLeft(2, '0')}:${(entry.fromMinute ?? 0).toString().padLeft(2, '0')}'
            : '-';
        final durStr = entry.duration != null
            ? _durationLabel(entry.duration!)
            : '-';
        return OrderDayEntry(
          dayName: AppFormatters.dayFullName(entry.day),
          time: timeStr,
          duration: durStr,
          weekday: entry.day,
          durationHours: entry.duration ?? 0,
        );
      }).toList();
    }

    final order = OrderModel(
      id: widget.ordersNotifier.nextId,
      services: _selectedServices
          .map((key) => _serviceChips[key]?.call() ?? key)
          .toList(),
      date: date,
      frequency: _bookingModeLabel(),
      notes: _notesController.text.trim(),
      serviceNote: _serviceNoteController.text.trim(),
      promoCode: _appliedPromoCode ?? '',
      paymentMethodId: _cards.isNotEmpty
          ? (_cards[_selectedCardIndex]['id']?.toString() ?? '')
          : '',
      isOneTime: isOneTime,
      time: time,
      duration: duration,
      dayEntries: dayEntries,
      endDate: endDate,
      weekday: isOneTime ? (_oneTimeDate?.weekday ?? 1) : 1,
      durationHours: isOneTime ? (_oneTimeDuration ?? 0) : 0,
    );

    widget.ordersNotifier.addOrder(order);
  }

  String _bookingModeLabel() {
    switch (_bookingMode) {
      case _BookingMode.oneTime:
        return AppStrings.oneTime;
      case _BookingMode.recurring:
        if (_hasEndDate && _endDate != null) {
          return AppStrings.recurringWithEnd(AppFormatters.date(_endDate!));
        }
        return AppStrings.recurringNoEnd;
    }
  }

  // ═════════════════════════════════════════════════════════════════
  //  CTA BUTTON
  // ═════════════════════════════════════════════════════════════════
  Widget _buildCTA(ThemeData theme) {
    final bool isEnabled;
    if (_currentStep == 0) {
      isEnabled = _step1Valid;
    } else if (_currentStep == 1) {
      isEnabled = _selectedServices.isNotEmpty;
    } else {
      isEnabled = true;
    }
    final label = _currentStep < 2 ? AppStrings.next : AppStrings.placeOrder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  // Final submit — create order and go back
                  _submitOrder();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              }
            : null,
        child: Text(label),
      ),
    );
  }
}
