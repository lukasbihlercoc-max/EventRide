// lib/main.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/notification_service.dart';
import 'package:my_app/data/seen_anfragen_service.dart';
import 'package:my_app/data/event_service.dart';
import 'package:my_app/data/firebase/firestore_event_repository.dart';
import 'package:my_app/data/fahrt_anfrage_service.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

// Repositories
import 'package:my_app/data/firebase/firebase_fahrt_repository.dart';
import 'package:my_app/data/firebase/firestore_chat_repository.dart';
import 'package:my_app/data/firebase/firestore_user_repository.dart';

// Interfaces + lokale Implementierungen
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/interfaces/i_fahrt_repository.dart';
import 'package:my_app/data/interfaces/i_user_repository.dart';
import 'package:my_app/data/firebase/firebase_auth_repository.dart';

import 'package:my_app/views/auth/auth_gate.dart';
import 'package:my_app/views/pages/admin_event_requests_page.dart';
import 'package:my_app/views/pages/admin_license_page.dart';
import 'package:my_app/views/pages/user_event_requests_page.dart';
import 'package:my_app/views/pages/chat_page.dart';
import 'package:my_app/data/firebase/firestore_anfrage_repository.dart';
import 'package:my_app/data/firebase/firestore_interessenten_repository.dart';

// Services
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/interessenten_service.dart';
import 'package:my_app/data/fahrt_service.dart';

// Provider
import 'package:provider/provider.dart';

//Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:my_app/utils/app_route.dart';

/// Globaler NavigatorKey – wird vom NotificationService für Deep-Links verwendet.
final navigatorKey = GlobalKey<NavigatorState>();


/// Slide-Übergang: neue Seite gleitet von rechts rein, ausgehende Seite bleibt stehen.
/// Kein Secondary-Animation-Effekt → kein Blur/Skalierung des Hintergrunds.
class _SlideTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ClipRect(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: child,
      ),
    );
  }
}

/// Top-Level-Handler für FCM-Nachrichten wenn die App beendet ist.
/// Muss eine Top-Level-Funktion sein (kein Lambda, kein Klassenmember).
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  FirebaseMessaging.onBackgroundMessage(_bgHandler);
  await initializeDateFormatting('de_DE', null);

  // Favoriten initialisieren
  await initFavouriteEvents();

  // ----------------------------
  // Services initialisieren
  // ----------------------------

  final authRepository = FirebaseAuthRepository();

  final anfrageRepository = FirestoreAnfrageRepository.create();
  final anfrageService = AnfrageService();
  await anfrageService.init(anfrageRepository, authRepository);

  final eventRepository = FirestoreEventRepository.create();
  final eventService = EventService(eventRepository);
  await eventService.load();
  eventService.addListener(() {
    eventListNotifier.value = eventService.events.toList();
  });

  final fahrtRepository = FirestoreFahrtRepository.create();
  final fahrtService = FahrtService(fahrtRepository);
  await fahrtService.load();

  final userRepository = FirestoreUserRepository();

  final notificationService = NotificationService(
    userRepo: userRepository,
    navigatorKey: navigatorKey,
  );

  notificationService.onAnfrageTapped = () {
    selectedPageNotifier.value = 1; // Fahrten-Tab
  };

  notificationService.onReviewTapped = () {
    selectedPageNotifier.value = 2; // Profil-Tab
  };

  notificationService.onLicenseReviewTapped = () {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Navigator.of(ctx).push(AppRoute(
      builder: (_) => const AdminLicensePage(),
    ));
  };

  notificationService.onEventRequestTapped = () {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Navigator.of(ctx).push(AppRoute(
      builder: (_) => const AdminEventRequestsPage(),
    ));
  };

  notificationService.onUserEventRequestTapped = () {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Navigator.of(ctx).push(AppRoute(
      builder: (_) => const UserEventRequestsPage(),
    ));
  };

  notificationService.onChatTapped = (convId, senderId) async {
    final doc =
        await FirebaseFirestore.instance.doc('users/$senderId').get();
    final d = doc.data();
    final name = [d?['firstName'], d?['lastName']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');

    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Navigator.of(ctx).push(AppRoute(
      builder: (_) => ChatPage(
        conversationId: convId,
        otherUserId: senderId,
        otherUserName: name.isEmpty ? 'Nutzer' : name,
      ),
    ));
  };

  final chatService = ChatService(FirestoreChatRepository());

  final seenAnfragenService = SeenAnfragenService();
  await seenAnfragenService.init();

  final interessentenService =
      InteressentenService(FirestoreInteressentenRepository())
        ..init(authRepository);

  // App starten
  runApp(MyApp(
    eventService: eventService,
    fahrtService: fahrtService,
    anfrageService: anfrageService,
    chatService: chatService,
    authRepository: authRepository,
    fahrtRepository: fahrtRepository,
    userRepository: userRepository,
    seenAnfragenService: seenAnfragenService,
    interessentenService: interessentenService,
    notificationService: notificationService,
  ));
}

class MyApp extends StatefulWidget {
  final EventService eventService;
  final FahrtService fahrtService;
  final AnfrageService anfrageService;
  final ChatService chatService;
  final IAuthRepository authRepository;
  final IFahrtRepository fahrtRepository;
  final IUserRepository userRepository;
  final SeenAnfragenService seenAnfragenService;
  final InteressentenService interessentenService;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.eventService,
    required this.fahrtService,
    required this.anfrageService,
    required this.chatService,
    required this.authRepository,
    required this.fahrtRepository,
    required this.userRepository,
    required this.seenAnfragenService,
    required this.interessentenService,
    required this.notificationService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _heartbeatTimer;
  StreamSubscription<AppUser?>? _authSub;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = widget.authRepository.authStateChanges.listen(
      (user) async {
        final newUserId = user?.userId ?? '';
        if (newUserId.isNotEmpty && _currentUserId.isEmpty) {
          // Login: Heartbeat + Notifications starten, Streams neu laden.
          _currentUserId = newUserId;
          _startHeartbeat();
          widget.fahrtService.load();
          // userId als lokale Variable sichern – _currentUserId könnte sich
          // durch einen Logout-Event ändern bevor then() ausgeführt wird.
          final uid = _currentUserId;
          await widget.notificationService.init(uid);
          widget.notificationService.startChatMonitoring(
            userId: uid,
            conversationsStream: widget.chatService.conversationsStream(uid),
          );
        } else if (newUserId.isEmpty && _currentUserId.isNotEmpty) {
          // Logout: erst Token entfernen (await!), dann aufräumen.
          // Ohne await bleibt das Token im alten User-Dokument wenn dasselbe
          // Gerät danach mit einem anderen Account einloggt.
          final uid = _currentUserId;
          _currentUserId = '';
          _stopHeartbeat();
          widget.notificationService.stopChatMonitoring();
          await widget.notificationService.removeToken(uid);
        } else {
          _currentUserId = newUserId;
        }
      },
      onError: (_) {},
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    widget.userRepository.updateLastSeen(_currentUserId);
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_currentUserId.isNotEmpty) {
        widget.userRepository.updateLastSeen(_currentUserId);
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_currentUserId.isNotEmpty) {
        _startHeartbeat();
        // Monitoring neu starten: setzt isFirstEmission zurück und verhindert
        // doppelte Notifications durch Firestore-Stream-Reconnect nach Resume.
        widget.notificationService.startChatMonitoring(
          userId: _currentUserId,
          conversationsStream:
              widget.chatService.conversationsStream(_currentUserId),
        );
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopHeartbeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _stopHeartbeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ValueListenableProvider<bool>.value(
          value: isDarkModeNotifier,
        ),

        ChangeNotifierProvider<EventService>.value(
          value: widget.eventService,
        ),

        ChangeNotifierProvider<FahrtService>.value(
          value: widget.fahrtService,
        ),

        ChangeNotifierProvider<AnfrageService>.value(
          value: widget.anfrageService,
        ),

        ChangeNotifierProvider<SeenAnfragenService>.value(
          value: widget.seenAnfragenService,
        ),

        ChangeNotifierProvider<InteressentenService>.value(
          value: widget.interessentenService,
        ),

        Provider<ChatService>.value(
          value: widget.chatService,
        ),
        
        Provider<RideRequestService>(
          create: (_) => RideRequestService(widget.anfrageService),
        ),

        // Repository-Interfaces (austauschbar gegen Firebase-Implementierungen)
        Provider<IAuthRepository>.value(value: widget.authRepository),
        Provider<IFahrtRepository>.value(value: widget.fahrtRepository),
        Provider<IUserRepository>.value(value: widget.userRepository),
        Provider<NotificationService>.value(value: widget.notificationService),
      ],

      
      child: Builder(
        builder: (context) {
          final isDarkMode = context.watch<bool>();

          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              textTheme: GoogleFonts.poppinsTextTheme(
                Theme.of(context).textTheme,
              ),
              colorSchemeSeed: Colors.blueAccent,
              brightness:
                  isDarkMode ? Brightness.dark : Brightness.light,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: _SlideTransitionsBuilder(),
                  TargetPlatform.iOS: _SlideTransitionsBuilder(),
                  TargetPlatform.macOS: _SlideTransitionsBuilder(),
                },
              ),
            ),
            home: const AuthGate(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('de', 'DE'),
            ],
          );
        },
      ),
    );
  }
}
