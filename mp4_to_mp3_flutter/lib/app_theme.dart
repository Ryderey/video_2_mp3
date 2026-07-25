import 'package:flutter/material.dart';

/// 中老年友好主题：大字体、加粗、高对比度
class AppTheme {
  // 主色调
  static const Color primary = Color(0xFF0D6E63); // 深青
  static const Color primaryDark = Color(0xFF0A574F);
  static const Color accent = Color(0xFFE8770D); // 橙色（主操作）
  static const Color danger = Color(0xFFC0392B); // 红色（停止）
  static const Color background = Color(0xFFEEF2F5); // 浅灰背景
  static const Color textColor = Color(0xFF1C2733); // 高对比文字
  static const Color textSecondary = Color(0xFF4A5560);
  static const Color success = Color(0xFF2F9E5F);

  // 字号规范
  static const double fontSizeBody = 20.0;
  static const double fontSizeTitle = 28.0;
  static const double fontSizeButton = 22.0;
  static const double fontSizeSmall = 17.0;
  static const double fontSizeLog = 15.0;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeButton,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(160, 64),
          textStyle: const TextStyle(
            fontSize: fontSizeButton,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8A94A0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8A94A0), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
