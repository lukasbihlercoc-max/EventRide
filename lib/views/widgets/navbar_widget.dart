// navbar_widget.dart
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:my_app/data/seen_anfragen_service.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:provider/provider.dart';

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
              horizontal: SizeHelper.w(context, 0.025),
              vertical: SizeHelper.h(context, 0.001),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SizeHelper.w(context, 0.08)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  height: SizeHelper.h(context, 0.09),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius:
                        BorderRadius.circular(SizeHelper.w(context, 0.06)),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.1),
                        blurRadius: SizeHelper.w(context, 0.075),
                        spreadRadius: SizeHelper.w(context, 0.0025),
                        offset: Offset(0, SizeHelper.h(context, 0.0125)),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: SizeHelper.w(context, 0.05),
                        offset: Offset(0, SizeHelper.h(context, 0.005)),
                      ),
                    ],
                  ),
                  child: BottomNavigationBarTheme(
                    data: BottomNavigationBarThemeData(
                      selectedIconTheme:
                          IconThemeData(size: SizeHelper.w(context, 0.08)),
                      unselectedIconTheme:
                          IconThemeData(size: SizeHelper.w(context, 0.07)),
                      selectedLabelStyle: TextStyle(
                        fontSize: SizeHelper.w(context, 0.0325),
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
                      items: [
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.celebration_outlined),
                          label: "Events",
                        ),
                        BottomNavigationBarItem(
                          icon: _FahrtenIcon(),
                          label: "Meine Fahrten",
                        ),
                        const BottomNavigationBarItem(
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

/// Icon für "Meine Fahrten" mit rotem Dot wenn ungesehene Anfragen vorhanden.
class _FahrtenIcon extends StatelessWidget {
  const _FahrtenIcon();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnfrageService, SeenAnfragenService>(
      builder: (context, anfrageService, seenService, _) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        bool hasUnseen = false;

        if (uid != null) {
          final ownerIds = anfrageService
              .getAnfragenForFahrer(uid)
              .where((a) => a.status == AnfrageStatus.offen)
              .map((a) => a.id);

          final requesterIds = anfrageService
              .getAnfragenByRequester(uid)
              .where((a) => a.status != AnfrageStatus.offen)
              .map((a) => a.id);

          hasUnseen = seenService.hasUnseenOwner(uid, ownerIds) ||
              seenService.hasUnseenRequester(uid, requesterIds);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.directions_car),
            if (hasUnseen)
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black54, width: 1),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
