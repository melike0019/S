import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/clothing_item_model.dart';
import '../../models/outfit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stilya_design_system.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  static const _dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  static const _dayLabels = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<PlannerProvider>().watchWeek(userId, DateTime.now());
        context.read<OutfitProvider>().watchOutfits(userId);
      }
    });
  }

  String _weekRangeLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final months = [
      '',
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${weekStart.day} ${months[weekStart.month]} – '
        '${end.day} ${months[end.month]}';
  }

  bool _isToday(DateTime weekStart, int dayIndex) {
    final now = DateTime.now();
    final day = weekStart.add(Duration(days: dayIndex));
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final outfitProv = context.watch<OutfitProvider>();
    final clothingProv = context.watch<ClothingProvider>();
    final userId = context.read<AuthProvider>().user?.id;
    final week = planner.currentWeek;
    final weekStart = week?.weekStartDate ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      appBar: const StilyaAppBar(
        title: 'Haftalık Ajanda',
        subtitle: 'Haftanı stil ritmine göre planla',
        icon: Icons.calendar_month_rounded,
      ),
      body: Column(
        children: [
          // ── Hafta Navigasyon Başlığı ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: userId == null
                      ? null
                      : () => context.read<PlannerProvider>().changeWeek(
                          userId,
                          -1,
                        ),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppTheme.textDark,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    week == null ? '' : _weekRangeLabel(weekStart),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: userId == null
                      ? null
                      : () => context.read<PlannerProvider>().changeWeek(
                          userId,
                          1,
                        ),
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textDark,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kombini başka güne taşımak için kombin kartına uzun basıp istediğin güne bırak.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textLight,
                  height: 1.35,
                ),
              ),
            ),
          ),

          // ── Günler ───────────────────────────────────────────────
          if (planner.isLoading && week == null)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryRose),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: _dayKeys.length,
                itemBuilder: (_, i) {
                  final key = _dayKeys[i];
                  final label = _dayLabels[i];
                  final outfitId = week?.days[key];
                  final outfit = outfitId != null
                      ? outfitProv.outfits.cast<OutfitModel?>().firstWhere(
                          (o) => o?.id == outfitId,
                          orElse: () => null,
                        )
                      : null;
                  final isToday = _isToday(weekStart, i);

                  return _DayRow(
                    dayKey: key,
                    dayLabel: label,
                    isToday: isToday,
                    outfit: outfit,
                    allItems: clothingProv.items,
                    onTap: () => _showOutfitPicker(
                      context,
                      dayKey: key,
                      dayLabel: label,
                      currentOutfitId: outfitId,
                      outfits: outfitProv.outfits,
                      allItems: clothingProv.items,
                      userId: userId,
                    ),
                    onRemove: outfit == null || userId == null
                        ? null
                        : () => context.read<PlannerProvider>().assignOutfit(
                            userId: userId,
                            dayKey: key,
                            outfitId: null,
                          ),
                    enableDragSource: outfit != null,
                    onSwapFromDay: userId == null
                        ? null
                        : (from) {
                            context.read<PlannerProvider>().swapDaysOutfits(
                              userId: userId,
                              fromDayKey: from,
                              toDayKey: key,
                            );
                          },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showOutfitPicker(
    BuildContext context, {
    required String dayKey,
    required String dayLabel,
    required String? currentOutfitId,
    required List<OutfitModel> outfits,
    required List<ClothingItem> allItems,
    required String? userId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OutfitPickerSheet(
        dayLabel: dayLabel,
        currentOutfitId: currentOutfitId,
        outfits: outfits,
        allItems: allItems,
        onSelect: (outfitId) {
          Navigator.pop(context);
          if (userId == null) return;
          context.read<PlannerProvider>().assignOutfit(
            userId: userId,
            dayKey: dayKey,
            outfitId: outfitId,
          );
        },
      ),
    );
  }
}

// ─── Gün Satırı (sürükle-bırak hedefi + kombin için long-press ile sürük) ────
class _DayRow extends StatelessWidget {
  final String dayKey;
  final String dayLabel;
  final bool isToday;
  final OutfitModel? outfit;
  final List<ClothingItem> allItems;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool enableDragSource;
  final void Function(String fromDayKey)? onSwapFromDay;

  const _DayRow({
    required this.dayKey,
    required this.dayLabel,
    required this.isToday,
    required this.outfit,
    required this.allItems,
    required this.onTap,
    required this.onRemove,
    required this.enableDragSource,
    this.onSwapFromDay,
  });

  List<ClothingItem> get _items {
    if (outfit == null) return [];
    final ids = outfit!.itemIds.toSet();
    return allItems.where((i) => ids.contains(i.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? AppTheme.lightRose.withValues(alpha: 0.25) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: isToday
                ? AppTheme.primaryRose.withValues(alpha: 0.4)
                : AppTheme.dividerColor.withValues(alpha: 0.6),
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRose.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: isToday
                    ? LinearGradient(
                        colors: [
                          AppTheme.lightRose.withValues(alpha: 0.5),
                          AppTheme.lightRose.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppTheme.radiusLG - 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRose,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Bugün',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    dayLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isToday ? AppTheme.primaryRose : AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 72,
              color: isToday
                  ? AppTheme.primaryRose.withAlpha(40)
                  : AppTheme.dividerColor,
            ),
            Expanded(
              child: outfit == null
                  ? const _EmptySlot()
                  : _OutfitPreview(outfit: outfit!, items: items),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: outfit != null && onRemove != null
                  ? GestureDetector(
                      onTap: onRemove,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppTheme.textLight,
                      ),
                    )
                  : const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                      color: AppTheme.textLight,
                    ),
            ),
          ],
        ),
      ),
    );

    final marginWrap = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 10),
      child: LongPressDraggable<String>(
        data: dayKey,
        maxSimultaneousDrags: enableDragSource ? 1 : 0,
        hapticFeedbackOnStart: true,
        feedback: _PlannerDragBadge(
          dayLabel: dayLabel,
          subtitle: outfit?.name ?? 'Kombin',
        ),
        childWhenDragging: Opacity(
          opacity: 0.42,
          child: IgnorePointer(child: card),
        ),
        child: card,
      ),
    );

    if (onSwapFromDay == null) {
      return marginWrap;
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != dayKey,
      onAcceptWithDetails: (d) {
        if (d.data == dayKey) return;
        HapticFeedback.mediumImpact();
        onSwapFromDay!(d.data);
      },
      builder: (context, candidate, rejected) {
        final hovered = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: EdgeInsets.only(bottom: hovered ? 8 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: AppTheme.primaryRose.withAlpha(90),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hovered ? AppTheme.primaryRose : Colors.transparent,
                width: hovered ? 2 : 0,
              ),
            ),
            child: marginWrap,
          ),
        );
      },
    );
  }
}

/// Sürüklerken küçük etiket
class _PlannerDragBadge extends StatelessWidget {
  final String dayLabel;
  final String subtitle;

  const _PlannerDragBadge({required this.dayLabel, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: AppTheme.primaryRose.withAlpha(220),
              size: 22,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryRose,
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

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Text(
        'Kombin seç…',
        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight),
      ),
    );
  }
}

class _OutfitPreview extends StatelessWidget {
  final OutfitModel outfit;
  final List<ClothingItem> items;

  const _OutfitPreview({required this.outfit, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Mini fotoğraf şeridi (max 3)
          if (items.isNotEmpty)
            SizedBox(
              height: 52,
              width: items.length > 3 ? 108 : items.length * 36.0,
              child: Stack(
                children: [
                  for (var i = 0; i < items.length.clamp(0, 3); i++)
                    Positioned(
                      left: i * 30.0,
                      child: Container(
                        width: 42,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF4F7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          imageUrl: items[i].imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => const SizedBox(),
                          errorWidget: (_, _, _) => const Icon(
                            Icons.checkroom_outlined,
                            size: 16,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  outfit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                if (outfit.occasion != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    outfit.occasion!,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kombin Seçici Bottom Sheet ───────────────────────────────────────────────
class _OutfitPickerSheet extends StatelessWidget {
  final String dayLabel;
  final String? currentOutfitId;
  final List<OutfitModel> outfits;
  final List<ClothingItem> allItems;
  final ValueChanged<String?> onSelect;

  const _OutfitPickerSheet({
    required this.dayLabel,
    required this.currentOutfitId,
    required this.outfits,
    required this.allItems,
    required this.onSelect,
  });

  List<ClothingItem> _items(OutfitModel outfit) {
    final ids = outfit.itemIds.toSet();
    return allItems.where((i) => ids.contains(i.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tutma çubuğu
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
          const SizedBox(height: 16),
          Text(
            '$dayLabel için kombin seç',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),

          if (outfits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Henüz kaydedilmiş kombin yok.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: outfits.length,
                itemBuilder: (_, i) {
                  final outfit = outfits[i];
                  final items = _items(outfit);
                  final isSelected = outfit.id == currentOutfitId;

                  return GestureDetector(
                    onTap: () => onSelect(outfit.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryRose.withAlpha(15)
                            : AppTheme.bgStart,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryRose
                              : AppTheme.dividerColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Mini görsel
                          if (items.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: items.first.imageUrl,
                                width: 48,
                                height: 56,
                                fit: BoxFit.contain,
                                placeholder: (_, _) => Container(
                                  width: 48,
                                  height: 56,
                                  color: const Color(0xFFFAF4F7),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  width: 48,
                                  height: 56,
                                  color: const Color(0xFFFAF4F7),
                                  child: const Icon(
                                    Icons.checkroom_outlined,
                                    size: 20,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  outfit.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.primaryRose
                                        : AppTheme.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${items.length} parça'
                                  '${outfit.occasion != null ? ' · ${outfit.occasion}' : ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryRose,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
