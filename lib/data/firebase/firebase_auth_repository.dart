// firebase_auth_repository.dart
// Produktions-Implementierung von IAuthRepository via Firebase Auth + Firestore.
// Ersetzt LocalAuthRepository sobald in main.dart eingebunden.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Mappt einen Firebase-User auf AppUser.
  // Name kommt aus displayName, photoUrl aus photoURL.
  AppUser _mapUser(User fbUser) => AppUser(
        userId: fbUser.uid,
        name: fbUser.displayName ?? '',
        email: fbUser.email ?? '',
        photoUrl: fbUser.photoURL,
      );

  @override
  AppUser? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _mapUser(fbUser);
  }

  // userChanges() feuert auch bei Profil-Updates (photoURL, displayName),
  // nicht nur bei Sign-in/Sign-out wie authStateChanges().
  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.userChanges().map((fbUser) {
      if (fbUser == null) return null;
      return _mapUser(fbUser);
    });
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user!;

    // displayName ist bei bestehenden Nutzern gesetzt.
    // Fallback: Firestore-Dokument lesen.
    String name = fbUser.displayName ?? '';
    if (name.isEmpty) {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        name = '${data['firstName']} ${data['lastName']}';
        await fbUser.updateDisplayName(name);
      }
    }

    return _mapUser(fbUser);
  }

  @override
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user!;
    final fullName = '$firstName $lastName';

    // displayName in Firebase Auth setzen (macht currentUser getter sofort nutzbar)
    await fbUser.updateDisplayName(fullName);

    // Nutzerprofil in Firestore anlegen
    await _firestore.collection('users').doc(fbUser.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'homeTown': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return _mapUser(fbUser);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Profilbild aus Storage entfernen (ignorieren falls nicht vorhanden)
    try {
      await _storage.ref('users/${user.uid}/profile.jpg').delete();
    } catch (_) {}

    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  @override
  Future<bool> isSignedIn() async => _auth.currentUser != null;

  static const _adminUid = 'vA8UdBXsdCPD3ePJ88j4C3MQtjJ2';

  @override
  bool get isAdmin => _auth.currentUser?.uid == _adminUid;

  @override
  Future<void> setHomeTown(String town) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({'homeTown': town});
  }

  @override
  Future<String?> getHomeTown() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['homeTown'] as String?;
  }

  @override
  Future<String> uploadProfilePhoto(File image) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Nicht eingeloggt');

    // Upload nach: users/{uid}/profile.jpg
    final ref = _storage.ref('users/$uid/profile.jpg');
    await ref.putFile(
      image,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = await ref.getDownloadURL();

    // URL in Firebase Auth und Firestore speichern
    await _auth.currentUser!.updatePhotoURL(url);
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'photoUrl': url});

    return url;
  }
}
