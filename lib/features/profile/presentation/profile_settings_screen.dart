import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/l10n/theme_notifier.dart';

/// Sub-screen: language + theme pickers.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.localeNotifier,
    required this.themeNotifier,
  });

  final LocaleNotifier localeNotifier;
  final ThemeNotifier themeNotifier;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late String _selectedLang = AppStrings.currentLocale.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // -- Language --
          InputDecorator(
            decoration: InputDecoration(
              labelText: AppStrings.language,
              labelStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
              prefixIcon: Icon(
                Icons.language,
                color: theme.colorScheme.secondary,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLang,
                isDense: true,
                isExpanded: true,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedLang = v);
                    widget.localeNotifier.setLocale(v);
                  }
                },
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                items: [
                  DropdownMenuItem(value: 'HR', child: Text(AppStrings.langHr)),
                  DropdownMenuItem(value: 'EN', child: Text(AppStrings.langEn)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Theme --
          ValueListenableBuilder<ThemeMode>(
            valueListenable: widget.themeNotifier,
            builder: (context, themeMode, _) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: AppStrings.themeMode,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                  prefixIcon: Icon(
                    Icons.brightness_6,
                    color: theme.colorScheme.secondary,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: themeMode,
                    isDense: true,
                    isExpanded: true,
                    onChanged: (v) {
                      if (v != null) {
                        widget.themeNotifier.setThemeMode(v);
                      }
                    },
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(AppStrings.themeSystem),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(AppStrings.themeLight),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(AppStrings.themeDark),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
