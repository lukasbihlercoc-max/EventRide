// navbar_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart'; // falls du SizeHelper dort definiert hast

class NavBarWidget extends StatelessWidget {
  const NavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeHelper.w(context, 0.025), // ≈10 bei 400px Breite
              vertical: SizeHelper.h(context, 0.001),   // ≈5 bei 800px Höhe
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SizeHelper.w(context, 0.08)), // ≈32
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), //? Unschärfe-Effekt
                child: Container(
                  height: SizeHelper.h(context, 0.09), // ≈72
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(SizeHelper.w(context, 0.06)), // ≈24
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.1),
                        blurRadius: SizeHelper.w(context, 0.075), // ≈30
                        spreadRadius: SizeHelper.w(context, 0.0025), // ≈1
                        offset: Offset(0, SizeHelper.h(context, 0.0125)), // ≈10
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: SizeHelper.w(context, 0.05), // ≈20
                        offset: Offset(0, SizeHelper.h(context, 0.005)), // ≈4
                      ),
                    ],
                  ),
                  child: BottomNavigationBarTheme(
                    data: BottomNavigationBarThemeData(
                      selectedIconTheme: IconThemeData(size: SizeHelper.w(context, 0.08)), // ≈32
                      unselectedIconTheme: IconThemeData(size: SizeHelper.w(context, 0.07)), // ≈28
                      selectedLabelStyle: TextStyle(
                        fontSize: SizeHelper.w(context, 0.0325), // ≈13
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: SizeHelper.w(context, 0.0325),
                        color: Colors.white70,
                      ),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: selectedPage,
                      onTap: (index) => selectedPageNotifier.value = index,
                      showSelectedLabels: true,
                      showUnselectedLabels: false,
                      selectedItemColor: Colors.amber,
                      unselectedItemColor: Colors.white70,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      type: BottomNavigationBarType.fixed,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.celebration_outlined),
                          label: "Events",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.directions_car),
                          label: "Meine Fahrten",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person),
                          label: "Profil",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
