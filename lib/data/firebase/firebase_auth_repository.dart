// firebase_auth_repository.dart
// Produktions-Implementierung von IAuthRepository via Firebase Auth + Firestore.
// Ersetzt LocalAuthRepository sobald in main.dart eingebunden.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Mappt einen Firebase-User auf AppUser.
  // Name kommt aus displayName (wird bei register() gesetzt).
  @override
  AppUser? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return AppUser(
      userId: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return AppUser(
        userId: fbUser.uid,
        name: fbUser.displayName ?? '',
        email: fbUser.email ?? '',
      );
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

    return AppUser(
      userId: fbUser.uid,
      name: name,
      email: fbUser.email ?? '',
    );
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
    });

    return AppUser(
      userId: fbUser.uid,
      name: fullName,
      email: email,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  @override
  Future<bool> isSignedIn() async => _auth.currentUser != null;

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
}
