import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary (Deep Indigo / Violet scale)
  static const Color primary1 = Color(0xFFFBFBFE);
  static const Color primary2 = Color(0xFFF2F1FD);
  static const Color primary3 = Color(0xFFE4E1FA);
  static const Color primary4 = Color(0xFFC7BFF5);
  static const Color primary5 = Color(0xFFA699ED);
  static const Color primary6 = Color(0xFF836EE4);
  static const Color primary7 = Color(0xFF6A4CE0);
  static const Color primary8 = Color(0xFF5331C9);
  static const Color primary9 = Color(0xFF3F1EA3);
  static const Color primary10 = Color(0xFF2C1573);
  static const Color primary11 = Color(0xFF1B0C48);
  static const Color primary12 = Color(0xFF0F0628);

  // Secondary (Electric Amber scale)
  static const Color secondary1 = Color(0xFFFFFDF5);
  static const Color secondary2 = Color(0xFFFFF9E5);
  static const Color secondary3 = Color(0xFFFFF0BF);
  static const Color secondary4 = Color(0xFFFFE080);
  static const Color secondary5 = Color(0xFFFFCB33);
  static const Color secondary6 = Color(0xFFF5B300);
  static const Color secondary7 = Color(0xFFD49400);
  static const Color secondary8 = Color(0xFFA87100);
  static const Color secondary9 = Color(0xFF7A4F00);
  static const Color secondary10 = Color(0xFF523300);
  static const Color secondary11 = Color(0xFF301D00);
  static const Color secondary12 = Color(0xFF170D00);

  // Neutral (Zinc scale)
  static const Color neutral0 = Color(0xFF000000);
  static const Color neutral1 = Color(0xFF09090B);
  static const Color neutral2 = Color(0xFF18181B);
  static const Color neutral3 = Color(0xFF27272A);
  static const Color neutral4 = Color(0xFF3F3F46);
  static const Color neutral5 = Color(0xFF52525B);
  static const Color neutral6 = Color(0xFF71717A);
  static const Color neutral7 = Color(0xFFA1A1AA);
  static const Color neutral8 = Color(0xFFD4D4D8);
  static const Color neutral9 = Color(0xFFE4E4E7);
  static const Color neutral10 = Color(0xFFF4F4F5);
  static const Color neutral11 = Color(0xFFFAFAFA);
  static const Color neutral12 = Color(0xFFFFFFFF);

  // Status & Semantics
  static const Color success = Color(0xFF34D399);
  static const Color successBackground = Color(0xFF132D1C);
  static const Color error = Color(0xFFF87171);
  static const Color errorBackground = Color(0xFF2A1615);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoBackground = Color(0xFF1B2240);
  static const Color paused = Color(0xFF9CA3AF);

  /* Convenience Semantic Aliases */
  static const Color primaryBase = primary9;
  static const Color primaryHover = primary8;
  static const Color primaryLight = primary3;
  static const Color primaryAccent = primary10;
  static const Color primaryDark = primary11;

  static const Color dangerBase = error;
  static const Color dangerBackground = errorBackground;
  static const Color dangerDark = Color(0xFF2D0A0A);
  static const Color infoBase = info;
  static const Color successBase = success;
  static const Color warningBase = warning;

  // SQLite Data Types
  static const Color typeInteger = Color(0xFF60A5FA);
  static const Color typeText = Color(0xFF34D399);
  static const Color typeBlob = Color(0xFFFFA073);
  static const Color typeReal = Color(0xFFC084FC);
  static const Color typeNull = Color(0xFFA1A1AA);
}
