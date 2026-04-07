// lib/main.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_app/data/chat_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  WidgetsFlutterBinding.ensureInitialized();
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

  final chatService = ChatService(FirestoreChatRepository());

  final seenAnfragenService = SeenAnfragenService();
  await seenAnfragenService.init();

  final interessentenService =
      InteressentenService(FirestoreInteressentenRepository());

  // 🔹 Performance Optimierungen
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

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
    _authSub = widget.authRepository.authStateChanges.listen((user) {
      _currentUserId = user?.userId ?? '';
      if (_currentUserId.isNotEmpty) {
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    widget.userRepository.updateLastSeen(_currentUserId);
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
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
      if (_currentUserId.isNotEmpty) _startHeartbeat();
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
      ],

      
      child: Builder(
        builder: (context) {
          final isDarkMode = context.watch<bool>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              textTheme: GoogleFonts.poppinsTextTheme(
                Theme.of(context).textTheme,
              ),
              colorSchemeSeed: Colors.blueAccent,
              brightness:
                  isDarkMode ? Brightness.dark : Brightness.light,
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
