import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode'; // 0=system, 1=light, 2=dark
const _kPasscodeKey = 'passcode_hash'; // SHA-256 ハッシュを保存

// ────────────────────────────────────────────────────────────────────────────
// テーマモード
// ────────────────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kThemeModeKey) ?? 0;
    return _fromInt(v);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeModeKey, _toInt(mode));
    state = AsyncData(mode);
  }

  static ThemeMode _fromInt(int v) {
    switch (v) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static int _toInt(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      default:
        return 0;
    }
  }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
        ThemeModeNotifier.new);

// ────────────────────────────────────────────────────────────────────────────
// パスコード
// ────────────────────────────────────────────────────────────────────────────

// SHA-256 ハッシュ化ユーティリティ
String _hashPin(String pin) {
  final bytes = utf8.encode(pin);
  return sha256.convert(bytes).toString();
}

class PasscodeNotifier extends AsyncNotifier<String?> {
  /// state は ハッシュ文字列 or null（未設定）
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPasscodeKey);
  }

  /// PIN を SHA-256 ハッシュ化して保存
  Future<void> setPasscode(String pin) async {
    final hash = _hashPin(pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPasscodeKey, hash);
    state = AsyncData(hash);
  }

  /// 入力 PIN が保存済みハッシュと一致するか検証
  bool verify(String pin) {
    final stored = state.valueOrNull;
    if (stored == null) return false;
    return _hashPin(pin) == stored;
  }

  Future<void> clearPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPasscodeKey);
    state = const AsyncData(null);
  }

  bool get isEnabled => state.valueOrNull != null;
}

final passcodeProvider =
    AsyncNotifierProvider<PasscodeNotifier, String?>(PasscodeNotifier.new);
