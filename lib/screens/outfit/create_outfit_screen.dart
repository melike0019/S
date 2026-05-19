import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/clothing_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../theme/app_theme.dart';

class CreateOutfitScreen extends StatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  State<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends State<CreateOutfitScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};
  String? _selectedOccasion;
  String? _selectedMood;
  bool _saving = false;
  String _filterCategory = 'Tümü';

  static const List<String> _occasions = [
    'Günlük', 'İş / Toplantı', 'Brunch', 'Spor', 'Gece Çıkışı', 'Ev',
  ];
  static const List<String> _moods = [
    'Enerjik', 'Özgüvenli', 'Sakin', 'Romantik', 'Yaratıcı', 'Stresli',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<ClothingItem> _filtered(List<ClothingItem> items) {
    if (_filterCategory == 'Tümü') return items;
    return items.where((i) => i.category == _filterCategory).toList();
  }

  List<String> _categories(List<ClothingItem> items) {
    final cats = items.map((i) => i.category).toSet().toList();
    return ['Tümü', ...cats];
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Kombin için bir isim gir.');
      return;
    }
    if (_selectedIds.isEmpty) {
      _snack('En az bir kıyafet seç.');
      return;
    }

    setState(() => _saving = true);
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _saving = false);
      return;
    }

    final ok = await context.read<OutfitProvider>().addOutfit(
          userId: userId,
          name: name,
          itemIds: _selectedIds.toList(),
          occasion: _selectedOccasion,
          mood: _selectedMood,
          source: 'manual',
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      _snack(context.read<OutfitProvider>().errorMessage ?? 'Kombin kaydedilemedi.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final allItems = context.watch<ClothingProvider>().items;
    final filtered  = _filtered(allItems);
    final cats      = _categories(allItems);

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: Column(
        children: [
          // ── Premium Header ─────────────────────────────────────────
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      child: const Icon(Icons.style_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Yeni Kombin',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    GestureDetector(
                      onTap: _saving ? null : _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _saving
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          boxShadow:
                              _saving ? null : AppTheme.softShadow,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryRose))
                            : Text('Kaydet',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryRose)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Kombin adı + filtre + seçilenler ──────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Kombin adı (örn: Ofis Şıklığı)',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textLight),
                    filled: true,
                    fillColor: AppTheme.bgStart,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.primaryRose),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 10),

                // Etkinlik seçimi
                _ChipRow(
                  label: 'Etkinlik',
                  options: _occasions,
                  selected: _selectedOccasion,
                  onSelect: (v) =>
                      setState(() => _selectedOccasion = v == _selectedOccasion ? null : v),
                ),
                const SizedBox(height: 6),

                // Ruh hali seçimi
                _ChipRow(
                  label: 'Ruh Hali',
                  options: _moods,
                  selected: _selectedMood,
                  onSelect: (v) =>
                      setState(() => _selectedMood = v == _selectedMood ? null : v),
                ),
                const SizedBox(height: 10),

                // Seçilen sayısı
                if (_selectedIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: AppTheme.primaryRose),
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedIds.length} parça seçildi',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.primaryRose,
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedIds.clear()),
                          child: Text('Temizle',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textLight)),
                        ),
                      ],
                    ),
                  ),

                // Kategori filtresi
                if (cats.length > 1)
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      itemBuilder: (_, i) {
                        final cat = cats[i];
                        final sel = cat == _filterCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _filterCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: sel ? AppTheme.primaryGradient : null,
                                color: sel ? null : Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                border: Border.all(
                                  color: sel
                                      ? Colors.transparent
                                      : AppTheme.dividerColor,
                                ),
                                boxShadow: sel ? AppTheme.softShadow : null,
                              ),
                              child: Text(cat,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: sel
                                        ? Colors.white
                                        : AppTheme.textMedium,
                                  )),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // ── Kıyafet grid ──────────────────────────────────────────
          Expanded(
            child: allItems.isEmpty
                ? Center(
                    child: Text(
                      'Önce gardıroba kıyafet ekle.',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textMedium),
                    ),
                  )
                : GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final selected = _selectedIds.contains(item.id);
                      return _SelectableItem(
                        item: item,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            selected
                                ? _selectedIds.remove(item.id)
                                : _selectedIds.add(item.id);
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Seçilebilir kıyafet ─────────────────────────────────────────────────────
class _SelectableItem extends StatelessWidget {
  final ClothingItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: selected ? AppTheme.primaryRose : AppTheme.dividerColor,
            width: selected ? 2 : 1,
          ),
          color: Colors.white,
          boxShadow: selected ? AppTheme.softShadow : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: selected
                        ? AppTheme.lightRose.withValues(alpha: 0.3)
                        : AppTheme.bgMid,
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, _) => const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppTheme.primaryRose),
                        ),
                      ),
                      errorWidget: (_, _, _) => const Center(
                        child: Icon(Icons.checkroom_outlined,
                            color: AppTheme.textLight, size: 24),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 5),
                  color: Colors.white,
                  child: Text(
                    item.category,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: selected
                            ? AppTheme.primaryRose
                            : AppTheme.textMedium,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Seçim işareti
            if (selected)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Yatay chip satırı ────────────────────────────────────────────────────────
class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _ChipRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (_, i) {
          final opt = options[i];
          final sel = opt == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: sel ? AppTheme.primaryGradient : null,
                  color: sel ? null : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: sel ? Colors.transparent : AppTheme.dividerColor,
                  ),
                  boxShadow: sel ? AppTheme.softShadow : null,
                ),
                child: Text(opt,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? Colors.white : AppTheme.textMedium,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }
}
