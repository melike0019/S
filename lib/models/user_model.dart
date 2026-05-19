import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final int xpPoints;
  final List<String> badges;
  final DateTime createdAt;
  final String? styleProfile;
  /// Doğum tarihi (tam gün bilgisi; saat kullanılmaz).
  final DateTime? birthDate;
  /// Batı güneş burcu, Türkçe (örn. Yay). [birthDate] yoksa null olabilir.
  final String? zodiacSign;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.xpPoints = 0,
    this.badges = const [],
    required this.createdAt,
    this.styleProfile,
    this.birthDate,
    this.zodiacSign,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? birth;
    final rawBirth = data['birthDate'];
    if (rawBirth is Timestamp) {
      birth = rawBirth.toDate();
    }

    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      xpPoints: data['xpPoints'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      styleProfile: data['styleProfile'],
      birthDate: birth,
      zodiacSign: data['zodiacSign'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'xpPoints': xpPoints,
      'badges': badges,
      'createdAt': createdAt,
      'styleProfile': styleProfile,
      if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
      if (zodiacSign != null && zodiacSign!.isNotEmpty) 'zodiacSign': zodiacSign,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    int? xpPoints,
    List<String>? badges,
    String? styleProfile,
    DateTime? birthDate,
    String? zodiacSign,
    bool clearBirthDate = false,
    bool clearZodiacSign = false,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      xpPoints: xpPoints ?? this.xpPoints,
      badges: badges ?? this.badges,
      createdAt: createdAt,
      styleProfile: styleProfile ?? this.styleProfile,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      zodiacSign: clearZodiacSign ? null : (zodiacSign ?? this.zodiacSign),
    );
  }
}
