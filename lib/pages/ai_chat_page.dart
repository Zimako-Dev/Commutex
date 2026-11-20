import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../nav.dart';
import '../services/claude_service.dart';
import '../services/saved_routes_service.dart';
import '../widgets/home/home_widgets.dart';
import '../widgets/onboarding/onboarding_scene.dart';
import '../widgets/kaya/kaya_widgets.dart';

class _Msg {
  _Msg({required this.role, required this.content, DateTime? time, this.failed = false, this.retryText, this.animate = false})
      : time = time ?? DateTime.now();

  final String role;
  final String content;
  final DateTime time;
  final bool failed;
  final String? retryText;
  bool animate;

  bool get isUser => role == 'user';
}

class _Starter {
  const _Starter(this.icon, this.color, this.title, this.prompt);

  final IconData icon;
  final Color color;
  final String title;
  final String prompt;
}

const _starters = [
  _Starter(Icons.payments_rounded, OnbPalette.gold, 'Check a fare', 'How much is a taxi from Bree to Soweto right now?'),
  _Starter(Icons.schedule_rounded, OnbPalette.ember, 'Beat the rush', 'When should I leave today to avoid the peak-hour surge?'),
  _Starter(Icons.shield_outlined, OnbPalette.teal, 'Ride safe', 'What are the best safety tips for minibus taxis at night?'),
  _Starter(Icons.savings_outlined, kayaViolet, 'Plan my budget', 'Help me plan a weekly transport budget for my regular trips.'),
];

/// Chat with Kaya, SmartTaxi's AI co-pilot.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with SingleTickerProviderStateMixin {
  final ClaudeService _ai = ClaudeService();
  final SavedRoutesService _saved = SavedRoutesService.instance;
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  final List<_Msg> _msgs = [];
  bool _loading = false;
  bool _personal = true;
  bool _atBottom = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6)..start();
    _saved.load();
    _saved.addListener(_refresh);
    _msgs.addAll(_ai.conversationHistory.map((m) => _Msg(role: m.role, content: m.content, time: m.timestamp)));
    _input.addListener(_refresh);
    _focus.addListener(_refresh);
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final atBottom = _scroll.position.maxScrollExtent - _scroll.offset < 80;
      if (atBottom != _atBottom) setState(() => _atBottom = atBottom);
    });
    if (_msgs.isNotEmpty) _scrollToBottom(jump: true);
  }

  @override
  void dispose() {
    _saved.removeListener(_refresh);
    _ticker.dispose();
    _time.dispose();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(max);
      } else {
        _scroll.animateTo(max, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      }
    });
  }

  /// Live facts Kaya gets with every question.
  String _context() {
    final now = DateTime.now();
    final rush = RushStatus.at(now);
    final b = StringBuffer()
      ..writeln(
        'Local time: ${DateFormat('EEEE HH:mm').format(now)}. '
        '${rush.peak ? 'It is peak hour (30% surge applies), ending in ${rush.countdown}.' : 'It is off-peak (standard fares); the next peak starts in ${rush.countdown}.'}',
      );
    if (_personal && _saved.items.isNotEmpty) {
      b.writeln("The rider's saved routes:");
      for (final r in _saved.items) {
        b.writeln(
          '- ${r.name}: ${r.from} to ${r.to}, about R${r.fare.toStringAsFixed(0)}, '
          '${r.durationMin} min, ${r.distanceKm.toStringAsFixed(1)} km, ridden ${r.useCount} times',
        );
      }
    }
    return b.toString();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _loading) return;
    _input.clear();
    HapticFeedback.lightImpact();
    setState(() {
      _msgs.add(_Msg(role: 'user', content: text));
      _loading = true;
    });
    _scrollToBottom();

    final reply = await _ai.sendMessage(text, context: _context());
    if (!mounted) return;
    final failed = _ai.lastFailed;
    if (!failed) HapticFeedback.selectionClick();
    setState(() {
      _loading = false;
      _msgs.add(_Msg(role: 'assistant', content: reply, failed: failed, retryText: failed ? text : null, animate: !failed));
    });
    _scrollToBottom();
  }

  void _retry(_Msg failed) {
    final text = failed.retryText;
    if (text == null) return;
    setState(() {
      final i = _msgs.indexOf(failed);
      _msgs.removeAt(i);
      if (i > 0 && _msgs[i - 1].isUser && _msgs[i - 1].content == text) _msgs.removeAt(i - 1);
    });
    _send(text);
  }

  void _regenerate() {
    if (_loading || _msgs.length < 2) return;
    final last = _msgs.last;
    final prev = _msgs[_msgs.length - 2];
    if (last.isUser || !prev.isUser) return;
    _ai.undoLastExchange();
    setState(() => _msgs.removeRange(_msgs.length - 2, _msgs.length));
    _send(prev.content);
  }

  void _newChat() {
    HapticFeedback.mediumImpact();
    _ai.clearHistory();
    setState(() => _msgs.clear());
  }

  void _toast(String message, {IconData icon = Icons.check_circle_outline_rounded}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1D1C22),
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x26FFFFFF))),
          content: Row(
            children: [
              Icon(icon, color: OnbPalette.gold, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white))),
            ],
          ),
        ),
      );
  }

  List<String> _followUps(String reply) {
    final r = reply.toLowerCase();
    if (r.contains('safe') || r.contains('valuable') || r.contains('night')) {
      return ['Where should I sit?', 'What if I feel unsafe?', 'Safest times to travel?'];
    }
    if (r.contains('budget') || r.contains('week') || r.contains('month')) {
      return ['How can I spend less?', 'Is a weekly pass worth it?', 'Budget for 5 work days'];
    }
    if (r.contains('peak') || r.contains('surge') || r.contains('rush')) {
      return ['How much does peak add?', 'Best time to leave?', 'Fare for Home → Work now?'];
    }
    if (r.contains('fare') || r.contains('r1') || r.contains('r2') || r.contains('rand') || r.contains('cost')) {
      return ['What about in peak hour?', 'Split it 3 ways', 'Is there a cheaper route?'];
    }
    if (r.contains('rank') || r.contains('route') || r.contains('stop')) {
      return ['How long will it take?', 'Which rank is closest?', 'Add a stop on the way'];
    }
    return ['Fare from Bree to Soweto?', 'When is peak hour?', 'Taxi safety tips'];
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: isLight ? 1 : 0),
      duration: const Duration(milliseconds: 700),
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
                Column(
                  children: [
                    _header(pal),
                    _contextStrip(pal),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _msgs.isEmpty ? _welcome(pal) : _thread(pal),
                      ),
                    ),
                    _composer(pal),
                  ],
                ),
                if (!_atBottom && _msgs.isNotEmpty)
                  Positioned(
                    right: 20,
                    bottom: 96 + MediaQuery.paddingOf(context).bottom,
                    child: GestureDetector(
                      onTap: () => _scrollToBottom(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pal.surface,
                          border: Border.all(color: pal.stroke),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12)],
                        ),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: pal.text),
                      ),
                    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.7, 0.7)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _circleButton(OnbPalette pal, IconData icon, String tip, VoidCallback onTap) => Semantics(
        button: true,
        label: tip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: pal.glass, border: Border.all(color: pal.stroke)),
            child: Icon(icon, size: 21, color: pal.text),
          ),
        ),
      );

  Widget _header(OnbPalette pal) {
    final (dot, status) = !_ai.isConfigured
        ? (pal.muted, 'Not connected')
        : _loading
            ? (kayaViolet, 'Thinking…')
            : (OnbPalette.teal, 'Online · your ride co-pilot');
    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 6),
      child: Row(
        children: [
          _circleButton(pal, Icons.arrow_back_rounded, 'Back', () => context.canPop() ? context.pop() : context.go(AppRoutes.home)),
          const SizedBox(width: 12),
          KayaOrb(size: 46, time: _time, thinking: _loading),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Kaya', style: GoogleFonts.outfit(fontSize: 21, fontWeight: FontWeight.w700, color: pal.text)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(colors: [kayaViolet, kayaPink]),
                      ),
                      child: Text('AI', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, color: pal.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _circleButton(pal, Icons.more_horiz_rounded, 'Chat options', _openOptions),
        ],
      ),
    );
  }

  Widget _contextStrip(OnbPalette pal) {
    final rush = RushStatus.at(DateTime.now());
    final count = _saved.items.length;
    Widget chip({required IconData icon, required String label, required Color color, bool on = true, VoidCallback? onTap, String? tip}) {
      return Semantics(
        button: onTap != null,
        label: tip,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: on ? color.withValues(alpha: 0.12) : pal.glass,
              border: Border.all(color: on ? color.withValues(alpha: 0.4) : pal.stroke),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: on ? color : pal.muted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: on ? pal.text : pal.muted,
                    decoration: on ? null : TextDecoration.lineThrough,
                    decorationColor: pal.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        children: [
          Center(
            child: Semantics(
              label: 'What Kaya knows right now',
              child: const Icon(Icons.auto_awesome_rounded, size: 16, color: kayaViolet),
            ),
          ),
          const SizedBox(width: 8),
          chip(
            icon: Icons.schedule_rounded,
            color: rush.peak ? OnbPalette.ember : OnbPalette.teal,
            label: rush.peak ? 'Peak now · ends in ${rush.countdown}' : 'Off-peak · peak in ${rush.countdown}',
          ),
          const SizedBox(width: 8),
          if (count > 0)
            chip(
              icon: _personal ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: kayaViolet,
              on: _personal,
              label: '$count routes',
              tip: _personal ? 'Stop sharing saved routes with Kaya' : 'Share saved routes with Kaya',
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _personal = !_personal);
                _toast(_personal ? 'Kaya can use your saved routes' : "Kaya won't see your saved routes",
                    icon: _personal ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded);
              },
            ),
        ],
      ),
    );
  }

  Widget _welcome(OnbPalette pal) {
    Widget enter(Widget w, int i) =>
        w.animate().fadeIn(delay: (120 + i * 80).ms, duration: 550.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic);
    final rush = RushStatus.at(DateTime.now());
    return LayoutBuilder(
      key: const ValueKey('welcome'),
      builder: (context, c) {
        final side = c.maxWidth > 600 ? (c.maxWidth - 560) / 2 : 20.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(side, 12, side, 16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Center(
              child: KayaOrb(size: 150, time: _time, thinking: _focus.hasFocus)
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), duration: 900.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),
            ),
            const SizedBox(height: 8),
            enter(
              Text.rich(
                TextSpan(
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1, height: 1.1, color: pal.text),
                  children: [
                    const TextSpan(text: "Sawubona! I'm "),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: ShaderMask(
                        shaderCallback: (r) => const LinearGradient(colors: [kayaViolet, kayaPink, OnbPalette.gold]).createShader(r),
                        child: Text(
                          'Kaya.',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              0,
            ),
            const SizedBox(height: 10),
            enter(
              Text(
                'Your ride co-pilot for fares, routes and staying safe. '
                "I can see it's ${rush.peak ? 'peak hour' : 'off-peak'} right now"
                '${_personal && _saved.items.isNotEmpty ? ' and I know your ${_saved.items.length} saved routes' : ''}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14.5, height: 1.55, color: pal.muted),
              ),
              1,
            ),
            if (!_ai.isConfigured) ...[
              const SizedBox(height: 16),
              enter(
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: pal.glass,
                    border: Border.all(color: pal.stroke),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.power_off_rounded, size: 18, color: pal.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Kaya isn't connected to an AI service in this build, so replies won't come through yet.",
                          style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: pal.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                2,
              ),
            ],
            const SizedBox(height: 22),
            for (var row = 0; row < 2; row++) ...[
              enter(
                SizedBox(
                  height: 138,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < 2; col++) ...[
                        if (col == 1) const SizedBox(width: 12),
                        Expanded(
                          child: KayaPromptCard(
                            pal: pal,
                            icon: _starters[row * 2 + col].icon,
                            color: _starters[row * 2 + col].color,
                            title: _starters[row * 2 + col].title,
                            prompt: _starters[row * 2 + col].prompt,
                            onTap: () => _send(_starters[row * 2 + col].prompt),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                3 + row,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 6),
            enter(
              Text(
                'Kaya can make mistakes. Confirm fares with your driver or at the rank.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted),
              ),
              5,
            ),
          ],
        );
      },
    );
  }

  Widget _thread(OnbPalette pal) {
    final lastAssistant = _msgs.isNotEmpty && !_msgs.last.isUser ? _msgs.last : null;
    final showFollowUps = !_loading && lastAssistant != null && !lastAssistant.failed && !lastAssistant.animate;
    final extra = (_loading ? 1 : 0) + (showFollowUps ? 1 : 0);
    return LayoutBuilder(
      key: const ValueKey('thread'),
      builder: (context, c) {
        final side = c.maxWidth > 600 ? (c.maxWidth - 560) / 2 : 16.0;
        final maxBubble = (c.maxWidth - side * 2) * 0.84;
        return ListView.builder(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(side, 8, side, 16),
          itemCount: _msgs.length + extra,
          itemBuilder: (context, i) {
            if (i < _msgs.length) {
              final m = _msgs[i];
              final showDay = i == 0 || !DateUtils.isSameDay(_msgs[i - 1].time, m.time);
              return Column(
                key: ObjectKey(m),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showDay) _dayDivider(pal, m.time),
                  m.isUser
                      ? _userBubble(pal, m, maxBubble)
                      : _assistantBubble(pal, m, maxBubble, isLast: m == lastAssistant),
                ],
              );
            }
            if (_loading && i == _msgs.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KayaOrb(size: 32, time: _time, thinking: true, glow: false),
                    const SizedBox(width: 10),
                    Flexible(child: KayaThinking(pal: pal, time: _time, personal: _personal && _saved.items.isNotEmpty)),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.2);
            }
            return Padding(
              padding: const EdgeInsets.only(left: 42, top: 2),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (k, f) in _followUps(lastAssistant!.content).indexed)
                    GestureDetector(
                      onTap: () => _send(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: kayaViolet.withValues(alpha: 0.1),
                          border: Border.all(color: kayaViolet.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: kayaViolet),
                            const SizedBox(width: 6),
                            Text(f, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: pal.text)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (80 * k).ms, duration: 300.ms).slideX(begin: 0.1),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dayDivider(OnbPalette pal, DateTime t) {
    final now = DateTime.now();
    final label = DateUtils.isSameDay(t, now)
        ? 'Today'
        : DateUtils.isSameDay(t, now.subtract(const Duration(days: 1)))
            ? 'Yesterday'
            : DateFormat('EEE, d MMM').format(t);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: pal.glass, borderRadius: BorderRadius.circular(99), border: Border.all(color: pal.stroke)),
          child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: pal.muted)),
        ),
      ),
    );
  }

  Widget _userBubble(OnbPalette pal, _Msg m, double maxW) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [OnbPalette.goldBright, OnbPalette.gold],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: SelectableText(
                m.content,
                style: GoogleFonts.inter(fontSize: 14.5, height: 1.45, fontWeight: FontWeight.w500, color: OnbPalette.ink),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(DateFormat('HH:mm').format(m.time), style: GoogleFonts.inter(fontSize: 10.5, color: pal.muted)),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.06, curve: Curves.easeOutCubic);
  }

  Widget _assistantBubble(OnbPalette pal, _Msg m, double maxW, {required bool isLast}) {
    final failed = m.failed;
    Widget body;
    if (m.animate) {
      body = TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: m.content.length),
        duration: Duration(milliseconds: (m.content.length * 11).clamp(300, 2400)),
        onEnd: () {
          m.animate = false;
          if (mounted) setState(() {});
          if (_atBottom) _scrollToBottom();
        },
        builder: (context, n, _) => KayaMarkdown(text: m.content.substring(0, n), pal: pal),
      );
    } else if (failed) {
      body = Text(m.content, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: pal.text));
    } else {
      body = KayaMarkdown(text: m.content, pal: pal);
    }

    Widget action(IconData icon, String tip, VoidCallback onTap) => Semantics(
          button: true,
          label: tip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 16, color: pal.muted),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KayaOrb(size: 32, time: _time, glow: false, still: true),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: failed
                          ? [homeDanger.withValues(alpha: 0.12), pal.glass]
                          : [pal.glassStrong, pal.glass],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: failed ? homeDanger.withValues(alpha: 0.5) : pal.stroke),
                  ),
                  child: failed
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 16, color: homeDanger),
                                const SizedBox(width: 6),
                                Text(
                                  _ai.isConfigured ? "Couldn't get a reply" : 'Kaya is offline',
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: homeDanger),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            body,
                            if (_ai.isConfigured && m.retryText != null) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _retry(m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    color: homeDanger.withValues(alpha: 0.15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.refresh_rounded, size: 15, color: homeDanger),
                                      const SizedBox(width: 6),
                                      Text('Try again', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: homeDanger)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : body,
                ),
                if (!failed && !m.animate)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 6),
                      Text(DateFormat('HH:mm').format(m.time), style: GoogleFonts.inter(fontSize: 10.5, color: pal.muted)),
                      const SizedBox(width: 4),
                      action(Icons.content_copy_rounded, 'Copy reply', () {
                        Clipboard.setData(ClipboardData(text: m.content));
                        HapticFeedback.selectionClick();
                        _toast('Reply copied');
                      }),
                      if (isLast && !_loading) action(Icons.refresh_rounded, 'Ask again for a new reply', _regenerate),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, curve: Curves.easeOutCubic);
  }

  Widget _composer(OnbPalette pal) {
    final canSend = _input.text.trim().isNotEmpty && !_loading;
    final focused = _focus.hasFocus;
    const none = InputBorder.none;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.scrim.withValues(alpha: 0), pal.scrim.withValues(alpha: 0.85)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _circleButton(pal, Icons.add_rounded, 'Quick tools', _openTools),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  constraints: const BoxConstraints(minHeight: 50),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: focused ? pal.glassStrong : pal.glass,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: focused ? kayaViolet.withValues(alpha: 0.7) : pal.stroke, width: focused ? 1.4 : 1),
                    boxShadow: [if (focused) BoxShadow(color: kayaViolet.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -4)],
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    cursorColor: kayaViolet,
                    style: GoogleFonts.inter(fontSize: 15, height: 1.4, color: pal.text),
                    decoration: InputDecoration(
                      hintText: 'Ask Kaya anything…',
                      hintStyle: GoogleFonts.inter(fontSize: 14.5, color: pal.muted),
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: none,
                      enabledBorder: none,
                      focusedBorder: none,
                      errorBorder: none,
                      focusedErrorBorder: none,
                      disabledBorder: none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Send message',
                enabled: canSend,
                child: GestureDetector(
                  onTap: canSend ? () => _send() : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: canSend ? const LinearGradient(colors: [kayaViolet, kayaPink, OnbPalette.gold]) : null,
                      color: canSend ? null : pal.glass,
                      border: Border.all(color: canSend ? Colors.transparent : pal.stroke),
                      boxShadow: [if (canSend) BoxShadow(color: kayaViolet.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6))],
                    ),
                    child: _loading
                        ? Padding(
                            padding: const EdgeInsets.all(15),
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: pal.muted),
                          )
                        : Icon(Icons.arrow_upward_rounded, color: canSend ? Colors.white : pal.muted, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheets ──────────────────────────────────────────────────────────────

  OnbPalette _palNow(BuildContext ctx) => OnbPalette(Theme.of(ctx).brightness == Brightness.light ? 1 : 0);

  Widget _sheet(BuildContext ctx, String title, List<Widget> rows) {
    final pal = _palNow(ctx);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFF17161B), const Color(0xFFFFFAF2), pal.day),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: pal.stroke),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: pal.faint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: pal.text)),
            const SizedBox(height: 6),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(BuildContext ctx, IconData icon, Color color, String title, String sub, VoidCallback onTap, {Widget? trailing}) {
    final pal = _palNow(ctx);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: color.withValues(alpha: 0.15)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: pal.text)),
                  Text(sub, style: GoogleFonts.inter(fontSize: 12, color: pal.muted)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: pal.muted),
          ],
        ),
      ),
    );
  }

  void _openTools() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _sheet(ctx, 'Quick tools', [
        _sheetRow(ctx, Icons.calculate_rounded, OnbPalette.gold, 'Fare estimator', 'Get an exact estimate for a trip', () {
          Navigator.pop(ctx);
          context.push(AppRoutes.calculator);
        }),
        _sheetRow(ctx, Icons.alt_route_rounded, OnbPalette.teal, 'Trip planner', 'Plan a journey with several stops', () {
          Navigator.pop(ctx);
          context.push(AppRoutes.tripPlanner);
        }),
        _sheetRow(ctx, Icons.bookmark_rounded, homeRose, 'Saved routes', 'Open your travel library', () {
          Navigator.pop(ctx);
          context.push(AppRoutes.saved);
        }),
      ]),
    );
  }

  void _openOptions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final pal = _palNow(ctx);
          return _sheet(ctx, 'Chat options', [
            _sheetRow(
              ctx,
              Icons.bookmark_rounded,
              kayaViolet,
              'Use my saved routes',
              'Share your saved routes with Kaya for personal answers',
              () {
                setState(() => _personal = !_personal);
                setSheet(() {});
              },
              trailing: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 46,
                height: 28,
                padding: const EdgeInsets.all(3),
                alignment: _personal ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: _personal ? kayaViolet : pal.faint),
                child: Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
              ),
            ),
            _sheetRow(ctx, Icons.add_comment_outlined, OnbPalette.gold, 'New chat', 'Clear this conversation and start fresh', () {
              Navigator.pop(ctx);
              if (_msgs.isNotEmpty) {
                _newChat();
                _toast('Started a new chat');
              }
            }),
          ]);
        },
      ),
    );
  }
}
