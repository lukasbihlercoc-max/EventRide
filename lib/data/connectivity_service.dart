// connectivity_service.dart
// Erkennt Offline-Zustand: sofort über OS-Netzwerk-Interface-Änderungen,
// zusätzlich per leichtem periodischen Erreichbarkeits-Check (für den Fall
// "WLAN verbunden, aber kein Internet dahinter" - connectivity_plus allein
// erkennt nur das Interface, nicht ob es tatsächlich Internet gibt).
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

class ConnectivityService with ChangeNotifier, WidgetsBindingObserver {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _reachabilityTimer;

  // Steigt bei jedem neuen Check — verhindert, dass ein Check, der während
  // des Hintergrundmodus hängen blieb, verspätet einen neueren Zustand
  // überschreibt (Race Condition bei schnellem Minimieren/Zurückkehren).
  int _checkGeneration = 0;

  // Zählt fehlgeschlagene Checks in Folge. Ein einzelner Timeout reicht nicht
  // für "offline" — direkt nach App-Resume ist die Firestore-Verbindung oft
  // kurz kalt (Netzwerk/gRPC-Kanal muss neu aufgebaut werden) und ein 5s-Timeout
  // schlägt fehl, obwohl eine normale Internetverbindung besteht. Erst der
  // zweite Fehlschlag in Folge (kurz danach erneut geprüft) gilt als offline.
  int _consecutiveFailures = 0;

  void start() {
    WidgetsBinding.instance.addObserver(this);

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _setOffline(true);
      } else {
        _checkReachability();
      }
    });

    _startPeriodicChecks();
    _checkReachability();
  }

  void _startPeriodicChecks() {
    _reachabilityTimer?.cancel();
    _reachabilityTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _checkReachability();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sofort neu prüfen statt auf den nächsten periodischen Tick zu warten —
      // sonst kann nach Rückkehr aus dem Hintergrund bis zu 20s ein veralteter
      // (evtl. falscher) Zustand angezeigt werden.
      _startPeriodicChecks();
      _checkReachability();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _reachabilityTimer?.cancel();
    }
  }

  Future<void> _checkReachability() async {
    final myGeneration = ++_checkGeneration;
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      if (myGeneration != _checkGeneration) return;
      _consecutiveFailures = 0;
      _setOffline(false);
    } catch (_) {
      if (myGeneration != _checkGeneration) return;
      _consecutiveFailures++;
      if (_consecutiveFailures >= 2) {
        _setOffline(true);
      } else {
        // Erster Fehlschlag: kein sofortiges "offline" — kurz danach erneut
        // prüfen statt bis zum nächsten 20s-Tick zu warten.
        Future.delayed(const Duration(seconds: 3), () {
          if (myGeneration == _checkGeneration) _checkReachability();
        });
      }
    }
  }

  void _setOffline(bool value) {
    if (_isOffline == value) return;
    _isOffline = value;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    _reachabilityTimer?.cancel();
    super.dispose();
  }
}
