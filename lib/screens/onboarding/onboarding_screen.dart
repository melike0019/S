import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';

const String _kOnboardingDone = 'onboarding_done';

Future<bool> isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

// ─── Slide veri modeli ────────────────────────────────────────────────────────
class _Slide {
  final String title;
  final String subtitle;
  final String caption;
  final List<Color> gradient;
  final Color accentColor;
  final _IllustrationType illustration;

  const _Slide({
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.gradient,
    required this.accentColor,
    required this.illustration,
  });
}

enum _IllustrationType { wardrobe, outfit, planner }

// ─── Onboarding Screen ────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const OnboardingScreen({super.key, this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<double> _entryRise;

  static const _slides = [
    _Slide(
      title: 'Dijital Gardırobun',
      subtitle: 'Tüm kıyafetlerini tek bir yerde topla.',
      caption: 'Fotoğrafla ekle, kategorile ve kolayca bul. Gardırobun sana göre akıllıca düzenlensin.',
      gradient: [Color(0xFF6B2040), Color(0xFFBF607A), Color(0xFFE8A0BB)],
      accentColor: Color(0xFFBF607A),
      illustration: _IllustrationType.wardrobe,
    ),
    _Slide(
      title: 'AI Kombin Önerileri',
      subtitle: 'Sana özel, akıllı stil önerileri.',
      caption: 'Hava durumu, ruh hali ve etkinliğe göre kişiselleştirilmiş kombinler — her gün harika hissettir.',
      gradient: [Color(0xFF5A2870), Color(0xFF9870AA), Color(0xFFD4B8E0)],
      accentColor: Color(0xFF9870AA),
      illustration: _IllustrationType.outfit,
    ),
    _Slide(
      title: 'Stilini Planla',
      subtitle: 'Haftanı önceden organize et.',
      caption: 'Ajandan ile kıyafet planı oluştur, kombini takip et ve stilini bir adım öteye taşı.',
      gradient: [Color(0xFF3A4A6A), Color(0xFF6A80B8), Color(0xFFB0C0E0)],
      accentColor: Color(0xFF6A80B8),
      illustration: _IllustrationType.planner,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _entryRise = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: 30.0, end: 0.0));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (mounted) widget.onDone?.call();
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _entryCtrl.reset();
    _entryCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final slide = _slides[_page];

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ──────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Decorative geometric shapes ───────────────────────────────
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.25,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.1,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // ── PageView (illustrations) ──────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _slides.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) => _buildIllustrationArea(_slides[i], size),
          ),

          // ── Content card (bottom) ─────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildContentCard(slide, size),
          ),

          // ── Skip button ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: TextButton(
              onPressed: _finish,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Atla',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),

          // ── Page indicator (top left) ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 22,
            left: 24,
            child: Row(
              children: List.generate(_slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(right: 6),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationArea(_Slide slide, Size size) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: size.height * 0.42,
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _entryCtrl,
          builder: (_, x) => Opacity(
            opacity: _entryFade.value,
            child: Transform.translate(
              offset: Offset(0, _entryRise.value * 0.5),
              child: _OnboardingIllustration(
                type: slide.illustration,
                color: slide.accentColor,
                size: math.min(size.width * 0.6, 220),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(_Slide slide, Size size) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          32, 32, 32,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: slide.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, x) => Opacity(
                opacity: _entryFade.value,
                child: Transform.translate(
                  offset: Offset(0, _entryRise.value),
                  child: Text(
                    slide.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, x) => Opacity(
                opacity: (_entryFade.value * 0.9).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, _entryRise.value * 1.2),
                  child: Text(
                    slide.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: slide.accentColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Caption
            AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, x) => Opacity(
                opacity: (_entryFade.value * 0.8).clamp(0.0, 1.0),
                child: Text(
                  slide.caption,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                    height: 1.65,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Next / Start button
            _AnimatedNextButton(
              isLast: _page == _slides.length - 1,
              accentColor: slide.accentColor,
              onTap: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated Next Button ─────────────────────────────────────────────────────
class _AnimatedNextButton extends StatefulWidget {
  final bool isLast;
  final Color accentColor;
  final VoidCallback onTap;

  const _AnimatedNextButton({
    required this.isLast,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_AnimatedNextButton> createState() => _AnimatedNextButtonState();
}

class _AnimatedNextButtonState extends State<_AnimatedNextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, x) => Transform.scale(
          scale: _scale.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.accentColor.withValues(alpha: 0.9),
                  widget.accentColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Row(
                  key: ValueKey(widget.isLast),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.isLast ? 'Hadi Başlayalım' : 'Devam Et',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      widget.isLast
                          ? Icons.auto_awesome_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Onboarding Illustrations (Custom Painted) ────────────────────────────────
class _OnboardingIllustration extends StatefulWidget {
  final _IllustrationType type;
  final Color color;
  final double size;

  const _OnboardingIllustration({
    required this.type,
    required this.color,
    required this.size,
  });

  @override
  State<_OnboardingIllustration> createState() =>
      _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<_OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));
    _float = Tween(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _floatCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: child,
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _IllustrationPainter(
            type: widget.type,
            color: widget.color,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final _IllustrationType type;
  final Color color;

  const _IllustrationPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case _IllustrationType.wardrobe:
        _drawWardrobe(canvas, size);
        break;
      case _IllustrationType.outfit:
        _drawOutfit(canvas, size);
        break;
      case _IllustrationType.planner:
        _drawPlanner(canvas, size);
        break;
    }
  }

  void _drawWardrobe(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.28;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Hanger
    final hangerPath = Path()
      ..moveTo(cx - s * 0.8, cy - s * 0.1)
      ..lineTo(cx - s * 0.1, cy - s * 0.1)
      ..arcToPoint(
        Offset(cx + s * 0.1, cy - s * 0.1),
        radius: const Radius.circular(10),
        clockwise: false,
      )
      ..lineTo(cx + s * 0.8, cy - s * 0.1);
    canvas.drawPath(hangerPath, paint);

    // Hook
    final hookPath = Path()
      ..moveTo(cx, cy - s * 0.1)
      ..lineTo(cx, cy - s * 0.5)
      ..arcToPoint(
        Offset(cx + s * 0.2, cy - s * 0.6),
        radius: const Radius.circular(15),
        clockwise: false,
      );
    canvas.drawPath(hookPath, paint);

    // Dress body
    final dressPath = Path()
      ..moveTo(cx - s * 0.8, cy - s * 0.1)
      ..lineTo(cx - s * 1.0, cy + s * 0.9)
      ..lineTo(cx + s * 1.0, cy + s * 0.9)
      ..lineTo(cx + s * 0.8, cy - s * 0.1)
      ..close();
    canvas.drawPath(dressPath, fillPaint);
    canvas.drawPath(dressPath, paint);

    // Collar detail
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + s * 0.1), width: s * 0.8, height: s * 0.4),
      math.pi, math.pi, false, paint,
    );
  }

  void _drawOutfit(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.25;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Stars/sparkles
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * math.pi * 2 + math.pi / 8;
      final r = s * 1.3;
      final starX = cx + r * math.cos(angle);
      final starY = cy + r * math.sin(angle);
      _drawStar(canvas, Offset(starX, starY), s * 0.1, paint);
    }

    // AI circle
    canvas.drawCircle(Offset(cx, cy), s * 0.75,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), s * 0.75, paint);

    // Shirt shape inside
    final shirtPath = Path()
      ..moveTo(cx - s * 0.4, cy - s * 0.5)
      ..lineTo(cx - s * 0.6, cy - s * 0.3)
      ..lineTo(cx - s * 0.5, cy + s * 0.5)
      ..lineTo(cx + s * 0.5, cy + s * 0.5)
      ..lineTo(cx + s * 0.6, cy - s * 0.3)
      ..lineTo(cx + s * 0.4, cy - s * 0.5)
      ..quadraticBezierTo(cx, cy - s * 0.7, cx - s * 0.4, cy - s * 0.5);
    canvas.drawPath(shirtPath, fillPaint);
    canvas.drawPath(shirtPath, paint);
  }

  void _drawPlanner(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.28;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Calendar body
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + s * 0.1), width: s * 2.2, height: s * 2.0),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, paint);

    // Header
    canvas.drawLine(
      Offset(cx - s * 1.1, cy - s * 0.55),
      Offset(cx + s * 1.1, cy - s * 0.55),
      paint,
    );

    // Binding rings
    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(cx + i * s * 0.55, cy - s * 0.55),
        s * 0.12,
        paint,
      );
    }

    // Grid dots
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 4; col++) {
        final x = cx - s * 0.75 + col * s * 0.5;
        final y = cy + s * 0.02 + row * s * 0.55;
        canvas.drawCircle(
          Offset(x, y),
          s * 0.07,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Checkmark on first item
    final checkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx - s * 0.75, cy + s * 0.1),
        Offset(cx - s * 0.55, cy + s * 0.28),
        checkPaint);
    canvas.drawLine(
        Offset(cx - s * 0.55, cy + s * 0.28),
        Offset(cx - s * 0.25, cy - s * 0.05),
        checkPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * math.pi * 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) =>
      old.type != type || old.color != color;
}
