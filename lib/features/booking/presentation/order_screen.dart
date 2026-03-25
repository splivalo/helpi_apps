import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/features/booking/presentation/order_flow_screen.dart';

/// Order screen - simple view with button for new order.
class OrderScreen extends StatelessWidget {
  const OrderScreen({
    super.key,
    required this.ordersNotifier,
    this.onOrderCreated,
  });

  final OrdersNotifier ordersNotifier;
  final VoidCallback? onOrderCreated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.orderTitle)),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/images/illustration.svg', width: 220),
                const SizedBox(height: 32),
                Text(
                  AppStrings.orderSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) =>
                              OrderFlowScreen(ordersNotifier: ordersNotifier),
                        ),
                      );
                      if (created == true) {
                        onOrderCreated?.call();
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: Text(AppStrings.newOrder),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
