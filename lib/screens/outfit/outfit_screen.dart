import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/clothing_item_model.dart';
import '../../models/outfit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stilya_design_system.dart';
import 'create_outfit_screen.dart';

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key});

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _tabLabels = ['Tümü', 'Favoriler', 'AI', 'Manuel'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<OutfitProvider>().watchOutfits(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<OutfitModel> _filtered(List<OutfitModel> all, int tab) {
    switch (tab) {
      case 1:
        return all.where((o) => o.isFavorite).toList();
      case 2:
        return all.where((o) => o.source == 'ai').toList();
      case 3:
        return all.where((o) => o.source == 'manual').toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final outfitProv = context.watch<OutfitProvider>();
    final clothingProv = context.watch<ClothingProvider>();
    final allOutfits = outfitProv.outfits;

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      appBar: StilyaAppBar(
        title: 'Kombinler',
        subtitle: 'Favorilerini, AI önerilerini ve planlarını yönet',
        icon: Icons.style_rounded,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primaryRose,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryRose,
          indicatorWeight: 2,
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateOutfitScreen()),
        ),
        backgroundColor: AppTheme.primaryRose,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: outfitProv.isLoading && allOutfits.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRose),
            )
          : TabBarView(
              controller: _tabs,
              children: List.generate(_tabLabels.length, (i) {
                final list = _filtered(allOutfits, i);
                if (list.isEmpty) {
                  return _EmptyState(tabIndex: i);
                }
                return _OutfitList(outfits: list, allItems: clothingProv.items);
              }),
            ),
    );
  }
}

// ─── Liste ────────────────────────────────────────────────────────────────────
class _OutfitList extends StatelessWidget {
  final List<OutfitModel> outfits;
  final List<ClothingItem> allItems;

  const _OutfitList({required this.outfits, required this.allItems});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: outfits.length,
      itemBuilder: (_, i) =>
          _OutfitCard(outfit: outfits[i], allItems: allItems),
    );
  }
}

// ─── Kombin Kartı ─────────────────────────────────────────────────────────────
class _OutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  final List<ClothingItem> allItems;

  const _OutfitCard({required this.outfit, required this.allItems});

  List<ClothingItem> get _items {
    final ids = outfit.itemIds.toSet();
    return allItems.where((i) => ids.contains(i.id)).toList();
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Kombinі Sil',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${outfit.name}" kombinini silmek istediğine emin misin?',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: AppTheme.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sil',
              style: GoogleFonts.poppins(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    await context.read<OutfitProvider>().deleteOutfit(
      userId: userId,
      outfitId: outfit.id,
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    await context.read<OutfitProvider>().toggleFavorite(
      userId: userId,
      outfitId: outfit.id,
      isFavorite: !outfit.isFavorite,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return GestureDetector(
      onLongPress: () => _delete(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fotoğraf Mozaiği ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: _OutfitMosaic(items: items),
            ),

            // ── İçerik ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          outfit.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Favori butonu
                      GestureDetector(
                        onTap: () => _toggleFavorite(context),
                        child: Icon(
                          outfit.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: outfit.isFavorite
                              ? AppTheme.errorRed
                              : AppTheme.textLight,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Etiketler
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Badge(
                        label: outfit.source == 'ai' ? 'AI Öneri' : 'Manuel',
                        color: outfit.source == 'ai'
                            ? AppTheme.primaryRose
                            : AppTheme.gold,
                      ),
                      if (outfit.occasion != null)
                        _Badge(
                          label: outfit.occasion!,
                          color: AppTheme.textMedium,
                        ),
                      if (outfit.mood != null)
                        _Badge(label: outfit.mood!, color: AppTheme.textMedium),
                    ],
                  ),

                  if (outfit.description != null &&
                      outfit.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      outfit.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                        height: 1.5,
                      ),
                    ),
                  ],

                  if ((outfit.makeupTips != null &&
                          outfit.makeupTips!.isNotEmpty) ||
                      (outfit.skincareTips != null &&
                          outfit.skincareTips!.isNotEmpty)) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 10),
                    if (outfit.makeupTips != null &&
                        outfit.makeupTips!.isNotEmpty)
                      _TipRow(
                        icon: Icons.brush_outlined,
                        label: 'Makyaj',
                        text: outfit.makeupTips!,
                      ),
                    if (outfit.skincareTips != null &&
                        outfit.skincareTips!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _TipRow(
                        icon: Icons.spa_outlined,
                        label: 'Cilt',
                        text: outfit.skincareTips!,
                      ),
                    ],
                  ],

                  // Parça sayısı + silme ipucu
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.checkroom_outlined,
                        size: 13,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${items.length} parça',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Silmek için uzun bas',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mozaik ───────────────────────────────────────────────────────────────────
class _OutfitMosaic extends StatelessWidget {
  final List<ClothingItem> items;

  const _OutfitMosaic({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        height: 160,
        color: const Color(0xFFFAF4F7),
        child: const Center(
          child: Icon(
            Icons.checkroom_outlined,
            size: 40,
            color: AppTheme.textLight,
          ),
        ),
      );
    }

    if (items.length >= 5) {
      // Yatay kaydırmalı şerit
      return SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (_, i) =>
              _MosaicCell(url: items[i].imageUrl, width: 130, height: 160),
        ),
      );
    }

    // ≤4 parça: eşit sütunlar
    return SizedBox(
      height: 160,
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: _MosaicCell(
                  url: item.imageUrl,
                  height: 160,
                  borderRight: item != items.last,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MosaicCell extends StatelessWidget {
  final String url;
  final double height;
  final double? width;
  final bool borderRight;

  const _MosaicCell({
    required this.url,
    required this.height,
    this.width,
    this.borderRight = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      width: width ?? double.infinity,
      height: height,
      placeholder: (_, _) => const ColoredBox(
        color: Color(0xFFFAF4F7),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppTheme.primaryRose,
            ),
          ),
        ),
      ),
      errorWidget: (_, _, _) => const ColoredBox(
        color: Color(0xFFFAF4F7),
        child: Center(
          child: Icon(
            Icons.checkroom_outlined,
            color: AppTheme.textLight,
            size: 28,
          ),
        ),
      ),
    );

    if (borderRight) {
      img = Container(
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: AppTheme.dividerColor, width: 0.5),
          ),
        ),
        child: img,
      );
    }

    return ColoredBox(color: const Color(0xFFFAF4F7), child: img);
  }
}

// ─── Küçük Bileşenler ─────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
        Icon(icon, size: 14, color: AppTheme.primaryRose),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                TextSpan(
                  text: text,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textMedium,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Boş Durum ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final int tabIndex;

  const _EmptyState({required this.tabIndex});

  static const _messages = [
    'Henüz kaydedilmiş kombin yok.\nAI önerisinden "Kaydet"e bas veya\n+ butonuna dokun.',
    'Henüz favori kombin yok.\nBeğendiklerini kalp ikonuna basarak ekle.',
    'Henüz AI önerisi kaydedilmedi.\nAna sayfadan kombin al, ardından kaydet.',
    'Henüz manuel kombin oluşturulmadı.\n+ butonuna basarak başla.',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRose.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.style_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _messages[tabIndex],
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textMedium,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
