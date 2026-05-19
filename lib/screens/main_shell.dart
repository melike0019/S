import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/clothing_item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/clothing_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../utils/badge_checker.dart';
import '../widgets/stilya_design_system.dart';
import 'home/home_screen.dart';
import 'wardrobe/wardrobe_screen.dart';
import 'outfit/outfit_screen.dart';
import 'planner/planner_screen.dart';
import 'profile/profile_screen.dart';

// Sallama eşiği (m/s²) ve bekleme süresi
const double _kShakeThreshold = 18.0;
const Duration _kShakeCooldown = Duration(seconds: 3);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShake = DateTime(2000);
  bool _sheetOpen = false;

  static const List<Widget> _screens = [
    HomeScreen(),
    WardrobeScreen(),
    OutfitScreen(),
    PlannerScreen(),
    ProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Ana Sayfa',
    ),
    _NavItem(
      icon: Icons.checkroom_outlined,
      selectedIcon: Icons.checkroom,
      label: 'Gardırop',
    ),
    _NavItem(
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
      label: 'Kombin',
    ),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Ajanda',
    ),
    _NavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startListening();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initUserAndBadges());
  }

  /// UserProvider'ı başlat ve mevcut kullanıcı için geçmiş rozetleri kontrol et.
  /// Bu sayede eski kullanıcılar rozet sisteminden önce kazandıkları
  /// başarımları uygulama açılışında retroaktif olarak alır.
  Future<void> _initUserAndBadges() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    // UserProvider'ı başlat (badge check için gerekli)
    context.read<UserProvider>().watchUser(userId);

    // Kısa gecikme: stream'in ilk veriyi almasını bekle
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) await checkBadgesAndNotify(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _accelSub?.resume();
    } else {
      _accelSub?.pause();
    }
  }

  void _startListening() {
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((event) {
          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final now = DateTime.now();
          if (magnitude > _kShakeThreshold &&
              now.difference(_lastShake) > _kShakeCooldown &&
              !_sheetOpen) {
            _lastShake = now;
            _onShake();
          }
        });
  }

  void _onShake() {
    final clothing = context.read<ClothingProvider>();
    if (clothing.items.isEmpty) return;

    final outfit = _buildRandomOutfit(clothing.items);
    if (outfit.isEmpty) return;

    _sheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ShakeOutfitSheet(items: outfit, allItems: clothing.items),
    ).whenComplete(() => _sheetOpen = false);
  }

  /// Mevsimine uygun kıyafetleri kategoriye göre rastgele seçer.
  List<ClothingItem> _buildRandomOutfit(List<ClothingItem> all) {
    final season = _currentSeason();
    final rng = Random();

    // Mevsime uyan parçalar, yoksa tümü kullanılır
    final pool = all.where((i) => i.seasons.contains(season)).toList();
    final source = pool.isEmpty ? all : pool;

    // Kategori grupları — öncelik sırasına göre
    final groups = <String, List<ClothingItem>>{};
    for (final item in source) {
      groups.putIfAbsent(item.category, () => []).add(item);
    }

    final result = <ClothingItem>[];
    // Öncelikli kategorilerden birer parça seç
    const priority = [
      'Üst Giyim',
      'Alt Giyim',
      'Elbise / Tulum',
      'Ayakkabı',
      'Dış Giyim',
      'Aksesuar',
      'Çanta',
    ];
    for (final cat in priority) {
      final list = groups[cat];
      if (list != null && list.isNotEmpty) {
        result.add(list[rng.nextInt(list.length)]);
      }
    }
    // Kalan kategorilerden de ekle
    for (final cat in groups.keys) {
      if (!priority.contains(cat) && groups[cat]!.isNotEmpty) {
        result.add(groups[cat]![rng.nextInt(groups[cat]!.length)]);
      }
    }

    return result.take(5).toList(); // Maksimum 5 parça
  }

  String _currentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: StilyaGlassCard(
          radius: AppTheme.radius2XL,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 68,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                return _NavButton(
                  item: _navItems[i],
                  selected: _currentIndex == i,
                  onTap: () => setState(() => _currentIndex = i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Salla-Giy Bottom Sheet ───────────────────────────────────────────────────
class _ShakeOutfitSheet extends StatefulWidget {
  final List<ClothingItem> items;
  final List<ClothingItem> allItems;

  const _ShakeOutfitSheet({required this.items, required this.allItems});

  @override
  State<_ShakeOutfitSheet> createState() => _ShakeOutfitSheetState();
}

class _ShakeOutfitSheetState extends State<_ShakeOutfitSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.elasticOut,
    ).drive(Tween(begin: 0.7, end: 1.0));
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeIn,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saved || _saving) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    final season = _seasonLabel();
    final ok = await context.read<OutfitProvider>().addOutfit(
      userId: userId,
      name: 'Salla-Giy: $season Kombini',
      itemIds: widget.items.map((i) => i.id).toList(),
      source: 'manual',
    );
    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) _saved = true;
      });
      if (ok) unawaited(checkBadgesAndNotify(context));
    }
  }

  String _seasonLabel() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgStart,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: AppTheme.strongShadow,
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Center(
                    child: Text('🎲', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salla-Giy!',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '${_seasonLabel()} mevsimi kombinin hazır ✨',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Outfit items grid
            ScaleTransition(
              scale: _scaleAnim,
              child: SizedBox(
                height: 160,
                child: Row(
                  children: widget.items
                      .asMap()
                      .entries
                      .map(
                        (entry) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: entry.key < widget.items.length - 1
                                  ? 6
                                  : 0,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.bgMid,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMD,
                              ),
                              border: Border.all(
                                color: AppTheme.dividerColor.withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CachedNetworkImage(
                                    imageUrl: entry.value.imageUrl,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    placeholder: (_, _) => const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
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
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.8),
                                  child: Text(
                                    entry.value.category,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      color: AppTheme.textMedium,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) {
                          final clothing = context.read<ClothingProvider>();
                          if (clothing.items.isNotEmpty) {
                            final shell = context
                                .findAncestorStateOfType<_MainShellState>();
                            shell?._onShake();
                          }
                        }
                      });
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.bgMid,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎲', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 8),
                          Text(
                            'Tekrar Sal',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _saved ? null : (_saving ? null : _save),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: _saved
                            ? const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                              )
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_saving)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Icon(
                              _saved
                                  ? Icons.check_rounded
                                  : Icons.bookmark_add_outlined,
                              color: Colors.white,
                              size: 17,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _saved
                                ? 'Kaydedildi'
                                : _saving
                                ? 'Kaydediliyor…'
                                : 'Kombinimi Kaydet',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Item & Button ────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
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
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                width: widget.selected ? 48 : 38,
                height: widget.selected ? 32 : 26,
                decoration: widget.selected
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.lightRose, Color(0xFFFFE8F2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRose.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      )
                    : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.selected
                          ? widget.item.selectedIcon
                          : widget.item.icon,
                      key: ValueKey(widget.selected),
                      size: widget.selected ? 21 : 20,
                      color: widget.selected
                          ? AppTheme.primaryRose
                          : AppTheme.textLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: widget.selected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: widget.selected
                      ? AppTheme.primaryRose
                      : AppTheme.textLight,
                  fontFamily: 'Poppins',
                  letterSpacing: widget.selected ? 0.2 : 0,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
