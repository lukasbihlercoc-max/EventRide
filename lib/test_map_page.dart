import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestMapPage extends StatelessWidget {
  const TestMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map Test")),
      body: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(46.6247, 13.8500), // Villach
          zoom: 14,
        ),
      ),
    );
  }
}