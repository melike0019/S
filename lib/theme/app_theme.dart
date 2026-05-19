import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Core Brand Palette ───────────────────────────────────────────────────
  static const Color primaryRose = Color(0xFFC95F82);
  static const Color darkRose = Color(0xFF9C4F70);
  static const Color lightRose = Color(0xFFF8D8E6);
  static const Color deepRose = Color(0xFF5A243A);
  static const Color gold = Color(0xFFD8B874);
  static const Color softGold = Color(0xFFF7EBD2);
  static const Color lavender = Color(0xFFA98FD0);
  static const Color softLavender = Color(0xFFF0E9FB);
  static const Color lilac = Color(0xFFD7C4EE);
  static const Color mauve = Color(0xFF8D6C88);
  static const Color blush = Color(0xFFF6C6D3);
  static const Color cream = Color(0xFFFFF8EF);
  static const Color sage = Color(0xFF9DBBA6);
  static const Color powderBlue = Color(0xFFAFC7E8);
  static const Color peach = Color(0xFFF1B79D);

  // ─── Background System ────────────────────────────────────────────────────
  static const Color bgStart = Color(0xFFFFFAF7);
  static const Color bgMid = Color(0xFFFFF1F6);
  static const Color bgEnd = Color(0xFFF3ECFA);
  static const Color bgDeep = Color(0xFFEDE7F4);

  // ─── Text Colors ─────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF2C1A24);
  static const Color textMedium = Color(0xFF7B5A68);
  static const Color textLight = Color(0xFFA98293);
  static const Color textFaint = Color(0xFFC9AAB9);

  // ─── Surface Colors ───────────────────────────────────────────────────────
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color glassWhite = Color(0xCCFFFFFF);
  static const Color glassFrosted = Color(0xAAFFF5FA);
  static const Color dividerColor = Color(0xFFEFD7E4);
  static const Color errorRed = Color(0xFFCC3055);

  // ─── Gradient Definitions ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8F4164), primaryRose, Color(0xFFEAA3B4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFEAA3B4), primaryRose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [bgStart, Color(0xFFFFF5EF), bgMid, bgEnd],
    stops: [0.0, 0.36, 0.70, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient deepBackgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFAF7), Color(0xFFF9EAF2), Color(0xFFEFE8FA)],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient editorialGradient = LinearGradient(
    colors: [
      Color(0xFFFFF8EF),
      Color(0xFFF8D8E6),
      Color(0xFFEDE2F8),
      Color(0xFFE7F0E8),
    ],
    stops: [0.0, 0.38, 0.72, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC8A46A), Color(0xFFE4C890), Color(0xFFC8A46A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lavenderGradient = LinearGradient(
    colors: [Color(0xFF9870AA), Color(0xFFB8A0CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x88FFF5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient blushRadial = RadialGradient(
    colors: [Color(0x30F2C4CE), Color(0x00F2C4CE)],
    radius: 1.0,
  );

  static const RadialGradient lavenderRadial = RadialGradient(
    colors: [Color(0x28B8A0CC), Color(0x00B8A0CC)],
    radius: 1.0,
  );

  // ─── Shadow System ────────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryRose.withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: primaryRose.withValues(alpha: 0.18),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: darkRose.withValues(alpha: 0.25),
      blurRadius: 48,
      offset: const Offset(0, 20),
    ),
    BoxShadow(
      color: primaryRose.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get glassShadow => [
    BoxShadow(
      color: primaryRose.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.8),
      blurRadius: 2,
      offset: const Offset(0, -1),
    ),
  ];

  static List<BoxShadow> get navShadow => [
    BoxShadow(
      color: darkRose.withValues(alpha: 0.15),
      blurRadius: 40,
      offset: const Offset(0, -8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, -2),
    ),
  ];

  // ─── Border Radius System ─────────────────────────────────────────────────
  static const double radiusXS = 8.0;
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  static const double radiusXL = 24.0;
  static const double radius2XL = 32.0;
  static const double radiusFull = 999.0;

  // ─── Spacing System ───────────────────────────────────────────────────────
  static const double spaceXXS = 4.0;
  static const double spaceXS = 8.0;
  static const double spaceSM = 12.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double space2XL = 48.0;
  static const double space3XL = 64.0;

  // ─── Glassmorphism Container Helper ──────────────────────────────────────
  static BoxDecoration glassDecoration({
    double opacity = 0.75,
    double borderOpacity = 0.4,
    double radius = radiusXL,
    Color? tint,
  }) {
    final base = tint ?? Colors.white;
    return BoxDecoration(
      color: base.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: base.withValues(alpha: borderOpacity), width: 1.0),
      boxShadow: glassShadow,
    );
  }

  static BoxDecoration premiumCardDecoration({
    double radius = radiusXL,
    bool withBorder = true,
  }) => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: withBorder
        ? Border.all(color: dividerColor.withValues(alpha: 0.6), width: 1.0)
        : null,
    boxShadow: softShadow,
  );

  // ─── Full Light Theme ─────────────────────────────────────────────────────
  static ThemeData get light {
    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: textDark,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: textDark,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textDark,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textDark,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.35,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textMedium,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textDark,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textMedium,
        height: 1.55,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textLight,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: cardBg,
        letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMedium,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textLight,
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _StilyaPageTransitionsBuilder(),
          TargetPlatform.iOS: _StilyaPageTransitionsBuilder(),
          TargetPlatform.macOS: _StilyaPageTransitionsBuilder(),
          TargetPlatform.windows: _StilyaPageTransitionsBuilder(),
          TargetPlatform.linux: _StilyaPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryRose,
        onPrimary: Colors.white,
        primaryContainer: lightRose,
        onPrimaryContainer: darkRose,
        secondary: gold,
        onSecondary: Colors.white,
        secondaryContainer: softGold,
        onSecondaryContainer: const Color(0xFF7A5A20),
        tertiary: lavender,
        onTertiary: Colors.white,
        tertiaryContainer: softLavender,
        onTertiaryContainer: mauve,
        error: errorRed,
        onError: Colors.white,
        errorContainer: const Color(0xFFFCE4EC),
        onErrorContainer: const Color(0xFF8B1040),
        surface: cardBg,
        onSurface: textDark,
        surfaceContainerHighest: bgMid,
        onSurfaceVariant: textMedium,
        outline: dividerColor,
        outlineVariant: dividerColor.withValues(alpha: 0.5),
        shadow: Colors.black12,
        scrim: Colors.black54,
        inverseSurface: textDark,
        onInverseSurface: Colors.white,
        inversePrimary: lightRose,
      ),
      scaffoldBackgroundColor: bgStart,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark, size: 22),
        actionsIconTheme: const IconThemeData(color: primaryRose, size: 22),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          side: BorderSide(color: dividerColor.withValues(alpha: 0.6), width: 1),
        ),
        shadowColor: primaryRose.withValues(alpha: 0.1),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgEnd,
        selectedColor: primaryRose,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide(color: dividerColor.withValues(alpha: 0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRose,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryRose,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRose,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primaryRose, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRose,
          textStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgMid.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: dividerColor.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: dividerColor.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primaryRose, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: errorRed),
        ),
        labelStyle: GoogleFonts.poppins(color: textLight, fontSize: 13),
        hintStyle: GoogleFonts.poppins(color: textFaint, fontSize: 13),
        prefixIconColor: textLight,
        suffixIconColor: textLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        floatingLabelStyle: GoogleFonts.poppins(
          color: primaryRose,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRose,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: primaryRose,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: textLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryRose, size: 23);
          }
          return const IconThemeData(color: textLight, size: 22);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius2XL)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryRose,
        inactiveTrackColor: lightRose,
        thumbColor: primaryRose,
        overlayColor: primaryRose.withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
    );
  }
}

// ─── Reusable Design Components ───────────────────────────────────────────────

/// Premium gradient button with animation
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double? width;
  final double height;
  final Gradient? gradient;
  final IconData? icon;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.width,
    this.height = 54,
    this.gradient,
    this.icon,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _ctrl.forward() : null,
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.loading
                ? null
                : (widget.gradient ?? AppTheme.primaryGradient),
            color: widget.loading ? AppTheme.lightRose : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: widget.loading ? [] : AppTheme.mediumShadow,
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryRose,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Decorative blob background widget
class BlobBackground extends StatelessWidget {
  final Widget child;
  final bool showTopBlob;
  final bool showBottomBlob;

  const BlobBackground({
    super.key,
    required this.child,
    this.showTopBlob = true,
    this.showBottomBlob = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
        ),
        if (showTopBlob)
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.blushRadial,
              ),
            ),
          ),
        if (showBottomBlob)
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.lavenderRadial,
              ),
            ),
          ),
        child,
      ],
    );
  }
}

/// Skeleton loading shimmer
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppTheme.radiusSM,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat();
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
      builder: (_, x) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFFEDD8E8),
              Color(0xFFF8EEF5),
              Color(0xFFEDD8E8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StilyaPageTransitionsBuilder extends PageTransitionsBuilder {
  const _StilyaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.035, 0.018),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
