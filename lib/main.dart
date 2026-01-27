// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/chat_conversation.dart';
import 'package:my_app/data/chat_message.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/event_repository.dart';
import 'package:my_app/data/event_service.dart';
import 'package:my_app/data/fahrt_anfrage_service.dart';
import 'package:my_app/data/fahrt_daten.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

// Repositories
import 'package:my_app/data/fahrt_repository.dart';
import 'package:my_app/data/chat_repository.dart';

// Hive
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/user_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_app/views/widget_tree.dart';
import 'package:my_app/data/anfrage_daten.dart';

// Services
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/fahrt_service.dart';

// Provider
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);

  // Hive initialisieren
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // Adapter registrieren
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(FahrtDatenAdapter());
  Hive.registerAdapter(FahrtrichtungAdapter());
  Hive.registerAdapter(AnfrageStatusAdapter());
  Hive.registerAdapter(AnfrageDatenAdapter());

  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ChatConversationAdapter());

  // Boxen öffnen
  await Hive.openBox<Event>('events');
  await Hive.openBox<FahrtDaten>('fahrten');
  await Hive.openBox<AnfrageDaten>('anfragen');
  await Hive.openBox<ChatConversation>('chat_conversations');
  await Hive.openBox<ChatMessage>('chat_messages');

  //await Hive.deleteBoxFromDisk("events"); //! gespeicherte Events LÖSCHEN
  //await Hive.deleteBoxFromDisk("fahrten"); //! gespeicherte Fahrten LÖSCHEN
  //await Hive.deleteBoxFromDisk("anfragen"); //! gespeicherte Anfragen LÖSCHEN
  //await Hive.deleteBoxFromDisk("chat_conversations"); //! gespeicherte Chats LÖSCHEN
  //await Hive.deleteBoxFromDisk("chat_messages"); //! gespeicherte Nachrichten LÖSCHEN

  // Favoriten initialisieren
  await initFavouriteEvents();

  await UserService().loadUser();


  // ----------------------------
  // Services initialisieren
  // ----------------------------

  final anfrageService = AnfrageService();
  await anfrageService.init();

  final eventRepository =
      EventRepository(Hive.box<Event>('events'));
  final eventService = EventService(eventRepository);
  await eventService.load();

  final fahrtRepository =
      FahrtRepository(Hive.box<FahrtDaten>('fahrten'));
  final fahrtService = FahrtService(fahrtRepository);
  await fahrtService.load();

  // ✅ ChatRepository + ChatService (NEU, korrekt)
  final chatRepository = ChatRepository(
    Hive.box<ChatConversation>('chat_conversations'),
    Hive.box<ChatMessage>('chat_messages'),
  );
  final chatService = ChatService(chatRepository);

  // 🔹 Performance Optimierungen
  debugPrint = (String? message, {int? wrapWidth}) {}; // Debug-Output in Release deaktivieren

  // App starten
  runApp(MyApp(
    eventService: eventService,
    fahrtService: fahrtService,
    anfrageService: anfrageService,
    chatService: chatService,
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
  final ChatService chatService; // ✅ NEU

  const MyApp({
    super.key,
    required this.eventService,
    required this.fahrtService,
    required this.anfrageService,
    required this.chatService,
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

        // ✅ ChatService korrekt per value
        ChangeNotifierProvider<ChatService>.value(
          value: widget.chatService,
        ),
        
        Provider<RideRequestService>(
          create: (_) => RideRequestService()
          ),
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
            home: const WidgetTree(),
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
