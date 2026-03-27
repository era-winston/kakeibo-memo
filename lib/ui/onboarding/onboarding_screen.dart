import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';

const _kOnboardingKey = 'onboarding_done';

Future<bool> isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingKey) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingKey, true);
}

// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      emoji: '✏️',
      title: '2タップで記録完了',
      body: 'カテゴリを選んで金額を入れるだけ。\n家計簿が続かない理由は「面倒」だから。\nだからこのアプリはとにかくシンプルです。',
      bg: Color(0xFFE8F5F2),
      accent: AppColors.primary,
    ),
    _PageData(
      emoji: '🔒',
      title: 'データは端末の中だけ',
      body: 'クラウドに送りません。\n広告もありません。\nあなたの家計はあなただけのもの。',
      bg: Color(0xFFE3F2FD),
      accent: AppColors.income,
    ),
    _PageData(
      emoji: '📊',
      title: 'グラフで支出を把握',
      body: '月の支出内訳や6ヶ月推移を自動集計。\n記録するだけでお金の流れが見えてきます。',
      bg: Color(0xFFFFF8E1),
      accent: Color(0xFFFF8F00),
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _pages[_page];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      color: data.bg,
      child: SafeArea(
        child: Column(
          children: [
            // ── スキップボタン ──────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'スキップ',
                    style: TextStyle(
                      color: data.accent.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // ── スライドコンテンツ ──────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(data: _pages[i]),
              ),
            ),

            // ── ページインジケーター ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? data.accent
                        : data.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // ── ボタン ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: data.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    _page < _pages.length - 1 ? '次へ' : '始める',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PageContent extends StatelessWidget {
  final _PageData data;
  const _PageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 絵文字アイコン
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: data.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // タイトル
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: data.accent,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // 説明文
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary.withValues(alpha: 0.75),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PageData {
  final String emoji;
  final String title;
  final String body;
  final Color bg;
  final Color accent;

  const _PageData({
    required this.emoji,
    required this.title,
    required this.body,
    required this.bg,
    required this.accent,
  });
}
