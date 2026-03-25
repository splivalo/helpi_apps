import 'package:helpi_app/core/l10n/app_strings.dart';

/// Centralizirani formatteri i helperi za Helpi app.
class AppFormatters {
  AppFormatters._();

  /// Format: "DD.MM.YYYY."
  static String date(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  /// DateTime.weekday (1-7) -> puno ime: "Ponedjeljak", "Utorak" ...
  static String dayFullName(int weekday) {
    switch (weekday) {
      case 1:
        return AppStrings.dayMonFull;
      case 2:
        return AppStrings.dayTueFull;
      case 3:
        return AppStrings.dayWedFull;
      case 4:
        return AppStrings.dayThuFull;
      case 5:
        return AppStrings.dayFriFull;
      case 6:
        return AppStrings.daySatFull;
      case 7:
        return AppStrings.daySunFull;
      default:
        return '';
    }
  }

  /// DateTime.weekday -> 3 slova: "Pon", "Uto", "Sri" ...
  static String dayMediumName(int weekday) {
    switch (weekday) {
      case 1:
        return AppStrings.dayMon;
      case 2:
        return AppStrings.dayTue;
      case 3:
        return AppStrings.dayWed;
      case 4:
        return AppStrings.dayThu;
      case 5:
        return AppStrings.dayFri;
      case 6:
        return AppStrings.daySat;
      case 7:
        return AppStrings.daySun;
      default:
        return '';
    }
  }

  /// DateTime.weekday -> 2 slova: "Po", "Ut", "Sr" ...
  static String dayShortName(int weekday) {
    switch (weekday) {
      case 1:
        return AppStrings.dayMonShort;
      case 2:
        return AppStrings.dayTueShort;
      case 3:
        return AppStrings.dayWedShort;
      case 4:
        return AppStrings.dayThuShort;
      case 5:
        return AppStrings.dayFriShort;
      case 6:
        return AppStrings.daySatShort;
      case 7:
        return AppStrings.daySunShort;
      default:
        return '';
    }
  }

  /// Nalazi prvi dan s [weekday] (1=Mon…7=Sun) na ili nakon [from].
  static DateTime firstOccurrence(int weekday, DateTime from) {
    final diff = (weekday - from.weekday + 7) % 7;
    return from.add(Duration(days: diff == 0 ? 0 : diff));
  }
}
