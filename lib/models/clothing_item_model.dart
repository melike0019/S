class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  final String category;
  final List<String> colors;
  final List<String> seasons;
  final String? brand;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastWornAt;
  final int wearCount;
  final String? fit;
  final String? fabric;
  final String? pattern;
  final String? style;
  final String? subCategory;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.category,
    required this.colors,
    required this.seasons,
    this.brand,
    this.notes,
    required this.createdAt,
    this.lastWornAt,
    this.wearCount = 0,
    this.fit,
    this.fabric,
    this.pattern,
    this.style,
    this.subCategory,
  });

  // Firestore'dan gelen veriyi Dart nesnesine çevir
  factory ClothingItem.fromFirestore(Map<String, dynamic> data, String id) {
    return ClothingItem(
      id: id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      colors: List<String>.from(data['colors'] ?? []),
      seasons: List<String>.from(data['seasons'] ?? []),
      brand: data['brand'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastWornAt: (data['lastWornAt'] as dynamic)?.toDate(),
      wearCount: data['wearCount'] ?? 0,
      fit: data['fit'],
      fabric: data['fabric'],
      pattern: data['pattern'],
      style: data['style'],
      subCategory: data['subCategory'],
    );
  }

  // Dart nesnesini Firestore'a yazılacak formata çevir
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'category': category,
      'colors': colors,
      'seasons': seasons,
      'brand': brand,
      'notes': notes,
      'createdAt': createdAt,
      'lastWornAt': lastWornAt,
      'wearCount': wearCount,
      'fit': fit,
      'fabric': fabric,
      'pattern': pattern,
      'style': style,
      'subCategory': subCategory,
    };
  }
}