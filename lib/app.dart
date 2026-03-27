import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'providers/settings_provider.dart';
import 'ui/home/home_screen.dart';
import 'ui/history/history_screen.dart';
import 'ui/chart/chart_screen.dart';
import 'ui/input/input_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

// ── テーマビルダー ────────────────────────────────────────────────────────────

ThemeData _buildTheme(Brightness brightness) {
  final cs = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  );
  final isLight = brightness == Brightness.light;

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    brightness: brightness,
    scaffoldBackgroundColor:
        isLight ? AppColors.surface : const Color(0xFF111827),
    textTheme: GoogleFonts.notoSansJpTextTheme(
      isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isLight ? AppColors.cardBg : const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(
          color: isLight ? AppColors.divider : const Color(0xFF374151),
          width: 1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isLight ? AppColors.cardBg : const Color(0xFF1F2937),
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      foregroundColor:
          isLight ? AppColors.textPrimary : const Color(0xFFF0F0F0),
      titleTextStyle: GoogleFonts.notoSansJp(
        color: isLight ? AppColors.textPrimary : const Color(0xFFF0F0F0),
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isLight ? AppColors.divider : const Color(0xFF374151),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:
          isLight ? AppColors.cardBg : const Color(0xFF1F2937),
    ),
  );
}

// ── アプリルート ──────────────────────────────────────────────────────────────

class KakeiboApp extends ConsumerWidget {
  final bool showOnboarding;
  final Widget? lockScreen;
  const KakeiboApp({
    super.key,
    this.showOnboarding = false,
    this.lockScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode =
        themeModeAsync.valueOrNull ?? ThemeMode.system;

    return MaterialApp(
      title: '家計メモ帳',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ja', 'JP'),
      home: lockScreen ??
          (showOnboarding ? const OnboardingScreen() : const MainShell()),
    );
  }
}

// ── メインシェル ──────────────────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    const screens = [
      HomeScreen(),
      HistoryScreen(),
      ChartScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (i) =>
            ref.read(currentTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: '履歴',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'グラフ',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openInput(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _openInput(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InputScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
