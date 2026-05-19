import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/clothing_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class BlindSpotScreen extends StatefulWidget {
  const BlindSpotScreen({super.key});

  @override
  State<BlindSpotScreen> createState() => _BlindSpotScreenState();
}

class _BlindSpotScreenState extends State<BlindSpotScreen> {
  List<OutfitSuggestion>? _suggestions;
  bool _loading = false;
  String? _error;

  Future<void> _getSuggestions() async {
    final clothing = context.read<ClothingProvider>();
    final forgotten = clothing.forgottenItems;
    final all = clothing.items;

    setState(() {
      _loading = true;
      _suggestions = null;
      _error = null;
    });

    try {
      final zodiac = context.read<AuthProvider>().user?.zodiacSign;
      final results = await context.read<AIService>().getBlindSpotSuggestion(
        forgottenItems: forgotten,
        allItems: all,
        zodiacSign: zodiac,
      );
      if (mounted) setState(() => _suggestions = results);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markWorn(ClothingItem item) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    await context.read<ClothingProvider>().markAsWorn(
          userId: userId,
          itemId: item.id,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.category} giyildi olarak işaretlendi ✓'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clothing = context.watch<ClothingProvider>();
    final forgotten = clothing.forgottenItems;
    final all = clothing.items;

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.deepRose,
            title: Text(
              'Kör Nokta Analizi',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.deepRose, AppTheme.darkRose,
                        AppTheme.primaryRose, Color(0xFFD4809A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Text('♻️',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${forgotten.length} kıyafet 30+ gündür gardıroplarda uyuyor',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color:
                                        Colors.white.withAlpha(220),
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              titlePadding: EdgeInsets.zero,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Unutulan kıyafet grid'i ────────────────────────
                if (forgotten.isEmpty)
                  _buildEmpty()
                else ...[
                  _InfoCard(count: forgotten.length),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: forgotten.length,
                    itemBuilder: (_, i) => _ForgottenCard(
                      item: forgotten[i],
                      onMarkWorn: () => _markWorn(forgotten[i]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── AI Yeniden Keşfet butonu ───────────────────
                  _AiButton(
                    loading: _loading,
                    onPressed: _getSuggestions,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'AI, unutulan parçalarla yeni kombinler önerir',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textLight),
                    ),
                  ),

                  // ── Hata ──────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorCard(message: _error!),
                  ],

                  // ── AI önerileri ───────────────────────────────
                  if (_suggestions != null &&
                      _suggestions!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 14, color: AppTheme.primaryRose),
                        const SizedBox(width: 6),
                        Text(
                          '${_suggestions!.length} Yeniden Keşif Kombini',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._suggestions!.asMap().entries.map((e) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SuggestionCard(
                            suggestion: e.value,
                            allItems: all,
                            outfitNumber: e.key + 1,
                          ),
                        )),
                  ],
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppTheme.lightRose,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 44, color: AppTheme.primaryRose),
            ),
            const SizedBox(height: 20),
            Text(
              'Harika! Kör Nokta Yok',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Son 30 günde tüm kıyafetlerini\nen az bir kez giydin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textMedium,
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bilgi Kartı ──────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final int count;
  const _InfoCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFFCE8F3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu $count parça uzun süredir giyilmedi. '
              '"Bugün Giydim" butonuyla kaydını güncelle '
              'veya AI\'dan yeni kombinler isteyelim!',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Unutulan Kıyafet Kartı ───────────────────────────────────────────────────
class _ForgottenCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onMarkWorn;
  const _ForgottenCard({required this.item, required this.onMarkWorn});

  int get _daysSince {
    final last = item.lastWornAt ?? item.createdAt;
    return DateTime.now().difference(last).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fotoğraf
          Expanded(
            child: Stack(
              children: [
                ColoredBox(
                  color: const Color(0xFFFAF4F7),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, _) => const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppTheme.primaryRose),
                      ),
                    ),
                    errorWidget: (_, _, _) => const Center(
                      child: Icon(Icons.checkroom_outlined,
                          color: AppTheme.textLight, size: 28),
                    ),
                  ),
                ),
                // Gün sayısı rozeti
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _daysSince > 60
                          ? AppTheme.errorRed
                          : AppTheme.darkRose,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_daysSince gün',
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Alt bilgi + buton
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.brand != null) ...[
                  Text(
                    item.brand!,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: AppTheme.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onMarkWorn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRose,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: GoogleFonts.poppins(fontSize: 10),
                    ),
                    child: const Text('Bugün Giydim'),
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

// ─── AI Butonu ────────────────────────────────────────────────────────────────
class _AiButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _AiButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF5A2D4C), AppTheme.darkRose,
                      AppTheme.primaryRose],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: loading ? AppTheme.lightRose : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryRose.withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primaryRose),
              )
            else
              const Text('♻️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              loading ? 'Kombinler Hazırlanıyor…' : 'AI ile Yeniden Keşfet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: loading ? AppTheme.primaryRose : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hata Kartı ───────────────────────────────────────────────────────────────
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
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}

// ─── AI Öneri Kartı ───────────────────────────────────────────────────────────
class _SuggestionCard extends StatefulWidget {
  final OutfitSuggestion suggestion;
  final List<ClothingItem> allItems;
  final int outfitNumber;

  const _SuggestionCard({
    required this.suggestion,
    required this.allItems,
    required this.outfitNumber,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _saved = false;
  bool _saving = false;

  List<ClothingItem> get _matchedItems {
    final ids = widget.suggestion.itemIds.toSet();
    return widget.allItems.where((i) => ids.contains(i.id)).toList();
  }

  Future<void> _save() async {
    if (_saved || _saving) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    final ok = await context.read<OutfitProvider>().addOutfit(
          userId: userId,
          name: widget.suggestion.styleName,
          itemIds: widget.suggestion.itemIds,
          description: widget.suggestion.outfitDescription,
          makeupTips: widget.suggestion.makeupTips,
          skincareTips: widget.suggestion.skincareTips,
          source: 'ai',
        );
    if (mounted) setState(() { _saving = false; if (ok) _saved = true; });
  }

  @override
  Widget build(BuildContext context) {
    final items = _matchedItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRose.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık bandı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5A2D4C), AppTheme.primaryRose],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          color: Colors.white),
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
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else if (_saved)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20)
                else
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Kaydet',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Kıyafet fotoğrafları
          if (items.isNotEmpty)
            SizedBox(
              height: 140,
              child: Row(
                children: items
                    .take(4)
                    .map((item) => Expanded(
                          child: ColoredBox(
                            color: const Color(0xFFFAF4F7),
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: 140,
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
                        ))
                    .toList(),
              ),
            ),

          // İçerik
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.suggestion.outfitDescription,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textMedium,
                      height: 1.6),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: AppTheme.dividerColor),
                ),
                _TipRow(
                    icon: Icons.brush_outlined,
                    label: 'Makyaj',
                    text: widget.suggestion.makeupTips),
                const SizedBox(height: 8),
                _TipRow(
                    icon: Icons.spa_outlined,
                    label: 'Cilt',
                    text: widget.suggestion.skincareTips),
                const SizedBox(height: 10),
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
                      const Icon(Icons.format_quote_rounded,
                          color: AppTheme.primaryRose, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.suggestion.motivationMessage,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                              fontStyle: FontStyle.italic,
                              height: 1.5),
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

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _TipRow(
      {required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.lightRose,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: AppTheme.primaryRose),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
              const SizedBox(height: 2),
              Text(text,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textMedium,
                      height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
