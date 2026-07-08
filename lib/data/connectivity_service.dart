// connectivity_service.dart
// Erkennt Offline-Zustand: sofort über OS-Netzwerk-Interface-Änderungen,
// zusätzlich per leichtem periodischen Erreichbarkeits-Check (für den Fall
// "WLAN verbunden, aber kein Internet dahinter" - connectivity_plus allein
// erkennt nur das Interface, nicht ob es tatsächlich Internet gibt).
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _reachabilityTimer;

  void start() {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _setOffline(true);
      } else {
        _checkReachability();
      }
    });

    _reachabilityTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _checkReachability();
    });

    _checkReachability();
  }

  Future<void> _checkReachability() async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      _setOffline(false);
    } catch (_) {
      _setOffline(true);
    }
  }

  void _setOffline(bool value) {
    if (_isOffline == value) return;
    _isOffline = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _reachabilityTimer?.cancel();
    super.dispose();
  }
}
