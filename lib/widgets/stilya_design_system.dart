import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class StilyaGradientShell extends StatelessWidget {
  final Widget child;
  final bool topGlow;
  final bool bottomGlow;

  const StilyaGradientShell({
    super.key,
    required this.child,
    this.topGlow = true,
    this.bottomGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _StilyaTexturePainter())),
        if (topGlow)
          Positioned(
            top: -96,
            right: -76,
            child: _AtmosphericGlow(
              size: 260,
              colors: [
                AppTheme.blush.withValues(alpha: 0.46),
                AppTheme.lilac.withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ),
          ),
        if (bottomGlow)
          Positioned(
            bottom: -92,
            left: -84,
            child: _AtmosphericGlow(
              size: 250,
              colors: [
                AppTheme.softGold.withValues(alpha: 0.44),
                AppTheme.softLavender.withValues(alpha: 0.22),
                Colors.transparent,
              ],
            ),
          ),
        child,
      ],
    );
  }
}

class StilyaGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const StilyaGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceMD),
    this.radius = AppTheme.radiusXL,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
              width: 1,
            ),
            boxShadow: AppTheme.glassShadow,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return StilyaPressable(onTap: onTap, child: card);
  }
}

class StilyaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const StilyaAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + 18 + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 74,
      actions: actions,
      bottom: bottom,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF8EF),
              Color(0xFFF9D7E4),
              Color(0xFFE9DEF7),
              Color(0xFFE7F0E8),
            ],
            stops: [0.0, 0.38, 0.72, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -54,
              right: -34,
              child: _AtmosphericGlow(
                size: 180,
                colors: [
                  AppTheme.primaryRose.withValues(alpha: 0.16),
                  AppTheme.gold.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
            Positioned(
              bottom: -58,
              left: -36,
              child: _AtmosphericGlow(
                size: 156,
                colors: [
                  AppTheme.sage.withValues(alpha: 0.18),
                  AppTheme.lavender.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _StilyaTexturePainter()),
            ),
          ],
        ),
      ),
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              boxShadow: AppTheme.softShadow,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    height: 1.08,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: AppTheme.textDark),
      actionsIconTheme: const IconThemeData(color: AppTheme.primaryRose),
    );
  }
}

class StilyaEditorialHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final double height;

  const StilyaEditorialHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppTheme.editorialGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius2XL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StilyaTexturePainter())),
          Positioned(
            right: -34,
            top: -26,
            child: Transform.rotate(
              angle: -0.16,
              child: Container(
                width: 154,
                height: 154,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(44),
                  color: Colors.white.withValues(alpha: 0.34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.54),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 22,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.sage.withValues(alpha: 0.42),
                    AppTheme.lavender.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      eyebrow.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textLight,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const Spacer(),
                    ?trailing,
                  ],
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.45,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StilyaLoader extends StatelessWidget {
  final String label;

  const StilyaLoader({super.key, this.label = 'Hazırlanıyor'});

  @override
  Widget build(BuildContext context) {
    return StilyaGradientShell(
      child: Center(
        child: StilyaGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryRose,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StilyaPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const StilyaPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<StilyaPressable> createState() => _StilyaPressableState();
}

class _StilyaPressableState extends State<StilyaPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _AtmosphericGlow extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _AtmosphericGlow({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _StilyaTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppTheme.primaryRose.withValues(alpha: 0.055);

    for (var i = -1; i < 5; i++) {
      final y = size.height * (0.18 + i * 0.18);
      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(
          size.width * 0.25,
          y - 42,
          size.width * 0.62,
          y + 46,
          size.width + 24,
          y - 12,
        );
      canvas.drawPath(path, linePaint);
    }

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.gold.withValues(alpha: 0.08);
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.12 + (i % 3) * 0.29),
          size.height * (0.20 + (i ~/ 3) * 0.26),
        ),
        2.2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
