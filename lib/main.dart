// lib/main.dart
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/event_repository.dart';
import 'package:my_app/data/event_service.dart';
import 'package:my_app/data/fahrt_anfrage_service.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

// Repositories
import 'package:my_app/data/firebase/firebase_fahrt_repository.dart';
import 'package:my_app/data/firebase/firestore_chat_repository.dart';

// Interfaces + lokale Implementierungen
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/interfaces/i_fahrt_repository.dart';
import 'package:my_app/data/firebase/firebase_auth_repository.dart';

// Hive
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/user_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_app/views/auth/auth_gate.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/firebase/firestore_anfrage_repository.dart';

// Services
import 'package:my_app/data/anfrage_service.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);

  // Hive initialisieren
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // Adapter registrieren
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(AnfrageStatusAdapter());
  Hive.registerAdapter(AnfrageDatenAdapter());

  // Boxen öffnen
  await Hive.openBox<Event>('events');
  await Hive.openBox<AnfrageDaten>('anfragen');

  // Favoriten initialisieren
  await initFavouriteEvents();

  await UserService().loadUser();


  // ----------------------------
  // Services initialisieren
  // ----------------------------

  final anfrageRepository = await FirestoreAnfrageRepository.create();
  final anfrageService = AnfrageService();
  await anfrageService.init(anfrageRepository);

  final eventRepository =
      EventRepository(Hive.box<Event>('events'));
  final eventService = EventService(eventRepository);
  await eventService.load();

  final fahrtRepository = await FirestoreFahrtRepository.create();
  final fahrtService = FahrtService(fahrtRepository);
  await fahrtService.load();

  final chatService = ChatService(FirestoreChatRepository());

  // 🔹 Performance Optimierungen
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  final authRepository = FirebaseAuthRepository();

  // App starten
  runApp(MyApp(
    eventService: eventService,
    fahrtService: fahrtService,
    anfrageService: anfrageService,
    chatService: chatService,
    authRepository: authRepository,
    fahrtRepository: fahrtRepository,
  ));
}

Future<void> speichereEvent(Event event) async {
  final box = Hive.box<Event>('events');
  await box.put(event.id, event);
}

Future<List<Event>> ladeAlleEvents() async {
  final box = Hive.box<Event>('events');
  return box.values.toList();
}


class MyApp extends StatefulWidget {
  final EventService eventService;
  final FahrtService fahrtService;
  final AnfrageService anfrageService;
  final ChatService chatService;
  final IAuthRepository authRepository;
  final IFahrtRepository fahrtRepository;

  const MyApp({
    super.key,
    required this.eventService,
    required this.fahrtService,
    required this.anfrageService,
    required this.chatService,
    required this.authRepository,
    required this.fahrtRepository,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

        Provider<ChatService>.value(
          value: widget.chatService,
        ),
        
        Provider<RideRequestService>(
          create: (_) => RideRequestService(),
        ),

        // Repository-Interfaces (austauschbar gegen Firebase-Implementierungen)
        Provider<IAuthRepository>.value(value: widget.authRepository),
        Provider<IFahrtRepository>.value(value: widget.fahrtRepository),
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
