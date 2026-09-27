import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

class AppDurations {
  AppDurations._();

  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slowest = Duration(milliseconds: 600);
}

class AppCurves {
  AppCurves._();

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;
}

class AppGradients {
  AppGradients._();

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary9, AppColors.primary10],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neutral3, AppColors.neutral2],
  );
}

class AppAnimations {
  AppAnimations._();

  static const Duration hover = Duration(milliseconds: 150);
  static const Duration tabSwitch = Duration(milliseconds: 200);
  static const Duration modal = Duration(milliseconds: 250);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.neutral0,
      primaryColor: AppColors.primary9,
      canvasColor: AppColors.neutral0,
      cardColor: AppColors.neutral2,
      dividerColor: AppColors.neutral4,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.neutral3,
      cardTheme: CardThemeData(
        color: AppColors.neutral2,
        elevation: 0,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.neutral4, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.neutral0,
        foregroundColor: AppColors.neutral12,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.neutral2,
        elevation: 0,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.neutral5, width: 1),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.neutral2,
        elevation: 4,
        mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neutral4, width: 1),
        ),
      ),
      textTheme: GoogleFonts.googleSansTextTheme(),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary9,
        onPrimary: AppColors.neutral12,
        secondary: AppColors.primary4,
        onSecondary: AppColors.neutral12,
        surface: AppColors.neutral2,
        onSurface: AppColors.neutral12,
        error: AppColors.error,
        onError: AppColors.neutral12,
        outline: AppColors.neutral4,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.neutral12,
        selectionColor: AppColors.neutral6.withValues(alpha: 0.4),
        selectionHandleColor: AppColors.neutral7,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutral5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutral5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.neutral6, width: 1.0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.neutral7;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.neutral12;
            }
            return AppColors.neutral11;
          }),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.neutral7;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.neutral12;
            }
            return AppColors.neutral10;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.neutral7;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary4;
            }
            return AppColors.neutral11;
          }),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.neutral7;
          }
          return AppColors.neutral5;
        }),
        thickness: const WidgetStatePropertyAll(6.0),
        radius: const Radius.circular(4.0),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: ShapeDecoration(
          color: AppColors.neutral3,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: const BorderSide(color: AppColors.neutral5, width: 1),
          ),
        ),
        textStyle: AppTypography.caption.copyWith(color: AppColors.neutral12),
      ),
    );
  }
}
