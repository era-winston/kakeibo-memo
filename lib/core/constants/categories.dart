import 'package:flutter/material.dart';

class AppCategory {
  final String name;
  final String emoji;
  final bool isIncome;
  final Color color;

  const AppCategory({
    required this.name,
    required this.emoji,
    required this.isIncome,
    required this.color,
  });
}

class AppCategories {
  AppCategories._();

  static const List<AppCategory> expense = [
    AppCategory(name: '食費',   emoji: '🍚', isIncome: false, color: Color(0xFF2E7D6B)),
    AppCategory(name: '外食',   emoji: '🍜', isIncome: false, color: Color(0xFF00838F)),
    AppCategory(name: '交通',   emoji: '🚃', isIncome: false, color: Color(0xFF1976D2)),
    AppCategory(name: '日用品', emoji: '🛒', isIncome: false, color: Color(0xFF6A1B9A)),
    AppCategory(name: '医療',   emoji: '💊', isIncome: false, color: Color(0xFFD32F2F)),
    AppCategory(name: '娯楽',   emoji: '🎮', isIncome: false, color: Color(0xFFFF8F00)),
    AppCategory(name: '被服',   emoji: '👕', isIncome: false, color: Color(0xFF4527A0)),
    AppCategory(name: '美容',   emoji: '💄', isIncome: false, color: Color(0xFFC62828)),
    AppCategory(name: '光熱費', emoji: '💡', isIncome: false, color: Color(0xFF558B2F)),
    AppCategory(name: '通信',   emoji: '📱', isIncome: false, color: Color(0xFF1565C0)),
    // 固定費
    AppCategory(name: '家賃',   emoji: '🏠', isIncome: false, color: Color(0xFF5D4037)),
    AppCategory(name: '保険',   emoji: '🛡️', isIncome: false, color: Color(0xFF00695C)),
    AppCategory(name: 'サブスク', emoji: '🔄', isIncome: false, color: Color(0xFF7B1FA2)),
    AppCategory(name: 'ローン', emoji: '🏦', isIncome: false, color: Color(0xFF37474F)),
    // 個人事業主向け
    AppCategory(name: '税金',   emoji: '🏛️', isIncome: false, color: Color(0xFF4E342E)),
    AppCategory(name: '年金',   emoji: '📋', isIncome: false, color: Color(0xFF0D47A1)),
    AppCategory(name: '国保',   emoji: '🏥', isIncome: false, color: Color(0xFFB71C1C)),
    AppCategory(name: 'その他', emoji: '📌', isIncome: false, color: Color(0xFF757575)),
  ];

  static const List<AppCategory> income = [
    AppCategory(name: '給与',     emoji: '💰', isIncome: true, color: Color(0xFF1976D2)),
    AppCategory(name: '事業収入', emoji: '💼', isIncome: true, color: Color(0xFF00838F)),
    AppCategory(name: '副業',     emoji: '💻', isIncome: true, color: Color(0xFF2E7D6B)),
    AppCategory(name: '臨時収入', emoji: '🎁', isIncome: true, color: Color(0xFFFF8F00)),
    AppCategory(name: 'その他収入', emoji: '📥', isIncome: true, color: Color(0xFF6A1B9A)),
  ];

  static final Map<String, String> _emojiMap = {
    for (final c in [...expense, ...income]) c.name: c.emoji,
  };

  static final Map<String, Color> _colorMap = {
    for (final c in [...expense, ...income]) c.name: c.color,
  };

  static String emojiFor(String name) => _emojiMap[name] ?? '📌';
  static Color colorFor(String name) => _colorMap[name] ?? const Color(0xFF757575);
}
