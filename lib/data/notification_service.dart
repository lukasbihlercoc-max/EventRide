import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_app/data/chat_conversation.dart';
import 'package:my_app/data/interfaces/i_user_repository.dart';

/// Notification-Channel-ID für Android (muss mit AndroidManifest.xml übereinstimmen)
const String _channelId = 'eventride_channel';
const String _channelName = 'EventRide';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  final IUserRepository _userRepo;
  final GlobalKey<NavigatorState> _navigatorKey;

  /// Wird aufgerufen wenn der User auf eine Chat-Notification tippt.
  /// Parameter: conversationId, senderId
  Function(String convId, String senderId)? onChatTapped;

  /// Wird aufgerufen wenn der User auf eine Anfrage-Notification tippt.
  VoidCallback? onAnfrageTapped;

  /// Wird aufgerufen wenn der User auf eine Bewertungs-Notification tippt.
  VoidCallback? onReviewTapped;

  /// Wird aufgerufen wenn der Admin auf eine Führerschein-Notification tippt.
  VoidCallback? onLicenseReviewTapped;

  /// Wird aufgerufen wenn der Admin auf eine Event-Anfrage-Notification tippt.
  VoidCallback? onEventRequestTapped;

  /// Wird aufgerufen wenn der Nutzer auf eine "Event angenommen"-Notification tippt.
  VoidCallback? onUserEventRequestTapped;

  StreamSubscription<List<ChatConversation>>? _chatSub;
  StreamSubscription<String>? _tokenRefreshSub;
  final Map<String, DateTime> _knownLastMessageAt = {};
  bool _initialized = false;

  NotificationService({
    required IUserRepository userRepo,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _userRepo = userRepo,
        _navigatorKey = navigatorKey;

  Future<void> init(String userId) async {
    if (kDebugMode) debugPrint('[FCM] init() für userId=$userId');

    if (!_initialized) {
      _initialized = true;

      // 1. Berechtigung anfragen
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) debugPrint('[FCM] Berechtigung: ${settings.authorizationStatus}');

      // 2. Android Notification Channel einrichten (Pflicht ab Android 8)
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 3. flutter_local_notifications initialisieren
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          _navigateFromPayload(details.payload);
        },
      );

      // 6. Vordergrund: FCM-Nachrichten als lokale Notification anzeigen.
      // Chat-Nachrichten werden bereits durch startChatMonitoring angezeigt → überspringen.
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) debugPrint('[FCM] Vordergrund-Nachricht: ${message.notification?.title} / data=${message.data}');
        if (message.data['type'] == 'chat') return;
        _showLocalNotification(message);
      });

      // 7. Hintergrund → Vordergrund
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) debugPrint('[FCM] App durch Notification geöffnet: ${message.data}');
        _navigateFromData(message.data);
      });

      // 8. Cold Start – Navigation erst nach dem ersten Frame, damit der
      // Navigator sicher initialisiert ist.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        if (kDebugMode) debugPrint('[FCM] Cold-Start-Notification: ${initial.data}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateFromData(initial.data);
        });
      }
    }

    // 4. FCM-Token holen & in Firestore speichern (bei jedem Login)
    //    Nur wenn Notifications tatsächlich erlaubt sind.
    final permStatus = await FirebaseMessaging.instance.getNotificationSettings();
    final notificationsAllowed =
        permStatus.authorizationStatus == AuthorizationStatus.authorized ||
        permStatus.authorizationStatus == AuthorizationStatus.provisional;
    if (!notificationsAllowed) {
      if (kDebugMode) debugPrint('[FCM] Notifications verweigert – kein Token gespeichert');
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) debugPrint('[FCM] Token: $token');
    if (token != null) {
      await _userRepo.saveFcmToken(userId, token);
      if (kDebugMode) debugPrint('[FCM] Token in Firestore gespeichert');
    } else {
      if (kDebugMode) debugPrint('[FCM] KEIN TOKEN erhalten – Notifications werden nicht funktionieren');
    }

    // 5. Token-Refresh beobachten (alte Subscription ersetzen, damit kein falscher userId bleibt)
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (kDebugMode) debugPrint('[FCM] Token aktualisiert: $newToken');
      _userRepo.saveFcmToken(userId, newToken);
    });

    if (kDebugMode) debugPrint('[FCM] init() abgeschlossen');
  }

  /// FCM-Token beim Logout aus Firestore entfernen.
  Future<void> removeToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 5));
      if (token != null) {
        await _userRepo.removeFcmToken(userId, token);
      }
    } catch (_) {
      // getToken() kann auf iOS hängen wenn APNs nicht konfiguriert ist.
      // Token wird beim nächsten Login automatisch aktualisiert.
    }
  }

  /// Beobachtet den Conversations-Stream und zeigt lokale Notifications
  /// wenn der andere Teilnehmer eine neue Nachricht schickt.
  /// Funktioniert im Vordergrund ohne Cloud Functions.
  void startChatMonitoring({
    required String userId,
    required Stream<List<ChatConversation>> conversationsStream,
  }) {
    _chatSub?.cancel();
    _knownLastMessageAt.clear();
    bool isFirstEmission = true;

    _chatSub = conversationsStream.listen((conversations) {
      if (isFirstEmission) {
        // Baseline = jetzt, nicht conv.lastUpdated.
        // Firestore emittiert beim Start zweimal (Cache → Server). Würden wir
        // conv.lastUpdated als Baseline nehmen, gilt die zweite Emission als
        // "neue" Nachricht und löst eine Duplicate-Notification aus.
        final now = DateTime.now();
        for (final conv in conversations) {
          _knownLastMessageAt[conv.id] = now;
        }
        isFirstEmission = false;
        return;
      }

      for (final conv in conversations) {
        final known = _knownLastMessageAt[conv.id];
        final isNewer = known == null || conv.lastUpdated.isAfter(known);
        if (!isNewer) continue;

        _knownLastMessageAt[conv.id] = conv.lastUpdated;

        // Nur Notification wenn der ANDERE geschrieben hat
        final senderId = conv.lastSenderId;
        if (senderId == null || senderId == userId || senderId == 'system') continue;

        // Leere Nachrichten ignorieren
        if (conv.lastMessage == null || conv.lastMessage!.isEmpty) continue;

        // Nachrichten älter als 30 Sekunden ignorieren – verhindert
        // Spurious Notifications durch Server-Timestamp-Auflösung beim App-Start.
        final age = DateTime.now().difference(conv.lastUpdated);
        if (age > const Duration(seconds: 30)) continue;

        if (kDebugMode) debugPrint('[FCM] Neue Chat-Nachricht von $senderId in ${conv.id}');
        if (activeChatConversationId.value == conv.id) continue;
        _showChatLocalNotification(conv);
      }
    });
  }

  void stopChatMonitoring() {
    _chatSub?.cancel();
    _chatSub = null;
    _knownLastMessageAt.clear();
  }

  Future<void> cancelChatNotification(String conversationId) async {
    await _localNotifications.cancel(conversationId.hashCode);
  }

  void _showChatLocalNotification(ChatConversation conv) {
    final preview = conv.lastMessage ?? 'Neue Nachricht';
    _localNotifications.show(
      conv.id.hashCode,
      'Neue Nachricht',
      preview.length > 80 ? '${preview.substring(0, 80)}…' : preview,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'type=chat&conversationId=${conv.id}&senderId=${conv.lastSenderId ?? ""}',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // payload für Navigation nach Tap (Vordergrund)
      payload: _payloadFromData(message.data),
    );
  }

  /// Navigiert anhand des `data`-Felds einer FCM-Nachricht.
  /// [_retries] verhindert eine unendliche Retry-Schleife falls der Navigator
  /// nie bereit wird (z. B. nach Auth-Fehler).
  void _navigateFromData(Map<String, dynamic> data, {int retries = 0}) {
    if (_navigatorKey.currentState == null) {
      if (retries >= 5) return;
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateFromData(data, retries: retries + 1);
      });
      return;
    }
    final type = data['type'] as String?;
    if (type == 'chat') {
      final convId = data['conversationId'] as String?;
      final senderId = data['senderId'] as String?;
      if (convId != null && senderId != null && senderId.isNotEmpty) {
        onChatTapped?.call(convId, senderId);
      }
    } else if (type == 'storno_chat') {
      final convId = data['conversationId'] as String?;
      final senderId = data['senderId'] as String?;
      if (convId != null && senderId != null && senderId.isNotEmpty) {
        onChatTapped?.call(convId, senderId);
      }
    } else if (type == 'anfrage' || type == 'fahrt_geloescht') {
      onAnfrageTapped?.call();
    } else if (type == 'license_review') {
      onLicenseReviewTapped?.call();
    } else if (type == 'event_request') {
      onEventRequestTapped?.call();
    } else if (type == 'event_request_approved') {
      onUserEventRequestTapped?.call();
    } else if (type == 'review') {
      onReviewTapped?.call();
    }
  }

  /// Navigiert anhand eines serialisierten Payload-Strings (lokale Notifications).
  void _navigateFromPayload(String? payload) {
    if (payload == null) return;
    // Payload-Format: "type=chat&conversationId=xyz" oder "type=anfrage"
    final params = Uri.splitQueryString(payload);
    _navigateFromData(params);
  }

  /// Erstellt einen Payload-String aus den FCM data-Feldern.
  String _payloadFromData(Map<String, dynamic> data) {
    return Uri(queryParameters: data.map(
      (k, v) => MapEntry(k, v.toString()),
    )).query;
  }
}
