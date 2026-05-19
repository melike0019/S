import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:stilya/screens/auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _linesController;

  @override
  void initState() {
    super.initState();
    // Flutter ilk frame'i çizdi → native splash kaldırılır, siyah ekran olmaz
    FlutterNativeSplash.remove();

    // Çizgilerin akma süresi: 2.5 saniye (Zarif ve akıcı)
    _linesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    // Toplam Splash Ekranı Süresi: 4600ms (Sonrasında yönlendirme)
    Future.delayed(const Duration(milliseconds: 4600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (ctx, anim, secAnim) => const AuthGate(),
            transitionsBuilder: (ctx, anim, secAnim, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _linesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ─── 1. AŞAMA: ÇİZGİLERİN AKMASI (0 - 2500 ms) ───
          AnimatedBuilder(
            animation: _linesController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: _NeonLinesPainter(progress: _linesController.value),
              );
            },
          ),

          // ─── 2. AŞAMA: S LOGOSUNUN BELİRMESİ VE ÇÖKMESİ ───
          Image.asset(
            'assets/images/neon_s_logo.png',
            width: size.width * 0.45,
          )
          // 1200ms: Çizgiler tam ortaya geldiğinde logo belirmeye başlar
          .animate(delay: 1200.ms) 
          .fadeIn(duration: 600.ms) 
          .shimmer(duration: 1000.ms, color: Colors.white54)
          // 2600ms (1200+600+800): Logo bir süre asılı kalır
          .then(delay: 800.ms) 
          // İçe çökme başlar ve 400ms sürer. (Toplam süre 3000ms'ye ulaştı)
          .scale(
            end: const Offset(0.0, 0.0), 
            duration: 400.ms,
            curve: Curves.easeInBack, 
          )
          .fadeOut(duration: 400.ms),

          // ─── 3. AŞAMA: STILYA YAZISININ PATLAMASI (3400 ms) ───
          // Logo tam çöktükten sonra (3000+400=3400ms) yazı çıkar, üst üste binme olmaz
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STILYA',
                style: GoogleFonts.syne(
                  fontSize: size.width * 0.12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 6.0,
                ),
              )
              .animate(delay: 3400.ms)
              .fadeIn(duration: 300.ms)
              .scale(
                begin: const Offset(0.2, 0.2),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
              ),

              const SizedBox(height: 12),

              Text(
                'stilin sana özgü',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: size.width * 0.045,
                  color: const Color(0xFF00E5FF),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              )
              // 3700ms: Slogan hemen ardından kayarak gelir
              .animate(delay: 3700.ms)
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.5, curve: Curves.easeOutCubic),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ÇİZGİ PAINTER ───
class _NeonLinesPainter extends CustomPainter {
  final double progress;
  _NeonLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return; 

    final center = Offset(size.width / 2, size.height / 2);
    final math.Random rng = math.Random(42); 
    
    final List<Color> colors = [
      const Color(0xFF00E5FF), 
      const Color(0xFFFF00FF), 
      const Color(0xFF7D00FF), 
    ];

    for (int i = 0; i < 40; i++) {
      final paint = Paint()
        // Çizgilerin soluklaşmasını geciktirdik ki logonun altında kaybolmasınlar
        ..color = colors[rng.nextInt(colors.length)].withValues(alpha: (1 - (progress * 1.2)).clamp(0.0, 1.0))
        ..strokeWidth = rng.nextDouble() * 2.0 + 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3); 

      final angle = rng.nextDouble() * 2 * math.pi;
      final radius = size.width * 1.2; 
      final startPoint = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      final controlPoint = Offset(
        center.dx + math.cos(angle + 1.5) * radius * 0.4,
        center.dy + math.sin(angle - 1.5) * radius * 0.4,
      );

      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, center.dx, center.dy);

      for (final metric in path.computeMetrics()) {
        final length = metric.length;
        final head = length * progress * 1.5; 
        final tail = head - (length * 0.3); 
        
        if (head > 0 && tail < length) {
          final extractPath = metric.extractPath(
            math.max(0.0, tail),
            math.min(length, head),
          );
          canvas.drawPath(extractPath, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}