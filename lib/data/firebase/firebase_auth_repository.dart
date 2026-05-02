// firebase_auth_repository.dart
// Produktions-Implementierung von IAuthRepository via Firebase Auth + Firestore.

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/license_request.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  bool _isAdmin = false;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance {
    final currentUser = _auth.currentUser;
    if (currentUser != null) _loadAdminStatus(currentUser.uid);
  }

  Future<void> _loadAdminStatus(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    _isAdmin = doc.data()?['isAdmin'] == true;
  }

  // Minimales AppUser-Objekt aus Firebase Auth (ohne Firestore-Daten).
  // Wird nur für den Rückgabewert von signIn/register verwendet.
  AppUser _mapUser(User fbUser) => AppUser(
        userId: fbUser.uid,
        name: fbUser.displayName ?? '',
        email: fbUser.email ?? '',
        photoUrl: fbUser.photoURL,
        emailVerified: fbUser.emailVerified,
      );

  // Vollständiges AppUser-Objekt aus Firebase Auth + Firestore-Dokument.
  AppUser _toAppUser(User fbUser, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final carData = data['car'] as Map<String, dynamic>?;
    return AppUser(
      userId: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      photoUrl: fbUser.photoURL,
      emailVerified: data['emailVerified'] as bool? ?? fbUser.emailVerified,
      phone: data['phone'] as String?,
      phoneVerified: data['phoneVerified'] as bool? ?? false,
      licenseStatus: data['licenseStatus'] as String? ?? 'none',
      homeTown: data['homeTown'] as String?,
      homeTownLat: (data['homeTownLat'] as num?)?.toDouble(),
      homeTownLng: (data['homeTownLng'] as num?)?.toDouble(),
      car: carData != null ? CarInfo.fromMap(carData) : null,
      licenseRejectReason: data['licenseRejectReason'] as String?,
    );
  }

  @override
  AppUser? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _mapUser(fbUser);
  }

  // Kombiniert Firebase Auth-Stream mit dem Firestore-Nutzerdokument.
  // Jede Änderung am Firestore-Dokument (Telefon, Führerschein, Auto, ...)
  // löst automatisch einen Rebuild in der UI aus.
  //
  // switchMap-Verhalten: beim Logout wird der Firestore-Stream sofort
  // abgebrochen, damit der nächste Login-Event nicht gepuffert bleibt.
  @override
  Stream<AppUser?> get authStateChanges {
    StreamSubscription<dynamic>? firestoreSub;
    StreamSubscription<User?>? authSub;
    late final StreamController<AppUser?> controller;

    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.userChanges().listen(
          (fbUser) {
            firestoreSub?.cancel();
            firestoreSub = null;
            if (fbUser == null) {
              controller.add(null);
              return;
            }
            firestoreSub = _firestore
                .collection('users')
                .doc(fbUser.uid)
                .snapshots()
                .listen(
                  (doc) {
                    _isAdmin = doc.data()?['isAdmin'] == true;
                    controller.add(_toAppUser(fbUser, doc));
                  },
                  onError: controller.addError,
                );
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        firestoreSub?.cancel();
        authSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user!;

    String name = fbUser.displayName ?? '';
    if (name.isEmpty) {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        name = '${data['firstName']} ${data['lastName']}';
        await fbUser.updateDisplayName(name);
      }
    }

    await _loadAdminStatus(fbUser.uid);
    return _mapUser(fbUser);
  }

  @override
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user!;
    final fullName = '$firstName $lastName';

    await fbUser.updateDisplayName(fullName);

    await _firestore.collection('users').doc(fbUser.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': '',
      'phoneVerified': false,
      'homeTown': '',
      'emailVerified': false,
      'licenseStatus': 'none',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return _mapUser(fbUser);
  }

  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() async {
    _isAdmin = false;
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _storage.ref('users/${user.uid}/profile.jpg').delete();
    } catch (_) {}
    try {
      await _storage.ref('users/${user.uid}/license.jpg').delete();
    } catch (_) {}

    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  @override
  Future<bool> isSignedIn() async => _auth.currentUser != null;

  @override
  bool get isAdmin => _isAdmin;

  @override
  Future<void> setHomeTown(String town, {double? lat, double? lng}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final update = <String, dynamic>{'homeTown': town};
    if (lat != null) update['homeTownLat'] = lat;
    if (lng != null) update['homeTownLng'] = lng;
    await _firestore.collection('users').doc(uid).update(update);
  }

  @override
  Future<String?> getHomeTown() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['homeTown'] as String?;
  }

  @override
  Future<({double? lat, double? lng})> getHomeTownCoords() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return (lat: null, lng: null);
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    return (
      lat: (data?['homeTownLat'] as num?)?.toDouble(),
      lng: (data?['homeTownLng'] as num?)?.toDouble(),
    );
  }

  @override
  Future<String> uploadProfilePhoto(File image) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Nicht eingeloggt');

    final ref = _storage.ref('users/$uid/profile.jpg');
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    await _auth.currentUser!.updatePhotoURL(url);
    await _firestore.collection('users').doc(uid).update({'photoUrl': url});

    return url;
  }

  // ── E-Mail-Verifizierung ───────────────────────────────────────────────────

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
  }

  @override
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    if (verified) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'emailVerified': true});
    }
    return verified;
  }

  // ── Telefon ────────────────────────────────────────────────────────────────

  @override
  Future<void> savePhone(String phone) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'phone': phone,
      'phoneVerified': true,
    });
  }

  @override
  Future<void> startPhoneVerification(
    String phone, {
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential cred) async {
        // Android: automatisch erkannter Code
        try {
          await _auth.currentUser!.linkWithCredential(cred);
          await savePhone(phone);
        } catch (_) {
          await _auth.currentUser!.updatePhoneNumber(cred);
          await savePhone(phone);
        }
      },
      verificationFailed: (FirebaseAuthException e) =>
          onError(e.message ?? 'Verifizierung fehlgeschlagen'),
      codeSent: (String verificationId, int? resendToken) =>
          onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<void> confirmPhoneCode(
      String verificationId, String smsCode) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    try {
      await _auth.currentUser!.linkWithCredential(cred);
    } catch (_) {
      await _auth.currentUser!.updatePhoneNumber(cred);
    }
    final phone = _auth.currentUser?.phoneNumber ?? '';
    await savePhone(phone);
  }

  // ── Führerschein ───────────────────────────────────────────────────────────

  @override
  Future<void> uploadLicense(File image) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Nicht eingeloggt');
    final uid = fbUser.uid;
    final path = 'users/$uid/license.jpg';

    final ref = _storage.ref(path);
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    // Kein getDownloadURL() – nur der Pfad wird gespeichert

    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {
      'licenseStatus': 'pending',
      'licenseRejectReason': FieldValue.delete(),
    });
    batch.set(_firestore.collection('licenseRequests').doc(uid), {
      'uid': uid,
      'userName': fbUser.displayName ?? '',
      'userPhotoUrl': fbUser.photoURL,
      'licensePath': path,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'rejectReason': null,
    });
    await batch.commit();
  }

  // ── Admin: Führerschein-Prüfung ────────────────────────────────────────────

  @override
  Stream<List<LicenseRequest>> get pendingLicenseRequests => _firestore
      .collection('licenseRequests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) {
        final list = s.docs.map(LicenseRequest.fromDoc).toList();
        list.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
        return list;
      });

  @override
  Future<void> approveLicense(String userId) async {
    final doc =
        await _firestore.collection('licenseRequests').doc(userId).get();
    if (doc.data()?['status'] != 'pending') return;

    final batch = _firestore.batch();
    batch.update(doc.reference, {
      'status': 'verified',
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('users').doc(userId), {
      'licenseStatus': 'verified',
    });
    await batch.commit();
  }

  @override
  Future<void> rejectLicense(String userId, String reason) async {
    final doc =
        await _firestore.collection('licenseRequests').doc(userId).get();
    if (doc.data()?['status'] != 'pending') return;

    final batch = _firestore.batch();
    batch.update(doc.reference, {
      'status': 'rejected',
      'rejectReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('users').doc(userId), {
      'licenseStatus': 'rejected',
      'licenseRejectReason': reason,
    });
    await batch.commit();
  }

  // ── Auto-Infos ─────────────────────────────────────────────────────────────

  @override
  Future<void> updateCarInfo(
      String make, String model, String? color, int? seats) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'car': CarInfo(make: make, model: model, color: color, seats: seats)
          .toMap(),
    });
  }
}
