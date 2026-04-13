import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/shared/widgets/helpi_empty_state.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/utils/formatters.dart';
import 'package:helpi_app/shared/widgets/tab_bar_selector.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = AppApiService();
  final _storage = TokenStorage();

  int _selectedTab = 0;
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _loadError;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _unreadNotifications = [];

  @override
  void initState() {
    super.initState();
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

    final unreadResult = await _api.getUnreadNotificationsByUser(userId);
    if (!mounted) return;

    final allResult = await _api.getNotificationsByUser(userId);
    if (!mounted) return;

    if (!unreadResult.success || !allResult.success) {
      setState(() {
        _isLoading = false;
        _loadError =
            unreadResult.error ??
            allResult.error ??
            AppStrings.notificationsLoadError;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _unreadNotifications = unreadResult.data ?? [];
      _allNotifications = allResult.data ?? [];
      _unreadCount = _unreadNotifications.length;
    });
  }

  Future<void> _markAllAsRead() async {
    final userId = await _storage.getUserId();
    if (userId == null) {
      return;
    }

    setState(() => _isMarkingAll = true);
    final result = await _api.markAllNotificationsAsRead(userId);
    if (!mounted) return;

    setState(() => _isMarkingAll = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? AppStrings.notificationsLoadError),
        ),
      );
      return;
    }

    await _loadNotifications();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.notificationsMarkedAllRead)),
    );
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    final id = (notification['id'] as num?)?.toInt();
    final isRead = notification['isRead'] as bool? ?? false;
    if (id == null || isRead) {
      return;
    }

    final result = await _api.markNotificationAsRead(id);
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? AppStrings.notificationsLoadError),
        ),
      );
      return;
    }

    setState(() {
      _allNotifications = _allNotifications.map((item) {
        if (item['id'] == id) {
          return {...item, 'isRead': true};
        }
        return item;
      }).toList();
      _unreadNotifications = _unreadNotifications
          .where((item) => item['id'] != id)
          .toList();
      _unreadCount = _unreadNotifications.length;
    });
  }

  List<Map<String, dynamic>> get _visibleNotifications {
    return _selectedTab == 0 ? _unreadNotifications : _allNotifications;
  }

  String _formatCreatedAt(Map<String, dynamic> notification) {
    final raw = notification['createdAt'] as String?;
    if (raw == null) {
      return '';
    }

    final createdAt = DateTime.tryParse(raw)?.toLocal();
    if (createdAt == null) {
      return '';
    }

    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '${AppFormatters.date(createdAt)} • $hour:$minute';
  }

  IconData _iconForType(int? type) {
    switch (type) {
      case 1:
      case 2:
        return Icons.payments_outlined;
      case 8:
      case 12:
        return Icons.cancel_outlined;
      case 9:
      case 22:
      case 23:
        return Icons.event_repeat_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColorForType(int? type, ThemeData theme) {
    switch (type) {
      case 1:
        return AppColors.teal;
      case 2:
      case 8:
      case 12:
        return AppColors.coral;
      case 9:
      case 22:
      case 23:
        return theme.colorScheme.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.notificationsTitle),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _isMarkingAll ? null : _markAllAsRead,
              child: _isMarkingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppStrings.notificationsMarkAllRead),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBarSelector(
              tabs: [
                '${AppStrings.notificationsUnreadTab} ($_unreadCount)',
                AppStrings.notificationsAllTab,
              ],
              selectedIndex: _selectedTab,
              onTap: (index) => setState(() => _selectedTab = index),
            ),
          ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
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

    if (_visibleNotifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            HelpiEmptyState(
              icon: Icons.notifications_none_outlined,
              title: AppStrings.notificationsEmpty,
              subtitle: AppStrings.notificationsEmptySubtitle,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _visibleNotifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = _visibleNotifications[index];
          return _buildNotificationCard(theme, notification);
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _markAsRead(notification),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? theme.colorScheme.surface
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isRead
                  ? AppColors.border
                  : theme.colorScheme.secondary.withAlpha(60),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _iconColorForType(type, theme).withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconForType(type),
                  color: _iconColorForType(type, theme),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatCreatedAt(notification),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
