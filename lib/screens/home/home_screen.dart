import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'dart:async';
import '../../models/clothing_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/badge_checker.dart';
import 'ai_chat_screen.dart';

// ─── Sabit veriler ─────────────────────────────────────────────────────────
const List<Map<String, String>> _moods = [
  {'label': 'Enerjik', 'emoji': '⚡'},
  {'label': 'Özgüvenli', 'emoji': '✨'},
  {'label': 'Sakin', 'emoji': '🌿'},
  {'label': 'Romantik', 'emoji': '🌸'},
  {'label': 'Yaratıcı', 'emoji': '🎨'},
  {'label': 'Stresli', 'emoji': '😤'},
];

const List<Map<String, String>> _occasions = [
  {'label': 'Günlük', 'emoji': '☀️'},
  {'label': 'İş / Toplantı', 'emoji': '💼'},
  {'label': 'Brunch', 'emoji': '🥂'},
  {'label': 'Spor', 'emoji': '🏃'},
  {'label': 'Gece Çıkışı', 'emoji': '🌙'},
  {'label': 'Ev', 'emoji': '🏠'},
];

const Map<String, IconData> _weatherIcons = {
  'Clear': Icons.wb_sunny_rounded,
  'Clouds': Icons.cloud_rounded,
  'Rain': Icons.umbrella_rounded,
  'Drizzle': Icons.grain,
  'Thunderstorm': Icons.thunderstorm_rounded,
  'Snow': Icons.ac_unit_rounded,
  'Mist': Icons.blur_on_rounded,
  'Fog': Icons.blur_on_rounded,
  'Haze': Icons.blur_on_rounded,
};

// ─── HomeScreen ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMood = 'Enerjik';
  String _selectedOccasion = 'Günlük';

  final TextEditingController _customOutfitDetailController =
      TextEditingController();

  List<OutfitSuggestion>? _suggestions;
  bool _isSuggesting = false;
  String? _suggestionError;

  /// Makyaj + cilt bakımı bloklarını AI ve kartta göster.
  bool _includeMakeupSkincare = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchWeather();
    });
  }

  @override
  void dispose() {
    _customOutfitDetailController.dispose();
    super.dispose();
  }

  Future<void> _getSuggestion() async {
    final clothing = context.read<ClothingProvider>();
    final weatherProv = context.read<WeatherProvider>();

    if (clothing.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce Gardırop sekmesinden kıyafet ekle!'),
        ),
      );
      return;
    }
    if (!weatherProv.hasWeather) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hava durumu henüz yüklenmedi.')),
      );
      return;
    }

    setState(() {
      _isSuggesting = true;
      _suggestions = null;
      _suggestionError = null;
    });

    try {
      final zodiac = context.read<AuthProvider>().user?.zodiacSign;
      final extra = _customOutfitDetailController.text.trim();
      final results = await context.read<AIService>().getOutfitSuggestion(
        items: clothing.items,
        weather: weatherProv.weather!,
        mood: _selectedMood,
        occasion: _selectedOccasion,
        zodiacSign: zodiac,
        customPrompt: extra.isEmpty ? null : extra,
        includeMakeupSkincare: _includeMakeupSkincare,
      );
      if (mounted) setState(() => _suggestions = results);
    } catch (e) {
      if (mounted) setState(() => _suggestionError = e.toString());
    } finally {
      if (mounted) setState(() => _isSuggesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final dn = user?.displayName;
    final name = (dn != null && dn.isNotEmpty)
        ? dn.split(' ').first
        : (user?.email ?? 'Kullanıcı');
    final zodiacLabel = user?.zodiacSign?.trim();
    final weather = context.watch<WeatherProvider>();
    final clothing = context.watch<ClothingProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: (zodiacLabel != null && zodiacLabel.isNotEmpty)
                ? 172
                : 148,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.bgStart,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.editorialGradient,
                    ),
                    child: CustomPaint(painter: _HomeMoodPainter()),
                  ),
                  // Decorative circle
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryRose.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.sage.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  // Content
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Merhaba, $name ✨',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.7),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bugün nasıl bir stil yaratmak istersin?',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: AppTheme.textMedium,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (zodiacLabel != null && zodiacLabel.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.58),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryRose.withValues(
                                  alpha: 0.16,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: AppTheme.primaryRose,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Burç: $zodiacLabel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              titlePadding: EdgeInsets.zero,
              title: null,
            ),
            title: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => const LinearGradient(
                colors: [AppTheme.textDark, AppTheme.primaryRose],
              ).createShader(b),
              child: Text(
                'STILYA',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  letterSpacing: 3,
                ),
              ),
            ),
            centerTitle: false,
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AIChatScreen(clothingItems: clothing.items),
                  ),
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.64),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryRose.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppTheme.primaryRose,
                  ),
                ),
              ),
            ],
          ),

          // ── Body ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hava Durumu
                _WeatherCard(provider: weather),
                const SizedBox(height: 20),

                // Mood
                _SectionHeader(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Nasıl hissediyorsun?',
                ),
                const SizedBox(height: 10),
                _HorizontalChips(
                  items: _moods,
                  selected: _selectedMood,
                  onSelect: (v) => setState(() => _selectedMood = v),
                ),
                const SizedBox(height: 20),

                // Occasion
                _SectionHeader(
                  icon: Icons.event_note_outlined,
                  title: 'Bugün ne var?',
                ),
                const SizedBox(height: 10),
                _HorizontalChips(
                  items: _occasions,
                  selected: _selectedOccasion,
                  onSelect: (v) => setState(() => _selectedOccasion = v),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(
                      color: AppTheme.dividerColor.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _includeMakeupSkincare
                            ? AppTheme.lightRose
                            : AppTheme.bgMid,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.face_retouching_natural_rounded,
                        color: _includeMakeupSkincare
                            ? AppTheme.primaryRose
                            : AppTheme.textFaint,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Makyaj ve cilt bakımı önerileri',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    subtitle: Text(
                      'Kapalıysa AI sadece kombin ve motivasyon önerir.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textLight,
                        height: 1.4,
                      ),
                    ),
                    value: _includeMakeupSkincare,
                    activeThumbColor: AppTheme.primaryRose,
                    activeTrackColor: AppTheme.lightRose,
                    onChanged: (v) =>
                        setState(() => _includeMakeupSkincare = v),
                  ),
                ),
                const SizedBox(height: 24),

                _SectionHeader(
                  icon: Icons.edit_note_rounded,
                  title: 'Özel kombin detayı',
                  subtitle:
                      'İsteğe bağlı — örn. kırmızı ağırlıklı, daha resmi…',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customOutfitDetailController,
                  maxLines: 3,
                  minLines: 2,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Bugün kırmızı ağırlıklı giyinmek istiyorum veya planına özel bir not…',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryRose,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // AI Button
                _SuggestButton(
                  isSuggesting: _isSuggesting,
                  onPressed: _getSuggestion,
                ),
                const SizedBox(height: 12),

                // Stil Asistanı
                _ChatButton(clothingItems: clothing.items),

                // Error
                if (_suggestionError != null) ...[
                  const SizedBox(height: 12),
                  _ErrorCard(message: _suggestionError!),
                ],

                // Kombin seçenekleri
                if (_suggestions != null && _suggestions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.style_outlined,
                        size: 16,
                        color: AppTheme.primaryRose,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_suggestions!.length} Kombin Seçeneği',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(
                      _suggestions!.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SuggestionCard(
                          suggestion: _suggestions![i],
                          allItems: clothing.items,
                          outfitNumber: i + 1,
                          includeBeautyTips: _includeMakeupSkincare,
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hava Durumu Kartı ──────────────────────────────────────────────────────
class _HomeMoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stitch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppTheme.primaryRose.withValues(alpha: 0.08);

    for (var i = 0; i < 5; i++) {
      final path = Path()
        ..moveTo(-20, size.height * (0.24 + i * 0.16))
        ..cubicTo(
          size.width * 0.22,
          size.height * (0.08 + i * 0.12),
          size.width * 0.62,
          size.height * (0.42 + i * 0.10),
          size.width + 20,
          size.height * (0.18 + i * 0.14),
        );
      canvas.drawPath(path, stitch);
    }

    final swatchPaint = Paint()..style = PaintingStyle.fill;
    final swatches = [
      (
        AppTheme.peach.withValues(alpha: 0.24),
        Offset(size.width * 0.75, size.height * 0.22),
        92.0,
      ),
      (
        AppTheme.sage.withValues(alpha: 0.18),
        Offset(size.width * 0.18, size.height * 0.68),
        72.0,
      ),
      (
        AppTheme.lavender.withValues(alpha: 0.18),
        Offset(size.width * 0.90, size.height * 0.76),
        118.0,
      ),
    ];
    for (final swatch in swatches) {
      swatchPaint.color = swatch.$1;
      canvas.drawCircle(swatch.$2, swatch.$3, swatchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeatherCard extends StatelessWidget {
  final WeatherProvider provider;
  const _WeatherCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.lightRose.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryRose,
          ),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgMid,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lightRose,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppTheme.primaryRose,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final w = provider.weather;
    if (w == null) return const SizedBox.shrink();

    final icon = _weatherIcons[w.condition] ?? Icons.wb_cloudy_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepRose, AppTheme.darkRose, AppTheme.primaryRose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.cityName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.temperatureStr,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      w.conditionTr,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _WeatherBadge(
                    icon: Icons.water_drop_outlined,
                    value: '%${w.humidity}',
                  ),
                  const SizedBox(height: 6),
                  _WeatherBadge(
                    icon: Icons.air_rounded,
                    value: '${w.windSpeed.toStringAsFixed(1)} m/s',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  const _WeatherBadge({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.lightRose,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: AppTheme.primaryRose),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Horizontal Chip List ────────────────────────────────────────────────────
class _HorizontalChips extends StatelessWidget {
  final List<Map<String, String>> items;
  final String selected;
  final ValueChanged<String> onSelect;
  const _HorizontalChips({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final label = item['label']!;
          final isSelected = selected == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppTheme.darkRose, AppTheme.primaryRose],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryRose
                        : AppTheme.dividerColor.withValues(alpha: 0.8),
                    width: isSelected ? 0 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryRose.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  '${item['emoji']} $label',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppTheme.textMedium,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Suggest Button ─────────────────────────────────────────────────────────
class _SuggestButton extends StatelessWidget {
  final bool isSuggesting;
  final VoidCallback onPressed;
  const _SuggestButton({required this.isSuggesting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSuggesting ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          gradient: isSuggesting
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
          color: isSuggesting ? AppTheme.lightRose : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: isSuggesting ? [] : AppTheme.mediumShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSuggesting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryRose,
                ),
              )
            else
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 10),
            Text(
              isSuggesting ? 'Kombin Hazırlanıyor…' : 'Kombin Öner',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: isSuggesting ? AppTheme.primaryRose : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Button ─────────────────────────────────────────────────────────────
class _ChatButton extends StatelessWidget {
  final List<ClothingItem> clothingItems;
  const _ChatButton({required this.clothingItems});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AIChatScreen(clothingItems: clothingItems),
        ),
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.lightRose.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: AppTheme.primaryRose.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryRose.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primaryRose,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Stil Asistanıyla Konuş',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryRose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error Card ──────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorRed,
            size: 18,
          ),
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
}

// ─── Suggestion Card ─────────────────────────────────────────────────────────
class _SuggestionCard extends StatefulWidget {
  final OutfitSuggestion suggestion;
  final List<ClothingItem> allItems;
  final int outfitNumber;
  final bool includeBeautyTips;

  const _SuggestionCard({
    required this.suggestion,
    required this.allItems,
    required this.outfitNumber,
    this.includeBeautyTips = true,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _saved = false;
  bool _saving = false;

  /// AI bazen "ID:xxxx" formatında döner, bazen sadece "xxxx" — ikisini de yakala.
  List<ClothingItem> get _matchedItems {
    final cleanIds = widget.suggestion.itemIds
        .map((id) => id.startsWith('ID:') ? id.substring(3) : id)
        .toSet();
    return widget.allItems.where((item) => cleanIds.contains(item.id)).toList();
  }

  Future<void> _saveOutfit() async {
    if (_saved || _saving) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    final mk = widget.includeBeautyTips ? widget.suggestion.makeupTips : '';
    final sk = widget.includeBeautyTips ? widget.suggestion.skincareTips : '';
    final ok = await context.read<OutfitProvider>().addOutfit(
      userId: userId,
      name: widget.suggestion.styleName,
      itemIds: widget.suggestion.itemIds,
      description: widget.suggestion.outfitDescription,
      makeupTips: mk,
      skincareTips: sk,
      source: 'ai',
    );
    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) _saved = true;
      });
      if (ok) unawaited(checkBadgesAndNotify(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final matched = _matchedItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Kombin Numarası + Stil Adı başlık bandı ──────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.deepRose,
                  AppTheme.darkRose,
                  AppTheme.primaryRose,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.outfitNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.suggestion.styleName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else if (_saved)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                else
                  GestureDetector(
                    onTap: _saveOutfit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Kaydet',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Kıyafet Fotoğrafları (Flat Lay) ─────────────────────
          if (matched.isNotEmpty) ...[
            _OutfitPhotosMosaic(items: matched),
            _ColorPaletteStrip(items: matched),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: const Color(0xFFFFF0F5),
              child: Column(
                children: [
                  const Icon(
                    Icons.checkroom_outlined,
                    color: AppTheme.primaryRose,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gardıroba kıyafet ekledikçe\nburada fotoğraflar görünecek',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),

          // ── Metin İçerik ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Açıklama
                Text(
                  widget.suggestion.outfitDescription,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                    height: 1.6,
                  ),
                ),

                if (widget.includeBeautyTips) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppTheme.dividerColor),
                  ),
                  _TipRow(
                    icon: Icons.brush_outlined,
                    label: 'Makyaj',
                    text: widget.suggestion.makeupTips,
                  ),
                  const SizedBox(height: 10),
                  _TipRow(
                    icon: Icons.spa_outlined,
                    label: 'Cilt Bakımı',
                    text: widget.suggestion.skincareTips,
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 12),
                ],

                // Motivasyon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F5), Color(0xFFFCE8F3)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: AppTheme.primaryRose,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.suggestion.motivationMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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

// ─── Kıyafet Fotoğraf Şeridi ─────────────────────────────────────────────────
// ≤4 parça → eşit genişlikte sütunlar, ekranı doldurur
//  5+ parça → yatay kaydırmalı sabit genişlik kartlar
// BoxFit.contain → fotoğraf hiç kırpılmadan tam görünür
class _OutfitPhotosMosaic extends StatelessWidget {
  final List<ClothingItem> items;
  const _OutfitPhotosMosaic({required this.items});

  // Fotoğraf alanı yüksekliği
  static const double _photoH = 160;
  // Kategori etiket alanı yüksekliği
  static const double _labelH = 24;
  // 5+ parça için sabit hücre genişliği
  static const double _scrollCellW = 100;

  @override
  Widget build(BuildContext context) {
    final totalH = _photoH + _labelH;

    if (items.length <= 4) {
      // Tüm parçalar yan yana, ekranı eşit böler
      return SizedBox(
        height: totalH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(items.length, (i) {
            final last = i == items.length - 1;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: last
                      ? null
                      : const Border(
                          right: BorderSide(color: Color(0xFFEDD5E2), width: 1),
                        ),
                ),
                child: _cell(items[i]),
              ),
            );
          }),
        ),
      );
    }

    // 5+ parça: kaydırılabilir
    return SizedBox(
      height: totalH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => SizedBox(
          width: _scrollCellW,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDD5E2)),
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: _cell(items[i]),
          ),
        ),
      ),
    );
  }

  Widget _cell(ClothingItem item) {
    return Column(
      children: [
        // Fotoğraf alanı — açık pembe zemin, contain fit
        SizedBox(
          height: _photoH,
          child: ColoredBox(
            color: const Color(0xFFFAF4F7),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: _photoH,
              placeholder: (_, _) => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.primaryRose,
                  ),
                ),
              ),
              errorWidget: (_, _, _) => const Center(
                child: Icon(
                  Icons.checkroom_outlined,
                  color: AppTheme.textLight,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        // Kategori etiketi — beyaz zemin, fotoğrafın altında
        Container(
          height: _labelH,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFEDD5E2), width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            item.category,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Renk Paleti Şeridi ──────────────────────────────────────────────────────
class _ColorPaletteStrip extends StatelessWidget {
  final List<ClothingItem> items;
  const _ColorPaletteStrip({required this.items});

  static const _colorMap = <String, Color>{
    'beyaz': Color(0xFFF5F5F5),
    'siyah': Color(0xFF212121),
    'gri': Color(0xFF9E9E9E),
    'lacivert': Color(0xFF1A237E),
    'mavi': Color(0xFF1565C0),
    'açık mavi': Color(0xFF64B5F6),
    'kırmızı': Color(0xFFC62828),
    'bordo': Color(0xFF6D1B1B),
    'pembe': Color(0xFFEC407A),
    'açık pembe': Color(0xFFF8BBD9),
    'mor': Color(0xFF7B1FA2),
    'lila': Color(0xFFCE93D8),
    'yeşil': Color(0xFF2E7D32),
    'haki': Color(0xFF827717),
    'zeytin': Color(0xFF558B2F),
    'sarı': Color(0xFFF9A825),
    'turuncu': Color(0xFFE65100),
    'kahverengi': Color(0xFF4E342E),
    'krem': Color(0xFFFFF8E1),
    'bej': Color(0xFFD7C4A0),
    'ten': Color(0xFFFFCBA4),
    'gümüş': Color(0xFFBDBDBD),
    'altın': Color(0xFFFFD54F),
    'kot': Color(0xFF5C6BC0),
    'denim': Color(0xFF5C6BC0),
  };

  List<Color> get _uniqueColors {
    final seen = <String>{};
    final result = <Color>[];
    for (final item in items) {
      for (final colorName in item.colors) {
        final key = colorName.toLowerCase().trim();
        if (!seen.contains(key)) {
          seen.add(key);
          // Tam eşleşme yoksa kısmi eşleşme dene
          Color? c = _colorMap[key];
          if (c == null) {
            for (final entry in _colorMap.entries) {
              if (key.contains(entry.key) || entry.key.contains(key)) {
                c = entry.value;
                break;
              }
            }
          }
          if (c != null) result.add(c);
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _uniqueColors;
    if (colors.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEDD5E2), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Renk paleti',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: colors.map((c) {
                final isLight = c.computeLuminance() > 0.85;
                return Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFEDD5E2)
                          : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _TipRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.lightRose,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppTheme.primaryRose),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textMedium,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
