import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/providers/realtime_sync_provider.dart';
import 'package:helpi_app/shared/widgets/helpi_empty_state.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/utils/formatters.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/features/booking/presentation/order_detail_screen.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/presentation/job_detail_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _api = AppApiService();
  final _storage = TokenStorage();

  bool _isLoading = true;
  String? _loadError;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsUnreadProvider.notifier).state = 0;
    });
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = await _storage.getUserId();
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = AppStrings.notificationsLoadError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final result = await _api.getNotificationsByUser(userId);
    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _isLoading = false;
        _loadError = result.error ?? AppStrings.notificationsLoadError;
      });
      return;
    }

    final all = result.data ?? [];
    setState(() {
      _isLoading = false;
      _notifications = all;
      _unreadCount = all.where((n) => n['isRead'] != true).length;
    });
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    final id = (notification['id'] as num?)?.toInt();
    final isRead = notification['isRead'] as bool? ?? false;
    if (id == null || isRead) return;

    setState(() {
      _notifications = _notifications.map((item) {
        if (item['id'] == id) return {...item, 'isRead': true};
        return item;
      }).toList();
      _unreadCount = _notifications.where((n) => n['isRead'] != true).length;
    });

    final result = await _api.markNotificationAsRead(id);
    if (!mounted) return;
    if (!result.success) {
      // Revert on failure
      setState(() {
        _notifications = _notifications.map((item) {
          if (item['id'] == id) return {...item, 'isRead': false};
          return item;
        }).toList();
        _unreadCount = _notifications.where((n) => n['isRead'] != true).length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? AppStrings.notificationsLoadError),
        ),
      );
    }
  }

  // -- Types that warrant navigation (have a destination screen) --
  static const _seniorNavigableTypes = {1, 2, 7, 8, 9, 12, 21, 22, 23, 32};
  static const _studentNavigableTypes = {
    5,
    7,
    8,
    9,
    21,
    22,
    23,
    33,
    34,
    35,
    36,
  };

  Future<void> _onNotificationTap(Map<String, dynamic> notification) async {
    await _markAsRead(notification);

    final type = (notification['type'] as num?)?.toInt();
    final userType = await _storage.getUserType();
    if (!mounted) return;

    if ((userType?.toLowerCase() == 'customer' ||
            userType?.toLowerCase() == 'senior') &&
        _seniorNavigableTypes.contains(type)) {
      final orderId =
          (notification['orderId'] as num?)?.toInt() ??
          (notification['OrderId'] as num?)?.toInt();
      if (orderId == null) return;

      final result = await _api.getOrderById(orderId);
      if (!mounted) return;
      if (!result.success || result.data == null) return;

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(
            order: result.data!,
            ordersNotifier: OrdersNotifier(),
          ),
        ),
      );
    } else if (userType?.toLowerCase() == 'student' &&
        _studentNavigableTypes.contains(type)) {
      final jobInstanceId =
          (notification['jobInstanceId'] as num?)?.toInt() ??
          (notification['JobInstanceId'] as num?)?.toInt();
      if (jobInstanceId == null) return;

      // Try cache first, fall back to API
      var job = JobsCache.all
          .where((j) => j.sessionId == jobInstanceId.toString())
          .firstOrNull;

      if (job == null) {
        final userId = await _storage.getUserId();
        if (!mounted || userId == null) return;
        final apiResult = await _api.getSessionsByStudent(userId);
        if (!mounted) return;
        if (apiResult.success && apiResult.data != null) {
          job = apiResult.data!
              .where((j) => j.sessionId == jobInstanceId.toString())
              .firstOrNull;
        }
      }

      if (!mounted || job == null) return;

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => JobDetailScreen(job: job!, onJobUpdated: (_) {}),
        ),
      );
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final id = (notification['id'] as num?)?.toInt();
    if (id == null) return;

    final wasUnread = notification['isRead'] != true;

    setState(() {
      _notifications = _notifications.where((n) => n['id'] != id).toList();
      if (wasUnread) {
        _unreadCount = _notifications.where((n) => n['isRead'] != true).length;
      }
    });

    final result = await _api.deleteNotification(id);
    if (!mounted) return;
    if (!result.success) {
      // Reinsert on failure
      setState(() {
        _notifications = [notification, ..._notifications];
        _unreadCount = _notifications.where((n) => n['isRead'] != true).length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? AppStrings.notificationsDeleteError),
        ),
      );
    }
  }

  String _formatCreatedAt(Map<String, dynamic> notification) {
    final raw = notification['createdAt'] as String?;
    if (raw == null) return '';
    final createdAt = DateTime.tryParse(raw)?.toLocal();
    if (createdAt == null) return '';
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '${AppFormatters.date(createdAt)} \u2022 $hour:$minute';
  }

  IconData _iconForType(int? type) {
    switch (type) {
      // Payment
      case 1:
      case 2:
        return Icons.payments_outlined;
      // Job reminders & status
      case 5:
        return Icons.alarm_outlined;
      case 7:
        return Icons.check_circle_outline;
      case 8:
      case 12:
      case 35:
        return Icons.cancel_outlined;
      case 36:
        return Icons.remove_circle_outline;
      // Reschedule / reassignment
      case 9:
      case 22:
        return Icons.event_repeat_outlined;
      case 23:
        return Icons.event_available_outlined;
      // Contract
      case 13:
        return Icons.warning_amber_outlined;
      case 14:
        return Icons.event_busy_outlined;
      case 15:
      case 16:
        return Icons.description_outlined;
      // Review
      case 21:
        return Icons.star_outline;
      // Assignment (student)
      case 33:
        return Icons.pending_actions_outlined;
      case 34:
        return Icons.how_to_reg_outlined;
      // Order back to processing
      case 32:
        return Icons.hourglass_top_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColorForType(int? type, ThemeData theme) {
    switch (type) {
      // Teal = good / success
      case 1:
      case 7:
      case 15:
      case 23:
      case 34:
        return AppColors.teal;
      // Coral = error / cancelled / bad
      case 2:
      case 8:
      case 12:
      case 14:
      case 35:
      case 36:
        return AppColors.coral;
      // Amber = warning / pending / attention
      case 5:
      case 13:
      case 21:
      case 32:
      case 33:
        return Colors.amber.shade700;
      // Primary = info / neutral action
      case 9:
      case 16:
      case 22:
        return theme.colorScheme.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _unreadCount > 0
        ? '${AppStrings.notificationsTitle} ($_unreadCount)'
        : AppStrings.notificationsTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 72,
                color: theme.colorScheme.error.withAlpha(180),
              ),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadNotifications,
                child: Text(AppStrings.notificationsTryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: HelpiEmptyState(
          icon: Icons.notifications_none_outlined,
          title: AppStrings.notificationsEmpty,
          subtitle: AppStrings.notificationsEmptySubtitle,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final id = (notification['id'] as num?)?.toInt() ?? index;
          return Dismissible(
            key: ValueKey(id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: AppColors.coral,
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) => _deleteNotification(notification),
            child: _buildNotificationCard(Theme.of(context), notification),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    ThemeData theme,
    Map<String, dynamic> notification,
  ) {
    final type = (notification['type'] as num?)?.toInt();
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? false;

    return InkWell(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isRead ? Colors.transparent : AppColors.teal,
              width: 4,
            ),
          ),
          color: isRead ? Colors.transparent : theme.colorScheme.surface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _iconColorForType(type, theme).withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForType(type),
                color: _iconColorForType(type, theme),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCreatedAt(notification),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
