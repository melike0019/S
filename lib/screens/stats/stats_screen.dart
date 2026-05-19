import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/clothing_item_model.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/history_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stilya_design_system.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  // Renk adı → görsel renk
  static const Map<String, Color> _colorMap = {
    'Siyah': Colors.black,
    'Beyaz': Color(0xFFDDDDDD),
    'Gri': Colors.grey,
    'Lacivert': Color(0xFF1B2A6B),
    'Mavi': Colors.blue,
    'Yeşil': Colors.green,
    'Kırmızı': Colors.red,
    'Pembe': Colors.pink,
    'Mor': Colors.purple,
    'Sarı': Colors.amber,
    'Turuncu': Colors.orange,
    'Bej': Color(0xFFD4B896),
    'Kahverengi': Colors.brown,
  };

  // Kategori sırasına göre tutarlı renkler
  static const List<Color> _pieColors = [
    Color(0xFFB05070),
    Color(0xFFC9A96E),
    Color(0xFF7B9ED9),
    Color(0xFF7DBD8A),
    Color(0xFFE07B6A),
    Color(0xFF9B72AA),
    Color(0xFFE8B86D),
    Color(0xFF6DB8C8),
  ];

  Map<String, int> _categoryCount(List<ClothingItem> items) {
    final map = <String, int>{};
    for (final item in items) {
      map[item.category] = (map[item.category] ?? 0) + 1;
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, int> _colorCount(List<ClothingItem> items) {
    final map = <String, int>{};
    for (final item in items) {
      for (final color in item.colors) {
        map[color] = (map[color] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, int> _seasonCount(List<ClothingItem> items) {
    final map = <String, int>{};
    for (final item in items) {
      for (final s in item.seasons) {
        map[s] = (map[s] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final clothing = context.watch<ClothingProvider>();
    final outfits = context.watch<OutfitProvider>();
    final history = context.watch<HistoryProvider>();

    final items = clothing.items;
    final catCount = _categoryCount(items);
    final colorCount = _colorCount(items);
    final seasonCount = _seasonCount(items);
    final favCount = outfits.outfits.where((o) => o.isFavorite).length;

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      appBar: const StilyaAppBar(
        title: 'İstatistikler',
        subtitle: 'Gardırobunun ritmini ve renklerini oku',
        icon: Icons.bar_chart_rounded,
      ),
      body: StilyaGradientShell(
        child: CustomScrollView(
          slivers: [
            if (items.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatsOverviewCard(
                      clothing: items.length,
                      outfits: outfits.outfits.length,
                      favorites: favCount,
                      history: history.entries.length,
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      clothing: items.length,
                      outfits: outfits.outfits.length,
                      favorites: favCount,
                      history: history.entries.length,
                    ),
                    const SizedBox(height: 24),

                    // ── Kategori dağılımı ──────────────────────────────────
                    if (catCount.isNotEmpty) ...[
                      _SectionTitle('Kategori Dağılımı'),
                      const SizedBox(height: 12),
                      _CategoryPieCard(
                        catCount: catCount,
                        pieColors: _pieColors,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Renk dağılımı ──────────────────────────────────────
                    if (colorCount.isNotEmpty) ...[
                      _SectionTitle('Renk Dağılımı'),
                      const SizedBox(height: 12),
                      _ColorBarsCard(
                        colorCount: colorCount,
                        colorMap: _colorMap,
                        total: items.length,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Mevsim dağılımı ────────────────────────────────────
                    if (seasonCount.isNotEmpty) ...[
                      _SectionTitle('Mevsim Dağılımı'),
                      const SizedBox(height: 12),
                      _SeasonCard(
                        seasonCount: seasonCount,
                        total: items.fold(0, (s, i) => s + i.seasons.length),
                      ),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.mediumShadow,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz Veri Yok',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gardıroba kıyafet ekledikçe\nistatistikler burada görünecek.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textMedium,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsOverviewCard extends StatelessWidget {
  final int clothing;
  final int outfits;
  final int favorites;
  final int history;

  const _StatsOverviewCard({
    required this.clothing,
    required this.outfits,
    required this.favorites,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.editorialGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gardırop özeti',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$clothing parça · $outfits kombin · $favorites favori · $history kayıt',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.45,
                    color: AppTheme.textMedium,
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

// ─── Bölüm Başlığı ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

// ─── Özet Satırı ─────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final int clothing;
  final int outfits;
  final int favorites;
  final int history;

  const _SummaryRow({
    required this.clothing,
    required this.outfits,
    required this.favorites,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          value: '$clothing',
          label: 'Kıyafet',
          icon: Icons.checkroom_rounded,
          color: AppTheme.primaryRose,
        ),
        _SummaryCard(
          value: '$outfits',
          label: 'Kombin',
          icon: Icons.style_rounded,
          color: AppTheme.gold,
        ),
        _SummaryCard(
          value: '$favorites',
          label: 'Favori',
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE07B6A),
        ),
        _SummaryCard(
          value: '$history',
          label: 'Giyim Kaydı',
          icon: Icons.history_rounded,
          color: const Color(0xFF7B9ED9),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Kategori Pasta Grafik Kartı ──────────────────────────────────────────────
class _CategoryPieCard extends StatefulWidget {
  final Map<String, int> catCount;
  final List<Color> pieColors;

  const _CategoryPieCard({required this.catCount, required this.pieColors});

  @override
  State<_CategoryPieCard> createState() => _CategoryPieCardState();
}

class _CategoryPieCardState extends State<_CategoryPieCard> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.catCount.entries.toList();
    final total = entries.fold(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        _touched = -1;
                        return;
                      }
                      _touched = response!.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: List.generate(entries.length, (i) {
                  final isTouch = i == _touched;
                  final pct = entries[i].value / total * 100;
                  return PieChartSectionData(
                    color: widget.pieColors[i % widget.pieColors.length],
                    value: entries[i].value.toDouble(),
                    title: isTouch ? '${pct.toStringAsFixed(0)}%' : '',
                    radius: isTouch ? 70 : 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    badgeWidget: isTouch ? null : null,
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                centerSpaceColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Açıklama
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(entries.length, (i) {
              final pct = (entries[i].value / total * 100).toStringAsFixed(0);
              return _LegendItem(
                color: widget.pieColors[i % widget.pieColors.length],
                label: entries[i].key,
                value: '${entries[i].value} (%$pct)',
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $value',
          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMedium),
        ),
      ],
    );
  }
}

// ─── Renk Çubuk Grafik Kartı ──────────────────────────────────────────────────
class _ColorBarsCard extends StatelessWidget {
  final Map<String, int> colorCount;
  final Map<String, Color> colorMap;
  final int total;

  const _ColorBarsCard({
    required this.colorCount,
    required this.colorMap,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final top = colorCount.entries.take(6).toList();
    final maxVal = top.isEmpty ? 1 : top.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: top.map((entry) {
          final barColor = colorMap[entry.key] ?? AppTheme.primaryRose;
          final ratio = entry.value / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Renk noktası + isim
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: barColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppTheme.bgEnd,
                      valueColor: AlwaysStoppedAnimation(barColor),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Mevsim Kartı ─────────────────────────────────────────────────────────────
class _SeasonCard extends StatelessWidget {
  final Map<String, int> seasonCount;
  final int total;

  const _SeasonCard({required this.seasonCount, required this.total});

  static const _seasonIcons = {
    'İlkbahar': '🌸',
    'Yaz': '☀️',
    'Sonbahar': '🍂',
    'Kış': '❄️',
  };

  static const _seasonColors = {
    'İlkbahar': Color(0xFF7DBD8A),
    'Yaz': Color(0xFFE8B86D),
    'Sonbahar': Color(0xFFE07B6A),
    'Kış': Color(0xFF7B9ED9),
  };

  @override
  Widget build(BuildContext context) {
    final maxVal = seasonCount.values.isEmpty
        ? 1
        : seasonCount.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: ['İlkbahar', 'Yaz', 'Sonbahar', 'Kış'].map((season) {
          final count = seasonCount[season] ?? 0;
          final ratio = total == 0 ? 0.0 : count / maxVal;
          final color = _seasonColors[season] ?? AppTheme.primaryRose;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  _seasonIcons[season] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 68,
                  child: Text(
                    season,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppTheme.bgEnd,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
