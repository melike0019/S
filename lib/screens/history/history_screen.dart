import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/clothing_item_model.dart';
import '../../models/history_model.dart';
import '../../models/outfit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<HistoryProvider>().watchHistory(userId);
        context.read<OutfitProvider>().watchOutfits(userId);
      }
    });
  }

  static const _monthNames = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  void _prevMonth() {
    setState(() {
      _focusMonth =
          DateTime(_focusMonth.year, _focusMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_focusMonth.year, _focusMonth.month + 1, 1);
    if (next.isBefore(DateTime(now.year, now.month + 1, 1))) {
      setState(() => _focusMonth = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProv = context.watch<HistoryProvider>();
    final outfitProv = context.watch<OutfitProvider>();
    final clothingProv = context.watch<ClothingProvider>();
    final monthEntries = historyProv.entriesForMonth(
        _focusMonth.year, _focusMonth.month);

    // Günlere göre grupla
    final Map<int, List<HistoryModel>> byDay = {};
    for (final e in monthEntries) {
      byDay.putIfAbsent(e.wornDate.day, () => []).add(e);
    }
    final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: Column(
        children: [
          // ── Premium Header ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepRose, AppTheme.darkRose,
                    AppTheme.primaryRose, Color(0xFFD4809A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppTheme.softShadow,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: const Icon(Icons.history_rounded,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text('Giyim Geçmişi',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 20, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  // Ay Navigasyonu
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _prevMonth,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_left_rounded,
                                  color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${_monthNames[_focusMonth.month]} ${_focusMonth.year}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                          GestureDetector(
                            onTap: _nextMonth,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // İstatistik şeridi
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        _StatChip(
                            icon: Icons.event_available_outlined,
                            label: '${monthEntries.length} kez giyildi'),
                        const SizedBox(width: 10),
                        _StatChip(
                            icon: Icons.checkroom_outlined,
                            label: '${monthEntries.map((e) => e.outfitId).toSet().length} farklı kombin'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Liste ─────────────────────────────────────────────────
          if (historyProv.isLoading && monthEntries.isEmpty)
            const Expanded(
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryRose)),
            )
          else if (monthEntries.isEmpty)
            const Expanded(child: _EmptyState())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: sortedDays.length,
                itemBuilder: (_, i) {
                  final day = sortedDays[i];
                  final dayEntries = byDay[day]!;
                  final date = DateTime(
                      _focusMonth.year, _focusMonth.month, day);

                  return _DaySection(
                    date: date,
                    entries: dayEntries,
                    outfits: outfitProv.outfits,
                    allItems: clothingProv.items,
                    onDelete: (entryId) async {
                      final userId =
                          context.read<AuthProvider>().user?.id;
                      if (userId == null) return;
                      await context
                          .read<HistoryProvider>()
                          .deleteEntry(
                              userId: userId, entryId: entryId);
                    },
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _showLogSheet(
          context,
          outfits: outfitProv.outfits,
          allItems: clothingProv.items,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow: AppTheme.mediumShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Kaydet',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogSheet(
    BuildContext context, {
    required List<OutfitModel> outfits,
    required List<ClothingItem> allItems,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogSheet(
        outfits: outfits,
        allItems: allItems,
        onSave: (outfitId, date, mood, occasion) async {
          Navigator.pop(context);
          final userId = context.read<AuthProvider>().user?.id;
          if (userId == null) return;
          await context.read<HistoryProvider>().addEntry(
                userId: userId,
                outfitId: outfitId,
                wornDate: date,
                mood: mood,
                occasion: occasion,
              );
        },
      ),
    );
  }
}

// ─── Gün Bölümü ───────────────────────────────────────────────────────────────
class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<HistoryModel> entries;
  final List<OutfitModel> outfits;
  final List<ClothingItem> allItems;
  final ValueChanged<String> onDelete;

  const _DaySection({
    required this.date,
    required this.entries,
    required this.outfits,
    required this.allItems,
    required this.onDelete,
  });

  static const _dayNames = [
    '', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'
  ];
  static const _months = [
    '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gün başlığı
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isToday
                      ? AppTheme.primaryRose
                      : AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_dayNames[date.weekday]} ${date.day} ${_months[date.month]}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isToday ? Colors.white : AppTheme.textMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Divider(
                      height: 1,
                      color: AppTheme.dividerColor.withAlpha(120))),
            ],
          ),
        ),
        ...entries.map((entry) {
          final outfit = outfits.cast<OutfitModel?>().firstWhere(
              (o) => o?.id == entry.outfitId,
              orElse: () => null);
          return _HistoryCard(
            entry: entry,
            outfit: outfit,
            allItems: allItems,
            onDelete: () => onDelete(entry.id),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Geçmiş Kartı ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final HistoryModel entry;
  final OutfitModel? outfit;
  final List<ClothingItem> allItems;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.entry,
    required this.outfit,
    required this.allItems,
    required this.onDelete,
  });

  List<ClothingItem> get _items {
    if (outfit == null) return [];
    final ids = outfit!.itemIds.toSet();
    return allItems.where((i) => ids.contains(i.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return GestureDetector(
      onLongPress: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Kaydı Sil',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            content: Text('Bu geçmiş kaydını silmek istiyor musun?',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMedium)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('İptal',
                      style:
                          GoogleFonts.poppins(color: AppTheme.textLight))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Sil',
                      style: GoogleFonts.poppins(
                          color: AppTheme.errorRed))),
            ],
          ),
        );
        if (ok == true) onDelete();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Mini görsel
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13)),
              child: items.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: items.first.imageUrl,
                      width: 64,
                      height: 76,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => Container(
                          width: 64,
                          height: 76,
                          color: const Color(0xFFFAF4F7)),
                      errorWidget: (_, _, _) => Container(
                        width: 64,
                        height: 76,
                        color: const Color(0xFFFAF4F7),
                        child: const Icon(Icons.checkroom_outlined,
                            color: AppTheme.textLight, size: 24),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 76,
                      color: const Color(0xFFFAF4F7),
                      child: const Icon(Icons.checkroom_outlined,
                          color: AppTheme.textLight, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit?.name ?? 'Silinmiş Kombin',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: outfit != null
                              ? AppTheme.textDark
                              : AppTheme.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (entry.mood != null)
                          _MiniTag(label: entry.mood!),
                        if (entry.occasion != null)
                          _MiniTag(label: entry.occasion!),
                        if (items.isNotEmpty)
                          _MiniTag(label: '${items.length} parça'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.more_horiz_rounded,
                  color: AppTheme.textLight, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  const _MiniTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.dividerColor.withAlpha(120),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, color: AppTheme.textMedium)),
    );
  }
}

// ─── Kayıt Ekleme Sheet ───────────────────────────────────────────────────────
class _LogSheet extends StatefulWidget {
  final List<OutfitModel> outfits;
  final List<ClothingItem> allItems;
  final Future<void> Function(
      String outfitId, DateTime date, String? mood, String? occasion) onSave;

  const _LogSheet({
    required this.outfits,
    required this.allItems,
    required this.onSave,
  });

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  String? _selectedOutfitId;
  DateTime _selectedDate = DateTime.now();
  String? _mood;
  String? _occasion;
  bool _saving = false;

  static const _moods = [
    'Enerjik', 'Özgüvenli', 'Sakin', 'Romantik', 'Yaratıcı',
  ];
  static const _occasions = [
    'Günlük', 'İş', 'Brunch', 'Spor', 'Gece Çıkışı',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Bugün ne giydim?',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 16),

            // Tarih seçici
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now()
                      .subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgStart,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppTheme.primaryRose),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Kombin seçici
            Text('Kombin',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium)),
            const SizedBox(height: 6),
            if (widget.outfits.isEmpty)
              Text('Önce bir kombin kaydet.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textLight))
            else
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.outfits.length,
                  itemBuilder: (_, i) {
                    final o = widget.outfits[i];
                    final sel = o.id == _selectedOutfitId;
                    final ids = o.itemIds.toSet();
                    final items = widget.allItems
                        .where((it) => ids.contains(it.id))
                        .toList();
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedOutfitId = o.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primaryRose.withAlpha(15)
                              : AppTheme.bgStart,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppTheme.primaryRose
                                : AppTheme.dividerColor,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (items.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: items.first.imageUrl,
                                  width: 40,
                                  height: 46,
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) => const SizedBox(
                                      width: 40, height: 46),
                                  errorWidget: (_, _, _) => const Icon(
                                      Icons.checkroom_outlined,
                                      size: 20,
                                      color: AppTheme.textLight),
                                ),
                              ),
                            const SizedBox(height: 3),
                            Text(
                              o.name,
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: sel
                                    ? AppTheme.primaryRose
                                    : AppTheme.textMedium,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 14),

            // Ruh hali
            Text('Ruh Hali',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium)),
            const SizedBox(height: 6),
            _ChipRow(
                options: _moods,
                selected: _mood,
                onSelect: (v) => setState(
                    () => _mood = v == _mood ? null : v)),
            const SizedBox(height: 12),

            // Etkinlik
            Text('Etkinlik',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium)),
            const SizedBox(height: 6),
            _ChipRow(
                options: _occasions,
                selected: _occasion,
                onSelect: (v) => setState(
                    () => _occasion = v == _occasion ? null : v)),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _selectedOutfitId == null || _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.onSave(
                        _selectedOutfitId!,
                        _selectedDate,
                        _mood,
                        _occasion,
                      );
                    },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: (_selectedOutfitId == null || _saving)
                      ? null
                      : AppTheme.primaryGradient,
                  color: (_selectedOutfitId == null || _saving)
                      ? AppTheme.textFaint
                      : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  boxShadow: (_selectedOutfitId == null || _saving)
                      ? null
                      : AppTheme.mediumShadow,
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Kaydet',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _ChipRow(
      {required this.options,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (_, i) {
          final opt = options[i];
          final sel = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primaryRose : AppTheme.bgStart,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        sel ? AppTheme.primaryRose : AppTheme.dividerColor),
              ),
              child: Text(opt,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.white : AppTheme.textMedium,
                  )),
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRose.withAlpha(50),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.history_rounded,
                  size: 38, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              'Bu ay için kayıt yok.\n+ butonuna basarak bugün ne\ngiydiğini kaydet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textMedium,
                  height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}
