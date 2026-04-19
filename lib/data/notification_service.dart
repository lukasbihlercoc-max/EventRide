import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
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

  StreamSubscription<List<ChatConversation>>? _chatSub;
  final Map<String, DateTime> _knownLastMessageAt = {};

  NotificationService({
    required IUserRepository userRepo,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _userRepo = userRepo,
        _navigatorKey = navigatorKey;

  Future<void> init(String userId) async {
    debugPrint('[FCM] init() für userId=$userId');

    // 1. Berechtigung anfragen
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Berechtigung: ${settings.authorizationStatus}');

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

    // 4. FCM-Token holen & in Firestore speichern
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('[FCM] Token: $token');
    if (token != null) {
      await _userRepo.saveFcmToken(userId, token);
      debugPrint('[FCM] Token in Firestore gespeichert');
    } else {
      debugPrint('[FCM] KEIN TOKEN erhalten – Notifications werden nicht funktionieren');
    }

    // 5. Token-Refresh beobachten
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token aktualisiert: $newToken');
      _userRepo.saveFcmToken(userId, newToken);
    });

    // 6. Vordergrund: FCM-Nachrichten als lokale Notification anzeigen.
    // Chat-Nachrichten werden bereits durch startChatMonitoring angezeigt → überspringen.
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Vordergrund-Nachricht: ${message.notification?.title} / data=${message.data}');
      if (message.data['type'] == 'chat') return;
      _showLocalNotification(message);
    });

    // 7. Hintergrund → Vordergrund
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] App durch Notification geöffnet: ${message.data}');
      _navigateFromData(message.data);
    });

    // 8. Cold Start
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Cold-Start-Notification: ${initial.data}');
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateFromData(initial.data);
      });
    }

    debugPrint('[FCM] init() abgeschlossen');
  }

  /// FCM-Token beim Logout aus Firestore entfernen.
  Future<void> removeToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _userRepo.removeFcmToken(userId, token);
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
        // Basis-Zeitstempel merken, noch keine Notifications zeigen
        for (final conv in conversations) {
          _knownLastMessageAt[conv.id] = conv.lastUpdated;
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

        debugPrint('[FCM] Neue Chat-Nachricht von $senderId in ${conv.id}');
        _showChatLocalNotification(conv);
      }
    });
  }

  void stopChatMonitoring() {
    _chatSub?.cancel();
    _chatSub = null;
    _knownLastMessageAt.clear();
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
      payload: 'type=chat&conversationId=${conv.id}',
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
  void _navigateFromData(Map<String, dynamic> data) {
    if (_navigatorKey.currentState == null) {
      // navigatorKey noch nicht bereit → nochmals verzögern
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateFromData(data);
      });
      return;
    }
    final type = data['type'] as String?;
    if (type == 'chat') {
      final convId = data['conversationId'] as String?;
      _navigatorKey.currentState?.pushNamed('/chat', arguments: convId);
    } else if (type == 'anfrage') {
      _navigatorKey.currentState?.pushNamed('/anfragen');
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
