import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/utils/formatters.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/features/booking/presentation/order_detail_screen.dart';
import 'package:helpi_app/shared/widgets/status_chip.dart';
import 'package:helpi_app/shared/widgets/summary_row.dart';
import 'package:helpi_app/shared/widgets/tab_bar_selector.dart';

/// Ekran s listom narudžbi — 3 taba: U obradi, Aktivne, Završene.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.ordersNotifier});

  final OrdersNotifier ordersNotifier;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    widget.ordersNotifier.addListener(_onOrdersChanged);
  }

  void _onOrdersChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.ordersNotifier.removeListener(_onOrdersChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.ordersNotifier;

    final tabs = [
      AppStrings.ordersProcessing,
      AppStrings.ordersActive,
      AppStrings.ordersCompleted,
      AppStrings.ordersCancelled,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.myOrders)),
      body: Column(
        children: [
          // ── Custom tab bar (coral underline, no black line) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBarSelector(
              tabs: tabs,
              selectedIndex: _selectedTab,
              onTap: (i) => setState(() => _selectedTab = i),
            ),
          ),

          // ── Tab content ──
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildList(notifier.processing, _ActionType.cancel),
                _buildList(notifier.active, _ActionType.cancel),
                _buildList(notifier.completed, _ActionType.repeat),
                _buildList(notifier.cancelled, _ActionType.none),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────
  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 80,
              color: theme.colorScheme.secondary.withAlpha(100),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noOrdersInCategory,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Order list ──────────────────────────────────
  Widget _buildList(List<OrderModel> orders, _ActionType actionType) {
    final theme = Theme.of(context);

    if (orders.isEmpty) return _buildEmpty(theme);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(theme, order);
      },
    );
  }

  // ── Compact order card — tap to open detail ──
  Widget _buildOrderCard(ThemeData theme, OrderModel order) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              order: order,
              ordersNotifier: widget.ordersNotifier,
            ),
          ),
        );
        if (!mounted) return;
        if (result == 'repeated') {
          setState(() => _selectedTab = 0);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.orderNumber(order.id.toString()),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusChip(status: order.status),
              ],
            ),
            const Divider(height: 24),

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

            // Tap hint
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.showMore,
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: theme.colorScheme.secondary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ActionType { cancel, repeat, none }
