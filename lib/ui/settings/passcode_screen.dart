import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';

// ── 認証モード（起動時ロック）────────────────────────────────────────────────

class PasscodeLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const PasscodeLockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<PasscodeLockScreen> createState() =>
      _PasscodeLockScreenState();
}

class _PasscodeLockScreenState extends ConsumerState<PasscodeLockScreen> {
  String _entered = '';
  bool _shake = false;
  final _localAuth = LocalAuthentication();

  // 試行回数制限
  int _failCount = 0;
  bool _locked = false;       // 30秒ロック中
  bool _permanentLock = false; // 10回失敗で完全ロック
  int _lockSecondsLeft = 0;
  Timer? _lockTimer;

  static const _softLockThreshold = 5;   // 5回失敗→30秒ロック
  static const _hardLockThreshold = 10;  // 10回失敗→完全ロック
  static const _softLockDuration = 30;   // 秒

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _tryBiometrics() async {
    if (_locked || _permanentLock) return;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return;
      final authenticated = await _localAuth.authenticate(
        localizedReason: '家計メモ帳のロックを解除します',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (authenticated && mounted) {
        HapticFeedback.lightImpact();
        widget.onUnlocked();
      }
    } catch (_) {}
  }

  void _startSoftLock() {
    setState(() {
      _locked = true;
      _lockSecondsLeft = _softLockDuration;
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _lockSecondsLeft--);
      if (_lockSecondsLeft <= 0) {
        t.cancel();
        setState(() {
          _locked = false;
          _entered = '';
        });
      }
    });
  }

  Future<void> _onDigit(String d) async {
    if (_locked || _permanentLock || _entered.length >= 4) return;
    setState(() => _entered += d);
    HapticFeedback.selectionClick();

    if (_entered.length == 4) {
      final notifier = ref.read(passcodeProvider.notifier);
      if (notifier.verify(_entered)) {
        HapticFeedback.lightImpact();
        widget.onUnlocked();
      } else {
        _failCount++;
        await _shakeAndReset();
        if (_failCount >= _hardLockThreshold) {
          setState(() => _permanentLock = true);
        } else if (_failCount >= _softLockThreshold) {
          _startSoftLock();
        }
      }
    }
  }

  Future<void> _shakeAndReset() async {
    HapticFeedback.vibrate();
    setState(() => _shake = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() { _shake = false; _entered = ''; });
  }

  void _onDelete() {
    if (_locked || _permanentLock || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    if (_permanentLock) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 56, color: AppColors.expense),
                  SizedBox(height: 16),
                  Text(
                    'アクセスが無効になりました',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '試行回数が上限（$_hardLockThreshold回）に達しました。\nアプリを再インストールしてください。',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'パスコードを入力',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (_failCount > 0 && !_locked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '残り${_hardLockThreshold - _failCount}回',
                  style: TextStyle(
                    fontSize: 13,
                    color: _failCount >= _softLockThreshold
                        ? AppColors.expense
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 40),
            _ShakeWidget(
              shake: _shake,
              child: _PinDots(filled: _entered.length),
            ),
            if (_locked) ...[
              const SizedBox(height: 24),
              Text(
                '$_lockSecondsLeft秒後に再試行できます',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.expense,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const Spacer(),
            _Numpad(
              onDigit: _locked || _permanentLock ? (_) {} : _onDigit,
              onDelete: _locked || _permanentLock ? () {} : _onDelete,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _locked || _permanentLock ? null : _tryBiometrics,
              icon: const Icon(Icons.fingerprint, size: 22),
              label: const Text('Face ID / Touch ID'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── 設定モード（PINを新規登録 / 変更）────────────────────────────────────────

class PasscodeSetScreen extends ConsumerStatefulWidget {
  const PasscodeSetScreen({super.key});

  @override
  ConsumerState<PasscodeSetScreen> createState() =>
      _PasscodeSetScreenState();
}

class _PasscodeSetScreenState extends ConsumerState<PasscodeSetScreen> {
  String _first = '';
  String _entered = '';
  bool _confirming = false;
  bool _shake = false;

  Future<void> _onDigit(String d) async {
    if (_entered.length >= 4) return;
    setState(() => _entered += d);
    HapticFeedback.selectionClick();

    if (_entered.length == 4) {
      if (!_confirming) {
        // 1回目: 確認へ
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _first = _entered;
          _entered = '';
          _confirming = true;
        });
      } else {
        // 2回目: 一致チェック
        if (_entered == _first) {
          await ref.read(passcodeProvider.notifier).setPasscode(_entered);
          HapticFeedback.lightImpact();
          if (mounted) {
            Navigator.of(context).pop(true); // 成功
          }
        } else {
          await _shakeAndReset();
        }
      }
    }
  }

  Future<void> _shakeAndReset() async {
    HapticFeedback.vibrate();
    setState(() => _shake = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _shake = false;
      _entered = '';
      _confirming = false;
      _first = '';
    });
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('パスコードを設定')),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(
              _confirming ? 'もう一度入力してください' : 'パスコードを入力してください',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            _ShakeWidget(
              shake: _shake,
              child: _PinDots(filled: _entered.length),
            ),
            const Spacer(),
            _Numpad(onDigit: _onDigit, onDelete: _onDelete),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── 共通: PINドットインジケーター ──────────────────────────────────────────────

class _PinDots extends StatelessWidget {
  final int filled;
  const _PinDots({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? AppColors.primary : Colors.transparent,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        );
      }),
    );
  }
}

// ── 共通: テンキー ────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const _Numpad({required this.onDigit, required this.onDelete});

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: _keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 72, height: 72);
              return _NumKey(
                label: k,
                onTap: k == '⌫' ? onDelete : () => onDigit(k),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        alignment: Alignment.center,
        child: label == '⌫'
            ? const Icon(Icons.backspace_outlined, size: 22)
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

// ── 共通: シェイクアニメーション ──────────────────────────────────────────────

class _ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;

  const _ShakeWidget({required this.child, required this.shake});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _anim = Tween(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticIn));

  @override
  void didUpdateWidget(_ShakeWidget old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      child: widget.child,
      builder: (_, child) {
        final offset = _ctrl.isAnimating
            ? 8 * (0.5 - _anim.value).abs() * (_anim.value < 0.5 ? 1 : -1)
            : 0.0;
        return Transform.translate(
          offset: Offset(offset * 4, 0),
          child: child,
        );
      },
    );
  }
}
