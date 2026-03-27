import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ダーク/ライトで切り替わる色を BuildContext から取得する拡張。
/// 意味色（income/expense/primary）は AppColors 定数をそのまま使用。
/// 背景・テキスト・ボーダーのみ Brightness で分岐。
extension AppColorsContext on BuildContext {
  bool get _isDark =>
      Theme.of(this).brightness == Brightness.dark;

  // テキスト
  Color get textSecondary =>
      _isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;

  Color get textPrimary =>
      _isDark ? const Color(0xFFF0F0F0) : AppColors.textPrimary;

  // ボーダー・区切り線
  Color get dividerColor =>
      _isDark ? const Color(0xFF374151) : AppColors.divider;

  // 背景
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  Color get cardBgColor =>
      _isDark ? const Color(0xFF1F2937) : AppColors.cardBg;

  // カテゴリセル背景 (選択なし)
  Color get categoryBg =>
      _isDark ? const Color(0xFF111827) : AppColors.surface;
}
