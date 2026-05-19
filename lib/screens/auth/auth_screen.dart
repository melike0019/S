import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _submitting = false;
  bool _obscurePassword = true;
  String? _localError;
  DateTime? _birthDate;

  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final Animation<double> _cardFade;
  late final Animation<double> _cardRise;
  late final Animation<double> _bgShift;

  String _birthDateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    _bgShift = Tween(begin: 0.0, end: 1.0).animate(_bgCtrl);
    _bgCtrl.repeat(reverse: true);

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _cardFade = CurvedAnimation(
      parent: _cardCtrl,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _cardRise = CurvedAnimation(
      parent: _cardCtrl,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: 40.0, end: 0.0));
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _cardCtrl.reset();
    setState(() {
      _isLogin = !_isLogin;
      _localError = null;
      _birthDate = null;
    });
    _cardCtrl.forward();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 21, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now)
          ? DateTime(now.year - 21, now.month, now.day)
          : initial,
      firstDate: DateTime(1920, 1, 1),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppTheme.primaryRose),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _birthDate = DateTime(picked.year, picked.month, picked.day),
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _localError = null;
      _submitting = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _localError = 'E-posta ve şifre gereklidir.';
        _submitting = false;
      });
      return;
    }

    bool ok;
    if (_isLogin) {
      ok = await auth.signIn(email: email, password: password);
    } else {
      if (name.isEmpty) {
        setState(() {
          _localError = 'İsim gereklidir.';
          _submitting = false;
        });
        return;
      }
      if (_birthDate == null) {
        setState(() {
          _localError = 'Kayıt için doğum tarihini seçmen gerekiyor.';
          _submitting = false;
        });
        return;
      }
      ok = await auth.signUp(
        email: email,
        password: password,
        displayName: name,
        birthDate: DateTime(
          _birthDate!.year,
          _birthDate!.month,
          _birthDate!.day,
        ),
      );
    }

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _localError = auth.errorMessage ?? 'İşlem başarısız oldu.';
        _submitting = false;
      });
      return;
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _bgShift,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color(0xFFFFF8EF),
                Color(0xFFF8D8E6),
                Color(0xFFEDE2F8),
                Color(0xFFE7F0E8),
                Color(0xFFFFFAF7),
              ],
              stops: const [0.0, 0.26, 0.56, 0.82, 1.0],
              begin: Alignment(-0.5 + _bgShift.value * 0.3, -1.0),
              end: Alignment(0.5 + _bgShift.value * 0.2, 1.0),
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -size.width * 0.3,
                left: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryRose.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.08,
                right: -size.width * 0.25,
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.sage.withValues(alpha: 0.10),
                  ),
                ),
              ),

              // Content
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        size.height - MediaQuery.of(context).padding.vertical,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.06),
                      _buildHeader(size),
                      SizedBox(height: size.height * 0.04),
                      AnimatedBuilder(
                        animation: _cardCtrl,
                        builder: (_, child) => Opacity(
                          opacity: _cardFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _cardRise.value),
                            child: child,
                          ),
                        ),
                        child: _buildFormCard(auth, size),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Column(
      children: [
        // Logo with glow
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0x40FFFFFF), Color(0x18FFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryRose.withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.textDark, AppTheme.primaryRose],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'S',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryRose,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'STILYA',
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Stilin, Sana Özgü',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: AppTheme.textMedium,
            letterSpacing: 2.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AuthProvider auth, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppTheme.radius2XL),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkRose.withValues(alpha: 0.25),
              blurRadius: 60,
              offset: const Offset(0, 24),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab switcher
            _buildTabSwitcher(),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isLogin) ...[
                          _buildField(
                            controller: _nameController,
                            label: 'İsim',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                          _buildBirthDateField(),
                          const SizedBox(height: 14),
                        ],
                        _buildField(
                          controller: _emailController,
                          label: 'E-posta',
                          icon: Icons.mail_outline_rounded,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(),
                      ],
                    ),
                  ),

                  // Error banner
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: _localError != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: _buildErrorBanner(_localError!),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 22),

                  // Submit button
                  _buildSubmitButton(auth),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildGoogleButton(auth),

                  if (_isLogin) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _submitting ? null : _showForgotPassword,
                        child: Text(
                          'Şifremi Unuttum',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textLight,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.textFaint,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 6),

                  // Switch mode
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.dividerColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: _submitting ? null : _toggleMode,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textMedium,
                            ),
                            children: [
                              TextSpan(
                                text: _isLogin
                                    ? 'Hesabın yok mu? '
                                    : 'Zaten üye misin? ',
                              ),
                              TextSpan(
                                text: _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryRose,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.bgMid,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRose.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isLogin ? null : _toggleMode,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Giriş Yap',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: _isLogin
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _isLogin
                            ? AppTheme.primaryRose
                            : AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: !_isLogin ? null : _toggleMode,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Kayıt Ol',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: !_isLogin
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: !_isLogin
                            ? AppTheme.primaryRose
                            : AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateField() {
    final label = _birthDate == null
        ? 'Doğum tarihini seç'
        : _birthDateLabel(_birthDate!);
    return GestureDetector(
      onTap: _submitting ? null : _pickBirthDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgMid.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppTheme.textLight,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _birthDate == null
                    ? AppTheme.textFaint
                    : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: 'Şifre',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: AppTheme.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCE8F0), Color(0xFFFFF0F5)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthProvider auth) {
    final loading = _submitting || auth.isLoading;
    return PremiumButton(
      label: _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
      loading: loading,
      onPressed: loading ? null : _submit,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.dividerColor.withValues(alpha: 0.5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'veya',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.dividerColor.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildGoogleButton(AuthProvider auth) {
    final loading = _submitting || auth.isLoading;
    return GestureDetector(
      onTap: loading
          ? null
          : () async {
              setState(() {
                _localError = null;
                _submitting = true;
              });
              final ok = await auth.signInWithGoogle();
              if (!mounted) return;
              if (!ok && auth.errorMessage != null) {
                setState(() => _localError = auth.errorMessage);
              }
              setState(() => _submitting = false);
            },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleIcon(),
            const SizedBox(width: 12),
            Text(
              'Google ile devam et',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radius2XL),
          ),
          boxShadow: AppTheme.strongShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Şifreyi Sıfırla',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'E-posta adresine sıfırlama bağlantısı gönderilecek.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textDark,
              ),
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 20),
            PremiumButton(
              label: 'Sıfırlama Bağlantısı Gönder',
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(ctx);
                final ok = await context.read<AuthProvider>().resetPassword(
                  email,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Sıfırlama bağlantısı gönderildi.'
                          : 'Bir hata oluştu.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium Button (imported from theme or defined here) ────────────────────
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
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
      duration: const Duration(milliseconds: 100),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.loading
                ? null
                : const LinearGradient(
                    colors: [
                      AppTheme.deepRose,
                      AppTheme.primaryRose,
                      Color(0xFFD4809A),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
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

// ─── Google Icon ──────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final cx = r;
    final cy = r;
    const sw = 3.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r - sw / 2),
      -0.25,
      1.6,
      false,
      paint,
    );
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r - sw / 2),
      1.35,
      0.85,
      false,
      paint,
    );
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r - sw / 2),
      2.2,
      0.65,
      false,
      paint,
    );
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r - sw / 2),
      2.85,
      0.65,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
