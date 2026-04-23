import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/l10n/theme_notifier.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/providers/realtime_sync_provider.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/features/notifications/presentation/notifications_screen.dart';
import 'package:helpi_app/features/profile/presentation/profile_credentials_screen.dart';
import 'package:helpi_app/features/profile/presentation/profile_student_data_screen.dart';
import 'package:helpi_app/features/profile/presentation/profile_availability_screen.dart';
import 'package:helpi_app/features/profile/presentation/profile_settings_screen.dart';
import 'package:helpi_app/features/profile/presentation/terms_screen.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';

/// Bolt/Glovo-style profile menu for student role.
class StudentMenuScreen extends ConsumerStatefulWidget {
  const StudentMenuScreen({
    super.key,
    required this.localeNotifier,
    required this.themeNotifier,
    required this.onLogout,
    required this.availabilityNotifier,
  });

  final LocaleNotifier localeNotifier;
  final ThemeNotifier themeNotifier;
  final VoidCallback onLogout;
  final AvailabilityNotifier availabilityNotifier;

  @override
  ConsumerState<StudentMenuScreen> createState() => _StudentMenuScreenState();
}

class _StudentMenuScreenState extends ConsumerState<StudentMenuScreen> {
  String _userName = '';
  bool _isLoading = true;
  String? _profileImageUrl;
  int? _contactId;
  int? _studentUserId;

  // Profile data cache – loaded once, passed to sub-screens
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadBasicInfo();
  }

  Future<void> _loadBasicInfo() async {
    final userId = await TokenStorage().getUserId();
    if (userId == null || !mounted) return;
    _studentUserId = userId;

    final api = AppApiService();
    final result = await api.getStudentProfile(userId);
    if (!mounted) return;

    if (result.success && result.data != null) {
      _profileData = result.data!;
      final contact = result.data!['contact'] as Map<String, dynamic>? ?? {};
      _userName = contact['fullName'] as String? ?? '';
      _contactId = (contact['id'] as num?)?.toInt();

      // Profile image: relative URL from backend → full URL
      final imgPath = contact['profileImageUrl'] as String?;
      if (imgPath != null && imgPath.isNotEmpty) {
        _profileImageUrl = '${ApiEndpoints.baseUrl}$imgPath';
      } else {
        _profileImageUrl = null;
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Auto-reload when backend pushes profile changes via SignalR
    ref.listen<int>(profileVersionProvider, (prev, next) {
      if (prev != next) {
        debugPrint(
          '[StudentMenu] profileVersion changed $prev → $next, reloading',
        );
        _loadBasicInfo();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.profile),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Badge(
              isLabelVisible: ref.watch(notificationsUnreadProvider) > 0,
              label: Text(
                ref.watch(notificationsUnreadProvider) > 9
                    ? '9+'
                    : '${ref.watch(notificationsUnreadProvider)}',
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: AppStrings.notificationsTitle,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // -- Bolt-style centered header --
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 44,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _userName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, indent: 20, endIndent: 20),

                // -- Menu items --
                _MenuItem(
                  icon: Icons.email_outlined,
                  label: AppStrings.accessData,
                  onTap: () => _push(
                    ProfileCredentialsScreen(profileData: _profileData),
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _MenuItem(
                  icon: Icons.person_outline,
                  label: AppStrings.studentData,
                  onTap: () => _push(
                    ProfileStudentDataScreen(
                      profileData: _profileData,
                      studentUserId: _studentUserId,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _MenuItem(
                  icon: Icons.calendar_today_outlined,
                  label: AppStrings.availabilitySection,
                  onTap: () => _push(
                    ProfileAvailabilityScreen(
                      availabilityNotifier: widget.availabilityNotifier,
                      studentUserId: _studentUserId,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _MenuItem(
                  icon: Icons.tune_outlined,
                  label: AppStrings.settings,
                  onTap: () => _push(
                    ProfileSettingsScreen(
                      localeNotifier: widget.localeNotifier,
                      themeNotifier: widget.themeNotifier,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: AppStrings.termsOfUseTitle,
                  onTap: _openTerms,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),

                // -- Logout --
                _MenuItem(
                  icon: Icons.logout,
                  label: AppStrings.logout,
                  onTap: _confirmLogout,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),

                const SizedBox(height: 24),

                // -- Delete account --
                Center(
                  child: GestureDetector(
                    onTap: () => _confirmDeleteAccount(context),
                    child: Text(
                      AppStrings.deleteAccount,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // -- Version --
                Center(
                  child: Text(
                    AppStrings.appVersion,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  // ── Photo picker ──────────────────────────────

  void _pickProfilePhoto() {
    if (_contactId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppStrings.takePhoto),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppStrings.chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            if (_profileImageUrl != null)
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  AppStrings.removePhoto,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final api = AppApiService();
    final result = await api.uploadProfileImage(
      contactId: _contactId!,
      filePath: picked.path,
    );
    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() {
        _profileImageUrl = '${ApiEndpoints.baseUrl}${result.data!}';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? AppStrings.photoUploadFailed)),
      );
    }
  }

  Future<void> _deleteProfileImage() async {
    final api = AppApiService();
    final result = await api.deleteProfileImage(contactId: _contactId!);
    if (!mounted) return;

    if (result.success) {
      setState(() => _profileImageUrl = null);
    }
  }

  // ── Navigation helpers ────────────────────────

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    // Reload profile data after returning from sub-screen
    setState(() => _isLoading = true);
    await _loadBasicInfo();
  }

  void _openTerms() {
    _push(const TermsScreen());
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.logoutConfirmTitle),
        content: Text(AppStrings.logoutConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) widget.onLogout();
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deleteAccountConfirmTitle),
        content: Text(AppStrings.deleteAccountConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.deleteAccountNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(AppStrings.deleteAccountYes),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed != true) return;

    final result = await AuthService().deleteAccount();
    if (!context.mounted) return;

    if (result.success) {
      widget.onLogout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? AppStrings.deleteAccountError),
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════
// Menu Item tile (same pattern as senior menu)
// ══════════════════════════════════════════════
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface, size: 24),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withAlpha(100),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
