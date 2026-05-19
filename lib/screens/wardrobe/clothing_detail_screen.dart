import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/clothing_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../theme/app_theme.dart';

class ClothingDetailScreen extends StatefulWidget {
  final ClothingItem item;
  const ClothingDetailScreen({super.key, required this.item});

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  bool _editing = false;
  bool _saving = false;

  late String _category;
  late List<String> _colors;
  late List<String> _seasons;
  late String? _brand;
  late String? _notes;
  late String? _fit;
  late String? _fabric;
  late String? _pattern;
  late String? _style;
  late String? _subCategory;

  static const _categories = [
    'Üst Giyim', 'Alt Giyim', 'Elbise / Tulum', 'Dış Giyim',
    'Ayakkabı', 'Aksesuar', 'Çanta', 'İç Giyim', 'Spor',
  ];
  static const _allColors = [
    'Siyah', 'Beyaz', 'Gri', 'Lacivert', 'Mavi', 'Yeşil',
    'Kırmızı', 'Pembe', 'Mor', 'Sarı', 'Turuncu', 'Bej', 'Kahverengi',
  ];
  static const _allSeasons = ['İlkbahar', 'Yaz', 'Sonbahar', 'Kış'];

  static const Map<String, Color> _colorMap = {
    'Siyah': Colors.black,
    'Beyaz': Color(0xFFF0F0F0),
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

  @override
  void initState() {
    super.initState();
    _resetFields();
  }

  void _resetFields() {
    _category = widget.item.category;
    _colors = List.from(widget.item.colors);
    _seasons = List.from(widget.item.seasons);
    _brand = widget.item.brand;
    _notes = widget.item.notes;
    _fit = widget.item.fit;
    _fabric = widget.item.fabric;
    _pattern = widget.item.pattern;
    _style = widget.item.style;
    _subCategory = widget.item.subCategory;
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    await context.read<ClothingProvider>().updateItem(
          userId: userId,
          itemId: widget.item.id,
          category: _category,
          colors: _colors,
          seasons: _seasons,
          brand: _brand?.isEmpty ?? true ? null : _brand,
          notes: _notes?.isEmpty ?? true ? null : _notes,
          fit: _fit?.isEmpty ?? true ? null : _fit,
          fabric: _fabric?.isEmpty ?? true ? null : _fabric,
          pattern: _pattern?.isEmpty ?? true ? null : _pattern,
          style: _style?.isEmpty ?? true ? null : _style,
          subCategory: _subCategory?.isEmpty ?? true ? null : _subCategory,
        );
    if (mounted) setState(() { _saving = false; _editing = false; });
  }

  Future<void> _delete() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kıyafeti Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Bu kıyafeti gardırobundan silmek istiyor musun? Bu işlem geri alınamaz.'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ClothingProvider>().deleteItem(
            userId: userId,
            itemId: widget.item.id,
            imageUrl: widget.item.imageUrl,
          );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppTheme.textDark),
              ),
            ),
            actions: [
              if (!_editing) ...[
                GestureDetector(
                  onTap: () => setState(() => _editing = true),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 14,
                            color: AppTheme.primaryRose),
                        const SizedBox(width: 4),
                        Text('Düzenle',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryRose)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _delete,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: Color(0xFFE53935)),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _editing = false;
                      _resetFields();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Text('İptal',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMedium)),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.deepRose,
                      AppTheme.darkRose,
                      AppTheme.primaryRose,
                      const Color(0xFFD4809A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30, top: -30,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 65, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            child: Icon(
                              _editing
                                  ? Icons.edit_rounded
                                  : Icons.checkroom_rounded,
                              color: Colors.white, size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _editing ? 'Kıyafeti Düzenle' : 'Kıyafet Detayı',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(),
                  const SizedBox(height: 20),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  if (_editing) ...[
                    _buildEditSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ] else
                    _buildStatsCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgMid,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.mediumShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: widget.item.imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, _) => Center(
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
          ),
        ),
        errorWidget: (_, _, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 48, color: AppTheme.textLight),
              const SizedBox(height: 8),
              Text('Yüklenemedi', style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textLight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Kategori', _category),
          const Divider(height: 20, color: AppTheme.dividerColor),
          _infoRow('Renkler', _colors.join(', ')),
          const Divider(height: 20, color: AppTheme.dividerColor),
          _infoRow('Mevsimler', _seasons.join(', ')),
          if (_brand != null && _brand!.isNotEmpty) ...[
            const Divider(height: 20, color: AppTheme.dividerColor),
            _infoRow('Marka', _brand!),
          ],
          if (widget.item.fit != null && widget.item.fit!.isNotEmpty) ...[
            const Divider(height: 20, color: AppTheme.dividerColor),
            _infoRow('Kalıp', widget.item.fit!),
          ],
          if (widget.item.fabric != null && widget.item.fabric!.isNotEmpty) ...[
            const Divider(height: 20, color: AppTheme.dividerColor),
            _infoRow('Kumaş', widget.item.fabric!),
          ],
          if (widget.item.pattern != null && widget.item.pattern!.isNotEmpty) ...[
            const Divider(height: 20, color: AppTheme.dividerColor),
            _infoRow('Desen', widget.item.pattern!),
          ],
          if (widget.item.style != null && widget.item.style!.isNotEmpty) ...[
            const Divider(height: 20, color: AppTheme.dividerColor),
            _infoRow('Tarz', widget.item.style!),
          ],
          if (_notes != null && _notes!.isNotEmpty) ...[
            const Divider(height: 20, color: AppTheme.dividerColor),
            _infoRow('Notlar', _notes!),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final lastWorn = widget.item.lastWornAt;
    final daysSince = lastWorn != null
        ? DateTime.now().difference(lastWorn).inDays
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppTheme.bgStart],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text('Kullanım İstatistikleri',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statChip('👗', '${widget.item.wearCount}', 'kez giyildi'),
              const SizedBox(width: 12),
              _statChip(
                '📅',
                daysSince != null ? '$daysSince gün' : '—',
                'son giyimden beri',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Eklendi: ${_formatDate(widget.item.createdAt)}',
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.lightRose.withValues(alpha: 0.5), AppTheme.bgMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppTheme.darkRose)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppTheme.textLight),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Kategori'),
        _buildCategoryPicker(),
        const SizedBox(height: 16),
        _sectionLabel('Renkler'),
        _buildColorPicker(),
        const SizedBox(height: 16),
        _sectionLabel('Mevsimler'),
        _buildSeasonPicker(),
        const SizedBox(height: 16),
        _sectionLabel('Alt Kategori / Tür (İsteğe bağlı)'),
        _buildTextField(
          initialValue: _subCategory ?? '',
          hint: 'Örn: Kot Pantolon, Şifon Bluz…',
          onChanged: (v) => _subCategory = v,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Marka (İsteğe bağlı)'),
        _buildTextField(
          initialValue: _brand ?? '',
          hint: 'Örn: Zara, H&M…',
          onChanged: (v) => _brand = v,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Kalıp (İsteğe bağlı)'),
        _buildTextField(
          initialValue: _fit ?? '',
          hint: 'Örn: Dar, Oversize',
          onChanged: (v) => _fit = v,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Kumaş (İsteğe bağlı)'),
        _buildTextField(
          initialValue: _fabric ?? '',
          hint: 'Örn: Pamuk, İpek',
          onChanged: (v) => _fabric = v,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Desen (İsteğe bağlı)'),
        _buildTextField(
          initialValue: _pattern ?? '',
          hint: 'Örn: Çizgili, Düz',
          onChanged: (v) => _pattern = v,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Tarz (İsteğe bağlı)'),
        _buildTextField(
          initialValue: _style ?? '',
          hint: 'Örn: Spor, Şık',
          onChanged: (v) => _style = v,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Notlar (İsteğe bağlı)'),
        _buildTextField(
          initialValue: _notes ?? '',
          hint: 'Kıyafet hakkında notlar…',
          maxLines: 3,
          onChanged: (v) => _notes = v,
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
    );
  }

  Widget _buildCategoryPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _category == cat;
        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primaryRose : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? AppTheme.primaryRose : AppTheme.dividerColor),
            ),
            child: Text(cat,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: selected ? Colors.white : AppTheme.textMedium,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allColors.map((colorName) {
        final selected = _colors.contains(colorName);
        final c = _colorMap[colorName] ?? Colors.grey;
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _colors.remove(colorName);
            } else {
              _colors.add(colorName);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? c.withAlpha(30) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? c : AppTheme.dividerColor, width: selected ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDDDDDD), width: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(colorName,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textDark)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeasonPicker() {
    return Wrap(
      spacing: 8,
      children: _allSeasons.map((s) {
        final selected = _seasons.contains(s);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _seasons.remove(s);
            } else {
              _seasons.add(s);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.lightRose : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? AppTheme.primaryRose : AppTheme.dividerColor),
            ),
            child: Text(s,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: selected ? AppTheme.primaryRose : AppTheme.textMedium,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryRose),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textDark),
      onChanged: onChanged,
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _saving ? null : AppTheme.primaryGradient,
          color: _saving ? AppTheme.textFaint : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: _saving ? null : AppTheme.mediumShadow,
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text('Kaydet',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white)),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}
