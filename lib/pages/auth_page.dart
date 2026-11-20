import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smarttaxi/nav.dart';
import 'package:smarttaxi/services/theme_provider.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_scene.dart';

const _danger = Color(0xFFFF5A5F);

enum _Mode { signIn, signUp }

enum _Submit { idle, loading, success }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  _Mode _mode = _Mode.signIn;
  _Submit _submit = _Submit.idle;
  final Map<String, String> _errors = {};
  int _shake = 0;
  bool _obscure = true;
  bool _obscureConfirm = true;

  bool get _isSignUp => _mode == _Mode.signUp;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _emailFocus, _passwordFocus, _confirmFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  void _setMode(_Mode m) {
    if (m == _mode || _submit != _Submit.idle) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = m;
      _errors.clear();
    });
  }

  Map<String, String> _validate() {
    final e = <String, String>{};
    final email = _email.text.trim();
    if (_isSignUp && _name.text.trim().isEmpty) e['name'] = 'Tell us your name';
    if (email.isEmpty) {
      e['email'] = 'Enter your email';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      e['email'] = "That email doesn't look right";
    }
    if (_password.text.isEmpty) {
      e['password'] = _isSignUp ? 'Create a password' : 'Enter your password';
    } else if (_isSignUp && _password.text.length < 6) {
      e['password'] = 'Use at least 6 characters';
    }
    if (_isSignUp) {
      if (_confirm.text.isEmpty) {
        e['confirm'] = 'Confirm your password';
      } else if (_confirm.text != _password.text) {
        e['confirm'] = "Passwords don't match";
      }
    }
    return e;
  }

  Future<void> _submitForm() async {
    if (_submit != _Submit.idle) return;
    FocusScope.of(context).unfocus();
    final errors = _validate();
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      if (errors.isNotEmpty) _shake++;
    });
    if (errors.isNotEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    TextInput.finishAutofillContext();
    setState(() => _submit = _Submit.loading);
    // Sign-in is simulated in this prototype.
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _submit = _Submit.success);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) context.go(AppRoutes.home);
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1D1C22),
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x26FFFFFF)),
          ),
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: OnbPalette.gold, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: isLight ? 1 : 0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (context, day, _) {
        final pal = OnbPalette(day);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: day > 0.5 ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: pal.scrim,
            body: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: OnboardingScenePainter(time: 0, day: day, intro: 1)),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight - 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: _content(pal, isLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content(OnbPalette pal, bool isLight) {
    Widget enter(Widget w, int i) => w
        .animate()
        .fadeIn(delay: (120 + i * 70).ms, duration: 600.ms)
        .slideY(begin: 0.18, curve: Curves.easeOutCubic);

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          enter(_TopBar(pal: pal, isLight: isLight), 0),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: _Emblem(time: _time)
                .animate()
                .scale(begin: const Offset(0.4, 0.4), duration: 900.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 300.ms),
          ),
          const SizedBox(height: 22),
          enter(_Header(mode: _mode, pal: pal), 1),
          const SizedBox(height: 26),
          enter(_ModeToggle(mode: _mode, pal: pal, onChanged: _setMode), 2),
          const SizedBox(height: 18),
          enter(_formCard(pal), 3),
          const SizedBox(height: 22),
          enter(
            _PrimaryButton(
              label: _isSignUp ? 'Create account' : 'Sign in',
              state: _submit,
              time: _time,
              onTap: _submitForm,
            ),
            4,
          ),
          const SizedBox(height: 26),
          enter(_OrDivider(pal: pal), 5),
          const SizedBox(height: 16),
          enter(
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    pal: pal,
                    label: 'Google',
                    glyph: Text(
                      'G',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: pal.text),
                    ),
                    onTap: () => _toast("Google sign-in isn't set up yet."),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    pal: pal,
                    label: 'Apple',
                    glyph: Icon(Icons.apple, size: 22, color: pal.text),
                    onTap: () => _toast("Apple sign-in isn't set up yet."),
                  ),
                ),
              ],
            ),
            6,
          ),
          const SizedBox(height: 28),
          enter(_switchPrompt(pal), 7),
          const SizedBox(height: 14),
          enter(_guestLink(pal), 8),
        ],
      ),
    );
  }

  Widget _formCard(OnbPalette pal) {
    final strength = _strength(_password.text);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pal.glassStrong, pal.glass],
        ),
        border: Border.all(color: pal.stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05 + 0.25 * (1 - pal.day)),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isSignUp) ...[
              _LuxField(
                key: const ValueKey('name'),
                controller: _name,
                focusNode: _nameFocus,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                pal: pal,
                error: _errors['name'],
                shake: _shake,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                onChanged: (_) => _clearError('name'),
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.2, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),
            ],
            _LuxField(
              key: const ValueKey('email'),
              controller: _email,
              focusNode: _emailFocus,
              label: 'Email address',
              icon: Icons.alternate_email_rounded,
              pal: pal,
              error: _errors['email'],
              shake: _shake,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => _clearError('email'),
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            _LuxField(
              key: const ValueKey('password'),
              controller: _password,
              focusNode: _passwordFocus,
              label: _isSignUp ? 'Create password' : 'Password',
              icon: Icons.lock_outline_rounded,
              pal: pal,
              error: _errors['password'],
              shake: _shake,
              obscure: _obscure,
              autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
              textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
              trailing: _EyeToggle(
                obscure: _obscure,
                pal: pal,
                onTap: () => setState(() => _obscure = !_obscure),
              ),
              onChanged: (_) {
                _clearError('password');
                if (_isSignUp) setState(() {});
              },
              onSubmitted: (_) => _isSignUp ? _confirmFocus.requestFocus() : _submitForm(),
            ),
            if (_isSignUp) ...[
              const SizedBox(height: 12),
              _StrengthMeter(strength: strength, pal: pal)
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 60.ms),
              const SizedBox(height: 14),
              _LuxField(
                key: const ValueKey('confirm'),
                controller: _confirm,
                focusNode: _confirmFocus,
                label: 'Confirm password',
                icon: Icons.verified_user_outlined,
                pal: pal,
                error: _errors['confirm'],
                shake: _shake,
                obscure: _obscureConfirm,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: _confirm.text.isNotEmpty && _confirm.text == _password.text ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      child: const Icon(Icons.check_circle_rounded, color: OnbPalette.teal, size: 20),
                    ),
                    _EyeToggle(
                      obscure: _obscureConfirm,
                      pal: pal,
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ],
                ),
                onChanged: (_) {
                  _clearError('confirm');
                  setState(() {});
                },
                onSubmitted: (_) => _submitForm(),
              ).animate().fadeIn(duration: 350.ms, delay: 90.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
            ] else ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: _Link(
                  text: 'Forgot password?',
                  pal: pal,
                  onTap: () => _toast("Password reset isn't available yet."),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switchPrompt(OnbPalette pal) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(
        key: ValueKey(_mode),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isSignUp ? 'Already riding with us? ' : 'New to SmartTaxi? ',
            style: GoogleFonts.inter(fontSize: 14, color: pal.muted),
          ),
          _Link(
            text: _isSignUp ? 'Sign in' : 'Create an account',
            pal: pal,
            onTap: () => _setMode(_isSignUp ? _Mode.signIn : _Mode.signUp),
          ),
        ],
      ),
    );
  }

  Widget _guestLink(OnbPalette pal) {
    return Center(
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: () => context.go(AppRoutes.home),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: pal.glass,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: pal.stroke),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continue as guest',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: pal.text),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 16, color: pal.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _strength(String p) {
    if (p.isEmpty) return 0;
    var s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p) || RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s.clamp(1, 4);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pieces
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.pal, required this.isLight});

  final OnbPalette pal;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'SmartTaxi',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: pal.text,
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: isLight ? 'Switch to dark mode' : 'Switch to light mode',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<ThemeProvider>().setThemeMode(isLight ? ThemeMode.dark : ThemeMode.light);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pal.glass,
                border: Border.all(color: pal.stroke),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween(begin: 0.6, end: 1.0).animate(anim),
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: Icon(
                  isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isLight),
                  size: 20,
                  color: isLight ? pal.text : OnbPalette.goldBright,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem({required this.time});

  final ValueListenable<double> time;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: TickBuilder(
        valueListenable: time,
        builder: (context, t, _) {
          final pulse = 0.5 + 0.5 * math.sin(t * 2);
          return CustomPaint(
            painter: _HaloPainter(time: t),
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.35, -0.4),
                    colors: [Color(0xFFFFF0B3), OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember],
                    stops: [0, 0.25, 0.65, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OnbPalette.gold.withValues(alpha: 0.35 + 0.2 * pulse),
                      blurRadius: 26 + 12 * pulse,
                    ),
                  ],
                ),
                child: const Icon(Icons.local_taxi_rounded, size: 28, color: OnbPalette.ink),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = OnbPalette.gold.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            OnbPalette.goldBright.withValues(alpha: 0),
            OnbPalette.goldBright,
            OnbPalette.goldBright.withValues(alpha: 0),
          ],
          stops: const [0, 0.22, 0.45],
          transform: GradientRotation(time * 1.4),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) => old.time != time;
}

class _Header extends StatelessWidget {
  const _Header({required this.mode, required this.pal});

  final _Mode mode;
  final OnbPalette pal;

  @override
  Widget build(BuildContext context) {
    final signUp = mode == _Mode.signUp;
    final eyebrowColor = Color.lerp(OnbPalette.gold, const Color(0xFFB36B00), pal.day)!;
    final width = MediaQuery.sizeOf(context).width;
    final size = width < 360 ? 32.0 : 38.0;

    final eyebrow = signUp ? 'NEW RIDER' : 'WELCOME BACK';
    final lines = signUp ? ['Your next ride', 'starts *here.*'] : ['Good to see you', '*again.*'];
    final body = signUp
        ? 'Create an account to save routes, track spending and plan multi-stop trips.'
        : 'Sign in to pick up your saved routes and recent trips.';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(mode),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 1.4,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.ember]),
                ),
              ),
              Text(
                eyebrow,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.6,
                  color: eyebrowColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines) Text.rich(TextSpan(children: _spans(line, size))),
          const SizedBox(height: 12),
          Text(body, style: GoogleFonts.inter(fontSize: 15, height: 1.55, color: pal.muted)),
        ],
      ),
    );
  }

  List<InlineSpan> _spans(String line, double size) {
    TextStyle style({Color? color, Paint? foreground}) => GoogleFonts.outfit(
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1.08,
          letterSpacing: -1.1,
          color: color,
          foreground: foreground,
        );
    final parts = line.split('*');
    return [
      for (var k = 0; k < parts.length; k++)
        if (parts[k].isNotEmpty)
          TextSpan(
            text: parts[k],
            style: k.isOdd
                ? style(
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          Color.lerp(OnbPalette.goldBright, const Color(0xFFF08A00), pal.day)!,
                          Color.lerp(OnbPalette.gold, const Color(0xFFE06200), pal.day)!,
                          Color.lerp(OnbPalette.ember, const Color(0xFFC2410C), pal.day)!,
                        ],
                      ).createShader(Rect.fromLTWH(0, 0, size * 5, size)),
                  )
                : style(color: pal.text),
          ),
    ];
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.pal, required this.onChanged});

  final _Mode mode;
  final OnbPalette pal;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: pal.glass,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: pal.stroke),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final half = c.maxWidth / 2;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              left: mode == _Mode.signIn ? 0 : half,
              top: 0,
              bottom: 0,
              width: half,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [OnbPalette.goldBright, OnbPalette.gold],
                  ),
                  boxShadow: [
                    BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (final m in _Mode.values)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: m == mode,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(m),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: m == mode ? OnbPalette.ink : pal.muted,
                            ),
                            child: Text(m == _Mode.signIn ? 'Sign in' : 'Create account'),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _LuxField extends StatefulWidget {
  const _LuxField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.pal,
    required this.shake,
    this.error,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final OnbPalette pal;
  final int shake;
  final String? error;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_LuxField> createState() => _LuxFieldState();
}

class _LuxFieldState extends State<_LuxField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant _LuxField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pal = widget.pal;
    final focused = widget.focusNode.hasFocus;
    final hasError = widget.error != null;
    final accent = hasError ? _danger : Color.lerp(OnbPalette.gold, const Color(0xFFE08A00), pal.day)!;
    final active = focused || hasError;
    const none = InputBorder.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey(widget.shake),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 520),
          builder: (context, t, child) => Transform.translate(
            offset: Offset(hasError ? math.sin(t * math.pi * 6) * (1 - t) * 10 : 0, 0),
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: focused ? pal.glassStrong : pal.glass,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? accent.withValues(alpha: 0.9) : pal.stroke,
                width: active ? 1.4 : 1,
              ),
              boxShadow: [
                if (active) BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 24, spreadRadius: -4),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: active ? accent.withValues(alpha: 0.15) : pal.glass,
                  ),
                  child: Icon(widget.icon, size: 20, color: active ? accent : pal.muted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    obscureText: widget.obscure,
                    obscuringCharacter: '•',
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    autofillHints: widget.autofillHints,
                    autocorrect: false,
                    enableSuggestions: !widget.obscure,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    cursorColor: accent,
                    style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w500, color: pal.text),
                    decoration: InputDecoration(
                      labelText: widget.label,
                      labelStyle: GoogleFonts.inter(fontSize: 14.5, color: pal.muted),
                      floatingLabelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? accent : pal.muted,
                      ),
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: none,
                      enabledBorder: none,
                      focusedBorder: none,
                      errorBorder: none,
                      focusedErrorBorder: none,
                      disabledBorder: none,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 15, color: _danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.error!,
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _danger),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.obscure, required this.pal, required this.onTap});

  final bool obscure;
  final OnbPalette pal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: obscure ? 'Show password' : 'Hide password',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
            child: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              key: ValueKey(obscure),
              size: 20,
              color: pal.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength, required this.pal});

  final int strength;
  final OnbPalette pal;

  static const _colors = [_danger, OnbPalette.ember, OnbPalette.gold, OnbPalette.teal];
  static const _labels = ['Too weak', 'Fair', 'Good', 'Strong'];

  @override
  Widget build(BuildContext context) {
    final color = strength == 0 ? pal.muted : _colors[strength - 1];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < strength ? color : pal.faint,
                  boxShadow: [
                    if (i < strength) BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
                  ],
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: 6),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                strength == 0 ? '6+ characters' : _labels[strength - 1],
                key: ValueKey(strength),
                maxLines: 1,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.text, required this.pal, required this.onTap});

  final String text;
  final OnbPalette pal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color.lerp(OnbPalette.goldBright, const Color(0xFFB36B00), pal.day),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.pal});

  final OnbPalette pal;

  @override
  Widget build(BuildContext context) {
    Widget line(bool reverse) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: reverse ? [pal.stroke, pal.stroke.withValues(alpha: 0)] : [pal.stroke.withValues(alpha: 0), pal.stroke],
              ),
            ),
          ),
        );
    return Row(
      children: [
        line(false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted),
          ),
        ),
        line(true),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.pal, required this.label, required this.glyph, required this.onTap});

  final OnbPalette pal;
  final String label;
  final Widget glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue with $label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [pal.glassStrong, pal.glass],
            ),
            border: Border.all(color: pal.stroke),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              glyph,
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: pal.text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold pill that collapses into a spinner, then a check, on submit.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.state, required this.time, required this.onTap});

  final String label;
  final _Submit state;
  final ValueListenable<double> time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final busy = state != _Submit.idle;
    return LayoutBuilder(builder: (context, c) {
      return Center(
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              width: busy ? 60 : c.maxWidth,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: state == _Submit.success
                      ? const [Color(0xFF6CF5C6), OnbPalette.teal]
                      : const [OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (state == _Submit.success ? OnbPalette.teal : OnbPalette.gold).withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: -2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!busy)
                      Positioned.fill(
                        child: TickBuilder(
                          valueListenable: time,
                          builder: (context, t, _) => CustomPaint(painter: _SheenPainter(time: t)),
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                      child: switch (state) {
                        _Submit.idle => OverflowBox(
                            key: ValueKey(label),
                            maxWidth: double.infinity,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: OnbPalette.ink),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(color: OnbPalette.ink, shape: BoxShape.circle),
                                  child: const Icon(Icons.arrow_forward_rounded, color: OnbPalette.goldBright, size: 18),
                                ),
                              ],
                            ),
                          ),
                        _Submit.loading => const SizedBox(
                            key: ValueKey('loading'),
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.6, color: OnbPalette.ink),
                          ),
                        _Submit.success => const Icon(
                            Icons.check_rounded,
                            key: ValueKey('success'),
                            color: OnbPalette.ink,
                            size: 30,
                          ),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final x = ((time * 0.4) % 1.6 - 0.3) * size.width;
    canvas.save();
    canvas.translate(x, size.height / 2);
    canvas.rotate(0.5);
    final band = Rect.fromCenter(center: Offset.zero, width: 60, height: size.height * 3);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter old) => old.time != time;
}
