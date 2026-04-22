import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models/transaction.dart';
import 'app.dart';
import 'ui/settings/passcode_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // オフラインアプリのため、Google Fontsのランタイムダウンロードを無効化
  GoogleFonts.config.allowRuntimeFetching = false;

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());

  final prefs = await SharedPreferences.getInstance();

  await Future.wait([
    Hive.openBox<Transaction>('transactions'),
    initializeDateFormatting('ja'),
  ]);

  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  final savedPasscode = prefs.getString('passcode_hash');

  runApp(
    ProviderScope(
      child: _RootApp(
        showOnboarding: !onboardingDone,
        savedPasscode: savedPasscode,
      ),
    ),
  );
}

// ── ルートウィジェット（パスコード画面 → メインアプリ） ──────────────────────

class _RootApp extends StatefulWidget {
  final bool showOnboarding;
  final String? savedPasscode;

  const _RootApp({
    required this.showOnboarding,
    required this.savedPasscode,
  });

  @override
  State<_RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<_RootApp> {
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    // パスコードが未設定なら最初からアンロック状態
    if (widget.savedPasscode == null) {
      _unlocked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KakeiboApp(
      showOnboarding: widget.showOnboarding,
      // パスコード未解除の場合は PasscodeLockScreen をホームとして表示
      lockScreen: !_unlocked && widget.savedPasscode != null
          ? PasscodeLockScreen(
              onUnlocked: () => setState(() => _unlocked = true),
            )
          : null,
    );
  }
}
