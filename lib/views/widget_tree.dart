// widget_tree.dart
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:my_app/data/event_request.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/license_request.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:my_app/utils/app_route.dart';
import 'package:my_app/views/pages/app_info_page.dart';
import 'package:my_app/views/pages/events_page.dart';
import 'package:my_app/views/pages/fahrten_page.dart';
import 'package:my_app/views/pages/home_page.dart';
import 'package:my_app/views/pages/profile_page.dart';
import 'package:my_app/views/pages/settings_page.dart';
import 'package:my_app/views/widgets/appbar_widget.dart';
import 'package:my_app/views/widgets/background_widget.dart';
import 'package:my_app/views/widgets/navbar_widget.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';

import 'package:provider/provider.dart';

class PageInfo {
  final Widget page;
  final String title;

  PageInfo({required this.page, required this.title});
}

final List<PageInfo> pages = [
  PageInfo(page: HomePage(), title: "Veranstaltungen"),
  PageInfo(page: MeineFahrtenPage(), title: "Fahrten"),
  PageInfo(page: ProfilePage(), title: "Profil"),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    // 🆕 MULTIPROVIDER FÜR FAHRTSERVICE HINZUFÜGEN
    return MultiProvider(
      providers: [
        // 🟡 BEREITS EXISTIEREND: selectedPageNotifier als ValueListenableProvider
        ValueListenableProvider<int>.value(
          value: selectedPageNotifier,
        ),
      ],
      child: Builder(
        builder: (context) {
          // 🆕 CONTEXT.WATCH FÜR SELECTED PAGE VERWENDEN
          final selectedPage = context.watch<int>();

          final bottomInset = MediaQuery.of(context).padding.bottom;
          // ── Scrim / Navbar anpassen ──────────────────────────────
          final navbarBottom = SizeHelper.h(context, 0.006);   // Navbar-Abstand vom Rand
          final scrimHeight  = SizeHelper.h(context, 0.106) + bottomInset; // Scrim-Höhe
          // ─────────────────────────────────────────────────────────

          return Stack(
            children: [
              AppBackground(
                child: Scaffold(
                  extendBody: true,
                  backgroundColor: Colors.transparent,
                  appBar: _buildAppBar(context, selectedPage),
                  body: pages[selectedPage].page,
                ),
              ),

              // Bottom Scrim – dunkelt den Hintergrund hinter der Navbar ab
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: scrimHeight,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.35, 0.7, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                              Colors.black.withValues(alpha: 0.60),
                              Colors.black.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Action Button – nur für Admin sichtbar
              if (context.read<IAuthRepository>().isAdmin)
                Positioned(
                  bottom: 110,
                  right: 24,
                  child: FloatingActionButton(
                    backgroundColor: const Color.fromARGB(193, 51, 85, 234),
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppRoute(
                          builder: (_) => EventsPage(event: null),
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                ),

              // Navigationsleiste - 🟡 UNVERÄNDERT
              Positioned(
                bottom: navbarBottom,
                left: 16,
                right: 16,
                child: NavBarWidget(),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔥 AppBar-Konfiguration - 🟡 UNVERÄNDERT
  AppBarWidget _buildAppBar(BuildContext context, int selectedPage) {
    switch (selectedPage) {
      case 0: // HomePage
        return AppBarWidget(
          title: pages[selectedPage].title,
          showLogo: true,
          onLogoTap: () => Navigator.push(
            context,
            AppRoute(builder: (_) => const AppInfoPage()),
          ),
        );
      case 1: // FahrtenPage
        return AppBarWidget(
          title: pages[selectedPage].title,
        );
      
      case 2: // ProfilePage
        return AppBarWidget(
          title: pages[selectedPage].title,
          rightWidget: _buildSettingsButton(context),
        );
      
      default:
        return AppBarWidget(title: pages[selectedPage].title);
    }
  }

  Widget _buildSettingsButton(BuildContext context) {
    return const _AdminSettingsButton();
  }
}

// ─────────────────────────────────────────────────────────────
class _AdminSettingsButton extends StatefulWidget {
  const _AdminSettingsButton();

  @override
  State<_AdminSettingsButton> createState() => _AdminSettingsButtonState();
}

class _AdminSettingsButtonState extends State<_AdminSettingsButton> {
  int _licenseCount = 0;
  int _eventCount = 0;
  StreamSubscription<List<LicenseRequest>>? _licenseSub;
  StreamSubscription<List<EventRequest>>? _eventSub;

  @override
  void initState() {
    super.initState();
    final auth = context.read<IAuthRepository>();
    if (auth.isAdmin) {
      _licenseSub = auth.pendingLicenseRequests.listen(
        (list) { if (mounted) setState(() => _licenseCount = list.length); },
        onError: (_) {},
      );
      _eventSub = auth.pendingEventRequests.listen(
        (list) { if (mounted) setState(() => _eventCount = list.length); },
        onError: (_) {},
      );
    }
  }

  @override
  void dispose() {
    _licenseSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _licenseCount > 0 || _eventCount > 0;
    const orange = Color(0xFFF5A04A);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          AppRoute(builder: (_) => SettingsPage(title: "Einstellungen")),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasPending
                    ? orange.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasPending
                      ? orange.withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.25),
                ),
                boxShadow: hasPending
                    ? [
                        BoxShadow(
                          color: orange.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.settings_rounded,
                size: 20,
                color: hasPending ? orange : Colors.white,
              ),
            ),
            if (hasPending)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
