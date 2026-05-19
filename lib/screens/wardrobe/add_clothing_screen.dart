import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/badge_checker.dart';

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  File? _imageFile;
  String _selectedCategory = 'Üst Giyim';
  final List<String> _selectedColors = [];
  final List<String> _selectedSeasons = [];
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  final _fitController = TextEditingController();
  final _fabricController = TextEditingController();
  final _patternController = TextEditingController();
  final _styleController = TextEditingController();
  final _subCategoryController = TextEditingController();
  bool _saving = false;
  bool _isAnalyzing = false;

  final List<String> _categories = [
    'Üst Giyim',
    'Alt Giyim',
    'Dış Giyim',
    'Elbise / Tulum',
    'Aksesuar',
    'Ayakkabı',
    'Çanta',
    'Diğer',
  ];

  final List<String> _colors = [
    'Siyah',
    'Beyaz',
    'Gri',
    'Lacivert',
    'Mavi',
    'Yeşil',
    'Kırmızı',
    'Pembe',
    'Mor',
    'Sarı',
    'Turuncu',
    'Bej',
    'Kahverengi',
  ];

  final List<String> _seasons = [
    'İlkbahar',
    'Yaz',
    'Sonbahar',
    'Kış',
  ];

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
  void dispose() {
    _brandController.dispose();
    _notesController.dispose();
    _fitController.dispose();
    _fabricController.dispose();
    _patternController.dispose();
    _styleController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;

    // Kırpma ekranını aç
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı Düzenle',
          toolbarColor: const Color(0xFFB05070),
          toolbarWidgetColor: Colors.white,
          statusBarLight: false,
          activeControlsWidgetColor: const Color(0xFFB05070),
          backgroundColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Fotoğrafı Düzenle',
          cancelButtonTitle: 'İptal',
          doneButtonTitle: 'Tamam',
        ),
      ],
    );

    if (cropped != null && mounted) {
      final file = File(cropped.path);
      setState(() => _imageFile = file);
      _analyzeImage(file);
    }
  }

  Future<void> _analyzeImage(File file) async {
    setState(() => _isAnalyzing = true);
    try {
      final aiService = AIService();
      final data = await aiService.analyzeClothingImage(file);
      if (data != null && mounted) {
        setState(() {
          if (data['category'] != null) {
            final cat = data['category'].toString();
            if (!_categories.contains(cat)) _categories.add(cat);
            _selectedCategory = cat;
          }
          if (data['subCategory'] != null) {
            _subCategoryController.text = data['subCategory'].toString();
          }
          if (data['colors'] != null) {
            _selectedColors.clear();
            for (final c in data['colors']) {
              final colorStr = c.toString();
              if (!_colors.contains(colorStr)) _colors.add(colorStr);
              _selectedColors.add(colorStr);
            }
          }
          if (data['seasons'] != null) {
            _selectedSeasons.clear();
            for (final s in data['seasons']) {
              final seasonStr = s.toString();
              if (!_seasons.contains(seasonStr)) _seasons.add(seasonStr);
              _selectedSeasons.add(seasonStr);
            }
          }
          if (data['fit'] != null) _fitController.text = data['fit'];
          if (data['fabric'] != null) _fabricController.text = data['fabric'];
          if (data['pattern'] != null) _patternController.text = data['pattern'];
          if (data['style'] != null) _styleController.text = data['style'];
        });
        _showSnack('Yapay zeka kıyafeti analiz etti! Özellikleri kontrol edin.');
      } else {
        _showSnack('Yapay zeka analiz sonucu boş döndü.');
      }
    } catch (e) {
      _showSnack('Yapay zeka analizi başarısız: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Fotoğraf Çek'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_imageFile == null) {
      _showSnack('Lütfen bir fotoğraf seçin.');
      return;
    }
    if (_selectedColors.isEmpty) {
      _showSnack('En az bir renk seçin.');
      return;
    }
    if (_selectedSeasons.isEmpty) {
      _showSnack('En az bir mevsim seçin.');
      return;
    }

    setState(() => _saving = true);

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _saving = false);
      return;
    }

    final ok = await context.read<ClothingProvider>().addItem(
          userId: userId,
          imageFile: _imageFile!,
          category: _selectedCategory,
          colors: List.from(_selectedColors),
          seasons: List.from(_selectedSeasons),
          brand: _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          fit: _fitController.text.trim().isEmpty
              ? null
              : _fitController.text.trim(),
          fabric: _fabricController.text.trim().isEmpty
              ? null
              : _fabricController.text.trim(),
          pattern: _patternController.text.trim().isEmpty
              ? null
              : _patternController.text.trim(),
          style: _styleController.text.trim().isEmpty
              ? null
              : _styleController.text.trim(),
          subCategory: _subCategoryController.text.trim().isEmpty
              ? null
              : _subCategoryController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      // Rozet kontrolü — kıyafet sayısı değişti
      unawaited(checkBadgesAndNotify(context));
      Navigator.pop(context);
    } else {
      _showSnack(
        context.read<ClothingProvider>().errorMessage ?? 'Kıyafet eklenemedi.',
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
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
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18,
                    color: AppTheme.textDark),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: _saving ? null : AppTheme.primaryGradient,
                      color: _saving ? AppTheme.textFaint : null,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      boxShadow: _saving ? null : AppTheme.softShadow,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Kaydet',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.deepRose, AppTheme.darkRose, AppTheme.primaryRose,
                        const Color(0xFFD4809A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20, top: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 60, bottom: -10,
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            child: const Icon(Icons.add_circle_outline_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('Kıyafet Ekle',
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 22, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fotoğraf seçici
                  GestureDetector(
                    onTap: _imageFile == null ? _showImageSourceSheet : null,
                    child: Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        color: AppTheme.bgMid,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        border: Border.all(color: AppTheme.dividerColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: AppTheme.softShadow,
                                  ),
                                  child: const Icon(Icons.add_photo_alternate_outlined,
                                      size: 32, color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Fotoğraf eklemek için dokun',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.textMedium,
                                      fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Kamera veya galeri',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.textLight, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightRose,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusFull),
                                    border: Border.all(
                                        color: AppTheme.primaryRose.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '✨ AI ile otomatik analiz',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.primaryRose,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_imageFile!, fit: BoxFit.contain),
                                if (_isAnalyzing)
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.6),
                                          AppTheme.deepRose.withValues(alpha: 0.4),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 60, height: 60,
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.primaryGradient,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.5, color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Yapay Zeka Analiz Ediyor...',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                Positioned(
                                  top: 12, right: 12,
                                  child: GestureDetector(
                                    onTap: _showImageSourceSheet,
                                    child: Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: AppTheme.softShadow,
                                      ),
                                      child: const Icon(Icons.edit_rounded,
                                          size: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel('Kategori'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: selected ? AppTheme.primaryGradient : null,
                            color: selected ? null : Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : AppTheme.dividerColor,
                            ),
                            boxShadow: selected ? AppTheme.softShadow : null,
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: selected ? Colors.white : AppTheme.textMedium,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel('Renk'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _colors.map((colorName) {
                      final isSelected = _selectedColors.contains(colorName);
                      final c = _colorMap[colorName] ?? Colors.grey;
                      return GestureDetector(
                        onTap: () => setState(() {
                          isSelected
                              ? _selectedColors.remove(colorName)
                              : _selectedColors.add(colorName);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c.withAlpha(30)
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            border: Border.all(
                              color: isSelected ? c : AppTheme.dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.grey.shade300, width: 0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(colorName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.textDark)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel('Mevsim'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _seasons.map((season) {
                      final isSelected = _selectedSeasons.contains(season);
                      return GestureDetector(
                        onTap: () => setState(() {
                          isSelected
                              ? _selectedSeasons.remove(season)
                              : _selectedSeasons.add(season);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppTheme.primaryGradient
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppTheme.dividerColor,
                            ),
                            boxShadow: isSelected ? AppTheme.softShadow : null,
                          ),
                          child: Text(
                            season,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppTheme.textMedium,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel('Marka (İsteğe Bağlı)'),
                  const SizedBox(height: 10),
                  _premiumTextField(
                    controller: _brandController,
                    hint: 'Örn: Zara, H&M, Mango...',
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 28),

                  // AI stil detayları bölümü
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.lightRose.withValues(alpha: 0.5), Colors.white],
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
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSM),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Stil Detayları (AI ile dolduruldu)',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _premiumTextField(
                                controller: _fitController,
                                hint: 'Kalıp/Kesim',
                                label: 'Kalıp',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _premiumTextField(
                                controller: _fabricController,
                                hint: 'Kumaş',
                                label: 'Kumaş',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _premiumTextField(
                                controller: _patternController,
                                hint: 'Desen',
                                label: 'Desen',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _premiumTextField(
                                controller: _styleController,
                                hint: 'Tarz',
                                label: 'Tarz',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _SectionLabel('Notlar (İsteğe Bağlı)'),
                  const SizedBox(height: 10),
                  _premiumTextField(
                    controller: _notesController,
                    hint: 'Kıyafet hakkında notlar...',
                    maxLines: 3,
                    action: TextInputAction.done,
                  ),
                  const SizedBox(height: 36),

                  // Kaydet butonu
                  GestureDetector(
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
                            : Text(
                                'Gardıroba Ekle',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumTextField({
    required TextEditingController controller,
    required String hint,
    String? label,
    int maxLines = 1,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: action,
      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.primaryRose, width: 1.5),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

