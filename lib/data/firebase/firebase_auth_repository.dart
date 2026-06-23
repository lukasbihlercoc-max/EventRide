// firebase_auth_repository.dart
// Produktions-Implementierung von IAuthRepository via Firebase Auth + Firestore.

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/event_request.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/license_request.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  bool _isAdmin = false;
  AppUser? _cachedUser;

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

  // Setzt createdAt für Altaccounts die vor dem Feld angelegt wurden.
  // Nutzt Firebase Auth metadata.creationTime als Quelle.
  Future<void> _backfillCreatedAt(User fbUser) async {
    try {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data()?['createdAt'] == null) {
        final creationTime = fbUser.metadata.creationTime;
        if (creationTime != null) {
          await _firestore.collection('users').doc(fbUser.uid).update({
            'createdAt': Timestamp.fromDate(creationTime),
          });
        }
      }
    } catch (_) {}
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
      name: () {
        final first = data['firstName'] as String? ?? '';
        final last  = data['lastName']  as String? ?? '';
        final fs    = '$first $last'.trim();
        return fs.isNotEmpty ? fs : (fbUser.displayName ?? '');
      }(),
      email: fbUser.email ?? '',
      photoUrl: data['photoUrl'] as String? ?? fbUser.photoURL,
      emailVerified: data['emailVerified'] as bool? ?? fbUser.emailVerified,
      phone: data['phone'] as String?,
      phoneVerified: data['phoneVerified'] as bool? ?? false,
      licenseStatus: data['licenseStatus'] as String? ?? 'none',
      homeTown: data['homeTown'] as String?,
      homeTownLat: (data['homeTownLat'] as num?)?.toDouble(),
      homeTownLng: (data['homeTownLng'] as num?)?.toDouble(),
      car: carData != null ? CarInfo.fromMap(carData) : null,
      licenseRejectReason: data['licenseRejectReason'] as String?,
      ratingAvg: (data['ratingAvg'] as num?)?.toDouble(),
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  AppUser? get currentUser {
    if (_cachedUser != null) return _cachedUser;
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
              _cachedUser = null;
              controller.add(null);
              return;
            }
            _backfillCreatedAt(fbUser);
            firestoreSub = _firestore
                .collection('users')
                .doc(fbUser.uid)
                .snapshots()
                .listen(
                  (doc) {
                    _isAdmin = doc.data()?['isAdmin'] == true;
                    _cachedUser = _toAppUser(fbUser, doc);
                    controller.add(_cachedUser!);
                  },
                  onError: (_) {
                    // Firestore-Fehler (z.B. PERMISSION_DENIED kurz nach Logout)
                    // nicht an Subscriber propagieren – kein onError-Handler dort.
                  },
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
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Fahrten des Users holen und Anfragen auf fahrtGeloescht setzen
    final fahrtenSnap = await _firestore
        .collection('fahrten')
        .where('ownerId', isEqualTo: uid)
        .get();

    for (final fahrtDoc in fahrtenSnap.docs) {
      final anfragenSnap = await _firestore
          .collection('anfragen')
          .where('fahrtId', isEqualTo: fahrtDoc.id)
          .where('status', whereIn: [
            0, // offen
            1, // akzeptiert
          ])
          .get();

      final batch = _firestore.batch();
      for (final a in anfragenSnap.docs) {
        batch.update(a.reference, {
          'status': 4, // fahrtGeloescht
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      batch.delete(fahrtDoc.reference);
      await batch.commit();
    }

    // Eigene offene/akzeptierte Anfragen als Mitfahrer auf storniert setzen
    final myAnfragenSnap = await _firestore
        .collection('anfragen')
        .where('requesterId', isEqualTo: uid)
        .where('status', whereIn: [
          0, // offen
          1, // akzeptiert
        ])
        .get();

    if (myAnfragenSnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in myAnfragenSnap.docs) {
        batch.update(doc.reference, {
          'status': 3, // storniert
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      await batch.commit();
    }

    // Interessenten-Einträge löschen
    final interessentenSnap = await _firestore
        .collection('interessenten')
        .where('userId', isEqualTo: uid)
        .get();

    if (interessentenSnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in interessentenSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Chat-Conversations und deren Messages löschen
    final chatsSnap = await _firestore
        .collection('chat_conversations')
        .where('participants', arrayContains: uid)
        .get();

    for (final chatDoc in chatsSnap.docs) {
      final messagesSnap =
          await chatDoc.reference.collection('messages').get();
      final batch = _firestore.batch();
      for (final msg in messagesSnap.docs) {
        batch.delete(msg.reference);
      }
      batch.delete(chatDoc.reference);
      await batch.commit();
    }

    // Storage-Dateien löschen
    try {
      await _storage.ref('users/$uid/profile.jpg').delete();
    } catch (_) {}
    try {
      await _storage.ref('users/$uid/license.jpg').delete();
    } catch (_) {}

    // Reviews bleiben bewusst erhalten: sie sind historische Vertrauensnachweise
    // und dürfen nur vom Admin gelöscht werden. Der reviewerName ist ein Snapshot
    // zum Zeitpunkt der Bewertung; das User-Dokument selbst wird unten gelöscht.

    // Eigene Event-Requests löschen
    final eventRequestsSnap = await _firestore
        .collection('eventRequests')
        .where('uid', isEqualTo: uid)
        .get();
    if (eventRequestsSnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in eventRequestsSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Firestore-Dokumente des Users löschen (User-Doc enthält auch FCM-Token)
    final userBatch = _firestore.batch();
    userBatch.delete(_firestore.collection('users').doc(uid));
    userBatch.delete(_firestore.collection('licenseRequests').doc(uid));
    await userBatch.commit();

    // Firebase-Auth-Account löschen
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
    await user.sendEmailVerification(
      ActionCodeSettings(
        url: 'https://eventride.at/auth/email-action.html',
        handleCodeInApp: true,
        iOSBundleId: 'at.eventride.app',
        androidPackageName: 'at.eventride.app',
        androidInstallApp: false,
      ),
    );
  }

  @override
  Future<void> changeEmail(String newEmail, String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await user.verifyBeforeUpdateEmail(newEmail);

    // Nur emailVerified zurücksetzen — das email-Feld darf laut Firestore-Regel
    // nicht durch den User selbst geändert werden (Schutz vor Manipulation).
    // Die tatsächliche E-Mail-Adresse in Firebase Auth wird erst aktualisiert,
    // nachdem der User auf den Link in der neuen Inbox geklickt hat.
    await _firestore.collection('users').doc(user.uid).update({
      'emailVerified': false,
    });
  }

  @override
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    if (verified) {
      // Erzwinge Token-Refresh damit request.auth.token.email_verified in Firestore-Rules
      // sofort true ist – ohne diesen Force-Refresh bleibt das alte JWT noch bis zu
      // 60 Minuten gültig und würde die messages-Schreibregel blockieren.
      await _auth.currentUser!.getIdToken(true);
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
    void Function()? onAutoVerified,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential cred) async {
        // Android: Code automatisch erkannt, kein manuelles Eingeben nötig
        try {
          await _auth.currentUser!.linkWithCredential(cred);
          await savePhone(phone);
        } catch (_) {
          await _auth.currentUser!.updatePhoneNumber(cred);
          await savePhone(phone);
        }
        onAutoVerified?.call();
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

  // Liest Name und Foto immer aus Firestore, nicht aus Firebase Auth.
  // Firebase Auth's displayName/photoURL sind bei älteren Accounts oder nach
  // Profil-Updates in der App veraltet.
  Future<({String name, String? photoUrl})> _firestoreUserInfo(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final first = data['firstName'] as String? ?? '';
    final last = data['lastName'] as String? ?? '';
    final name = '$first $last'.trim();
    final photo = data['photoUrl'] as String?;
    return (name: name.isNotEmpty ? name : (_auth.currentUser?.displayName ?? ''), photoUrl: photo);
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

    final userInfo = await _firestoreUserInfo(uid);
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {
      'licenseStatus': 'pending',
      'licenseRejectReason': FieldValue.delete(),
    });
    batch.set(_firestore.collection('licenseRequests').doc(uid), {
      'uid': uid,
      'userName': userInfo.name,
      'userPhotoUrl': userInfo.photoUrl,
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

  // ── Event-Anfragen ─────────────────────────────────────────────────────────

  @override
  Future<void> submitEventRequestManual({
    required String name,
    required String standort,
    required String datum,
    required String eventTyp,
    required String beschreibung,
    required String adresse,
    double? latitude,
    double? longitude,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Nicht eingeloggt');

    final userInfo = await _firestoreUserInfo(fbUser.uid);
    await _firestore.collection('eventRequests').add({
      'uid': fbUser.uid,
      'userName': userInfo.name,
      'userPhotoUrl': userInfo.photoUrl,
      'submissionType': 'manual',
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'eventName': name,
      'standort': standort,
      'datum': datum,
      'eventTyp': eventTyp,
      'beschreibung': beschreibung,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  @override
  Future<void> submitEventRequestFlyer(File flyer, {String? note}) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Nicht eingeloggt');

    final docRef = _firestore.collection('eventRequests').doc();
    final path = 'event_requests/${docRef.id}/flyer.jpg';

    final userInfo = await _firestoreUserInfo(fbUser.uid);
    await _storage
        .ref(path)
        .putFile(flyer, SettableMetadata(contentType: 'image/jpeg'));

    await docRef.set({
      'uid': fbUser.uid,
      'userName': userInfo.name,
      'userPhotoUrl': userInfo.photoUrl,
      'submissionType': 'flyer',
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'flyerPath': path,
      'note': note,
    });
  }

  @override
  Stream<List<EventRequest>> get pendingEventRequests => _firestore
      .collection('eventRequests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) {
        final list = s.docs.map(EventRequest.fromDoc).toList();
        list.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
        return list;
      });

  @override
  Future<void> approveEventRequest(String requestId, Event event) async {
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('events').doc(event.id),
      event.toMap(),
    );
    batch.update(
      _firestore.collection('eventRequests').doc(requestId),
      {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  @override
  Stream<List<EventRequest>> get myEventRequests {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('eventRequests')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map(EventRequest.fromDoc).toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  @override
  Future<void> discardEventRequest(String requestId, {String? reason}) async {
    await _firestore.collection('eventRequests').doc(requestId).update({
      'status': 'discarded',
      'reviewedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.isNotEmpty) 'rejectReason': reason,
    });
  }
}
