import 'dart:io';
import 'package:flutter/material.dart';
import '../models/clothing_item_model.dart';
import '../services/clothing_service.dart';
import 'dart:async';

enum ClothingStatus { initial, loading, loaded, error }

class ClothingProvider extends ChangeNotifier {
  final ClothingService _clothingService = ClothingService();
  StreamSubscription? _itemsSubscription;

  ClothingStatus _status = ClothingStatus.initial;
  List<ClothingItem> _items = [];
  String? _errorMessage;
  String _selectedCategory = 'Tümü';

  ClothingStatus get status => _status;
  List<ClothingItem> get items => _items;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ClothingStatus.loading;
  String get selectedCategory => _selectedCategory;
  bool get isEmpty => _items.isEmpty;

  // Kategoriye göre filtrelenmiş liste
  List<ClothingItem> get filteredItems {
    if (_selectedCategory == 'Tümü') return _items;
    return _items
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  // Kategorilerin listesi (tekrarsız)
  List<String> get categories {
    final cats = _items.map((item) => item.category).toSet().toList();
    return ['Tümü', ...cats];
  }

  // 30+ gündür giyilmemiş kıyafetler (kör nokta analizi)
  List<ClothingItem> get forgottenItems {
    final threshold = DateTime.now().subtract(const Duration(days: 30));
    return _items.where((item) {
      final lastDate = item.lastWornAt ?? item.createdAt;
      return lastDate.isBefore(threshold);
    }).toList();
  }

  // --- KIYAFETLERİ YÜKLE ---
  Future<void> loadItems(String userId) async {
    _setLoading();
    try {
      final items = await _clothingService.getClothingItems(userId);
      _items = items;
      _status = ClothingStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- KIYAFETLERİ STREAM İLE DİNLE ---
  void watchItems(String userId) {
    _itemsSubscription?.cancel();
    
    _itemsSubscription = _clothingService
        .watchClothingItems(userId)
        .listen(
          (items) {
            _items = items;
            _status = ClothingStatus.loaded;
            notifyListeners();
          },
          onError: (e) {
            _setError(e.toString());
          },
        );
  }
  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }

  // --- KIYAFEt EKLE ---
  Future<bool> addItem({
    required String userId,
    required File imageFile,
    required String category,
    required List<String> colors,
    required List<String> seasons,
    String? brand,
    String? notes,
    String? fit,
    String? fabric,
    String? pattern,
    String? style,
    String? subCategory,
  }) async {
    _setLoading();
    try {
      await _clothingService.addClothingItem(
        userId: userId,
        imageFile: imageFile,
        category: category,
        colors: colors,
        seasons: seasons,
        brand: brand,
        notes: notes,
        fit: fit,
        fabric: fabric,
        pattern: pattern,
        style: style,
        subCategory: subCategory,
      );
      // watchItems stream'i Firestore'dan değişikliği zaten alacak,
      // burada manuel ekleme yapmıyoruz — çift gösterim önlenir.
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- KIYAFETİ SİL ---
  Future<bool> deleteItem({
    required String userId,
    required String itemId,
    required String imageUrl,
  }) async {
    try {
      await _clothingService.deleteClothingItem(
        userId: userId,
        itemId: itemId,
        imageUrl: imageUrl,
      );

      // Lokal listeden çıkar
      _items = _items.where((item) => item.id != itemId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- KIYAFETİ GÜNCELLE ---
  Future<bool> updateItem({
    required String userId,
    required String itemId,
    String? category,
    List<String>? colors,
    List<String>? seasons,
    String? brand,
    String? notes,
    String? fit,
    String? fabric,
    String? pattern,
    String? style,
    String? subCategory,
  }) async {
    try {
      await _clothingService.updateClothingItem(
        userId: userId,
        itemId: itemId,
        category: category,
        colors: colors,
        seasons: seasons,
        brand: brand,
        notes: notes,
        fit: fit,
        fabric: fabric,
        pattern: pattern,
        style: style,
        subCategory: subCategory,
      );

      // Lokal listede güncelle
      _items = _items.map((item) {
        if (item.id == itemId) {
          return ClothingItem(
            id: item.id,
            userId: item.userId,
            imageUrl: item.imageUrl,
            category: category ?? item.category,
            colors: colors ?? item.colors,
            seasons: seasons ?? item.seasons,
            brand: brand ?? item.brand,
            notes: notes ?? item.notes,
            fit: fit ?? item.fit,
            fabric: fabric ?? item.fabric,
            pattern: pattern ?? item.pattern,
            style: style ?? item.style,
            subCategory: subCategory ?? item.subCategory,
            createdAt: item.createdAt,
            lastWornAt: item.lastWornAt,
            wearCount: item.wearCount,
          );
        }
        return item;
      }).toList();

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- GİYİLDİ OLARAK İŞARETLE ---
  Future<void> markAsWorn({
    required String userId,
    required String itemId,
  }) async {
    try {
      await _clothingService.markAsWorn(
        userId: userId,
        itemId: itemId,
      );

      // Lokal listede güncelle
      _items = _items.map((item) {
        if (item.id == itemId) {
          return ClothingItem(
            id: item.id,
            userId: item.userId,
            imageUrl: item.imageUrl,
            category: item.category,
            colors: item.colors,
            seasons: item.seasons,
            brand: item.brand,
            notes: item.notes,
            fit: item.fit,
            fabric: item.fabric,
            pattern: item.pattern,
            style: item.style,
            subCategory: item.subCategory,
            createdAt: item.createdAt,
            lastWornAt: DateTime.now(),
            wearCount: item.wearCount + 1,
          );
        }
        return item;
      }).toList();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- KATEGORİ SEÇ ---
  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // --- LİSTEYİ TEMİZLE ---
  void clearItems() {
    _items = [];
    _status = ClothingStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  // --- YARDIMCI METODLAR ---
  void _setLoading() {
    _status = ClothingStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ClothingStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}