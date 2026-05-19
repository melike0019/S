import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/zodiac_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Mevcut kullanıcıyı stream olarak dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut Firebase kullanıcısı
  User? get currentUser => _auth.currentUser;

  // --- KAYIT OL ---
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
    required DateTime birthDate,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      // Firebase Auth display name güncelle
      await user.updateDisplayName(displayName);

      final zodiac = westernZodiacTurkish(birthDate);

      // Firestore'a kullanıcı dokümanı oluştur
      final userModel = UserModel(
        id: user.uid,
        email: email,
        displayName: displayName,
        xpPoints: 0,
        badges: [],
        createdAt: DateTime.now(),
        birthDate: birthDate,
        zodiacSign: zodiac,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // --- GİRİŞ YAP ---
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      // Firestore'dan kullanıcı verisini al
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        var model = UserModel.fromFirestore(doc.data()!, doc.id);
        // Firestore'da displayName boşsa Firebase Auth'tan al
        if (model.displayName.isEmpty) {
          final fbName = user.displayName ?? '';
          if (fbName.isNotEmpty) model = model.copyWith(displayName: fbName);
        }
        return model;
      }

      // Firestore belgesi yoksa Firebase Auth verisinden oluştur
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // --- ÇIKIŞ YAP ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- ŞİFRE SIFIRLA ---
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // --- GOOGLE İLE GİRİŞ ---
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı iptal etti

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      // Firestore belgesini kontrol et / oluştur
      final ref = _firestore.collection('users').doc(user.uid);
      final doc = await ref.get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }

      // Yeni kullanıcı — Firestore'a kaydet
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? googleUser.displayName ?? '',
        photoURL: user.photoURL,
        xpPoints: 0,
        badges: [],
        createdAt: DateTime.now(),
      );
      await ref.set(userModel.toFirestore());
      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw 'Bu e-posta adresi zaten e-posta/şifre ile kayıtlı. '
            'Lütfen e-posta ve şifrenizle giriş yapın.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google ile giriş başarısız: $e';
    }
  }

  // --- HESAP SİL ---
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userRef = _firestore.collection('users').doc(uid);

    // Alt koleksiyonları sil
    const subcollections = ['wardrobe', 'outfits', 'history', 'weeklyPlan', 'planner'];
    for (final col in subcollections) {
      final snap = await userRef.collection(col).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    // Firebase Storage: kıyafet fotoğrafları
    try {
      final clothingRef = FirebaseStorage.instance.ref().child('clothing/$uid');
      final list = await clothingRef.listAll();
      for (final item in list.items) {
        await item.delete();
      }
    } catch (_) {
      // Klasör yoksa sessizce geç
    }

    // Firebase Storage: profil fotoğrafı
    try {
      await FirebaseStorage.instance
          .ref()
          .child('users/$uid/profile.jpg')
          .delete();
    } catch (_) {}

    // Ana Firestore dokümanını sil
    await userRef.delete();

    // Firebase Auth hesabını sil
    await user.delete();
  }

  // --- HATA YÖNETİMİ ---
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre yanlış.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}