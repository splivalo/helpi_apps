import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/shared/models/faculty.dart';

/// Shows a bottom-sheet picker with a search field to choose a faculty.
/// Returns the selected [Faculty] or `null` if dismissed.
Future<Faculty?> showFacultyPicker({
  required BuildContext context,
  required List<Faculty> faculties,
  Faculty? current,
}) {
  return showModalBottomSheet<Faculty>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FacultyPickerSheet(faculties: faculties, current: current),
  );
}

class _FacultyPickerSheet extends StatefulWidget {
  const _FacultyPickerSheet({required this.faculties, this.current});

  final List<Faculty> faculties;
  final Faculty? current;

  @override
  State<_FacultyPickerSheet> createState() => _FacultyPickerSheetState();
}

class _FacultyPickerSheetState extends State<_FacultyPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<Faculty> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.faculties;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.faculties;
      } else {
        _filtered = widget.faculties.where((f) {
          return f.abbreviation.toLowerCase().contains(q) ||
              f.name.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              // ── Handle ──
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: HelpiTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // ── Title ──
              Text(
                AppStrings.facultyPickerTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // ── Search ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppStrings.facultySearchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── List ──
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.facultyNoResults,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: HelpiTheme.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        separatorBuilder: (context2, index) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (ctx, i) {
                          final f = _filtered[i];
                          final isSelected = widget.current?.id == f.id;

                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: HelpiTheme.teal.withAlpha(20),
                            selectedColor: HelpiTheme.teal,
                            title: Text(
                              f.abbreviation.isNotEmpty
                                  ? f.abbreviation
                                  : f.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              f.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: HelpiTheme.textSecondary,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.secondary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () => Navigator.of(ctx).pop(f),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
