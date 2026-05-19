import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clothing_item_model.dart';
import 'storage_service.dart';

class ClothingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Kullanıcının kıyafet koleksiyonuna kısayol
  CollectionReference _clothingRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing');
  }

  // --- KIYAFEt EKLE ---
  Future<ClothingItem> addClothingItem({
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
    try {
      // Önce fotoğrafı Storage'a yükle, URL al
      final imageUrl = await _storageService.uploadClothingImage(
        userId: userId,
        imageFile: imageFile,
      );

      // Kıyafet nesnesini oluştur
      final item = ClothingItem(
        id: '',
        userId: userId,
        imageUrl: imageUrl,
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
        createdAt: DateTime.now(),
      );

      // Firestore'a kaydet, Firestore otomatik ID üretsin
      final docRef = await _clothingRef(userId).add(item.toFirestore());

      // Firestore'un ürettiği ID ile güncel nesneyi döndür
      return ClothingItem(
        id: docRef.id,
        userId: userId,
        imageUrl: imageUrl,
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
        createdAt: item.createdAt,
      );
    } catch (e) {
      throw 'Kıyafet eklenemedi: $e';
    }
  }

  // --- TÜM KIYAFETLERİ GETİR ---
  Future<List<ClothingItem>> getClothingItems(String userId) async {
    try {
      final snapshot = await _clothingRef(userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ClothingItem.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw 'Kıyafetler alınamadı: $e';
    }
  }

  // --- KIYAFETLERİ STREAM OLARAK DİNLE ---
  Stream<List<ClothingItem>> watchClothingItems(String userId) {
    return _clothingRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ClothingItem.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // --- KIYAFETİ GÜNCELLE ---
  Future<void> updateClothingItem({
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
      final Map<String, dynamic> updates = {};

      if (category != null) updates['category'] = category;
      if (colors != null) updates['colors'] = colors;
      if (seasons != null) updates['seasons'] = seasons;
      if (brand != null) updates['brand'] = brand;
      if (notes != null) updates['notes'] = notes;
      if (fit != null) updates['fit'] = fit;
      if (fabric != null) updates['fabric'] = fabric;
      if (pattern != null) updates['pattern'] = pattern;
      if (style != null) updates['style'] = style;
      if (subCategory != null) updates['subCategory'] = subCategory;

      if (updates.isEmpty) return;

      await _clothingRef(userId).doc(itemId).update(updates);
    } catch (e) {
      throw 'Kıyafet güncellenemedi: $e';
    }
  }

  // --- KIYAFETİ SİL ---
  Future<void> deleteClothingItem({
    required String userId,
    required String itemId,
    required String imageUrl,
  }) async {
    try {
      // Önce Storage'dan fotoğrafı sil
      await _storageService.deleteImage(imageUrl);

      // Sonra Firestore'dan dokümanı sil
      await _clothingRef(userId).doc(itemId).delete();
    } catch (e) {
      throw 'Kıyafet silinemedi: $e';
    }
  }

  // --- GİYİLDİ OLARAK İŞARETLE ---
  Future<void> markAsWorn({
    required String userId,
    required String itemId,
  }) async {
    try {
      await _clothingRef(userId).doc(itemId).update({
        'lastWornAt': DateTime.now(),
        'wearCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw 'Güncellenemedi: $e';
    }
  }

  // --- KATEGORİYE GÖRE FİLTRELE ---
  Future<List<ClothingItem>> getByCategory({
    required String userId,
    required String category,
  }) async {
    try {
      final snapshot = await _clothingRef(userId)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ClothingItem.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw 'Kıyafetler filtrelenemedi: $e';
    }
  }
}