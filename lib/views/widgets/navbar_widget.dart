// navbar_widget.dart
import 'package:flutter/material.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:my_app/data/seen_anfragen_service.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:provider/provider.dart';

const _kOrange = Color(0xFFF5A623);
const _kDuration = Duration(milliseconds: 320);
const _kCurve = Curves.easeInOutCubic;

class NavBarWidget extends StatelessWidget {
  const NavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SizeHelper.w(context, 0.08));

    return SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, _) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeHelper.w(context, 0.025),
              vertical: SizeHelper.h(context, 0.002),
            ),
            child: Container(
              height: SizeHelper.h(context, 0.1),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF172E7A), // etwas dunkler
                    const Color(0xFF1E44A8),
                    const Color(0xFF2654CC),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.08),
                    blurRadius: 18,
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.03),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / 3;

                    // 🔽 SCHMÄLER gemacht
                    final pillWidth = itemWidth * 0.55;

                    final pillLeft =
                        selectedPage * itemWidth + (itemWidth - pillWidth) / 2;

                    return Stack(
                      children: [
                        // Gradient-Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Top-Highlight Linie
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 1.2,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),

                        // 🔥 Neue ruhige Pill
                        AnimatedPositioned(
                          duration: _kDuration,
                          curve: _kCurve,
                          left: pillLeft,
                          top: constraints.maxHeight * 0.18,
                          bottom: constraints.maxHeight * 0.18,
                          width: pillWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),

                              // weniger aggressiv
                              color: _kOrange.withValues(alpha: 0.16),

                              border: Border.all(
                                color: _kOrange.withValues(alpha: 0.25),
                              ),

                              // KEIN starker Glow mehr
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Items
                        Row(
                          children: [
                            _NavItem(
                              icon: Icons.celebration_outlined,
                              activeIcon: Icons.celebration,
                              label: 'Events',
                              isSelected: selectedPage == 0,
                              onTap: () => selectedPageNotifier.value = 0,
                              context: context,
                            ),
                            _NavItemFahrten(
                              isSelected: selectedPage == 1,
                              onTap: () => selectedPageNotifier.value = 1,
                              context: context,
                            ),
                            _NavItem(
                              icon: Icons.person_outline_rounded,
                              activeIcon: Icons.person_rounded,
                              label: 'Profil',
                              isSelected: selectedPage == 2,
                              onTap: () => selectedPageNotifier.value = 2,
                              context: context,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GENERIC ITEM
// ─────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final BuildContext context;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: _kDuration,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Transform.translate(
                key: ValueKey(isSelected),

                // 🔥 subtiler Lift
                offset: isSelected ? const Offset(0, -2) : Offset.zero,

                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? _kOrange : Colors.white38,
                  size: isSelected
                      ? SizeHelper.w(context, 0.075)
                      : SizeHelper.w(context, 0.065),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _kDuration,
              style: TextStyle(
                fontSize: SizeHelper.w(context, 0.028),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? _kOrange : Colors.white38,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FAHRTEN ITEM
// ─────────────────────────────────────────────────────────────

class _NavItemFahrten extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final BuildContext context;

  const _NavItemFahrten({
    required this.isSelected,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer2<AnfrageService, SeenAnfragenService>(
              builder: (context, anfrageService, seenService, _) {
                final uid = context.read<IAuthRepository>().currentUser?.userId;
                bool hasUnseen = false;

                if (uid != null) {
                  final ownerIds = anfrageService
                      .getAnfragenForFahrer(uid)
                      .where((a) => a.status == AnfrageStatus.offen)
                      .map((a) => a.id);

                  final requesterIds = anfrageService
                      .getAnfragenByRequester(uid)
                      .where((a) => a.status != AnfrageStatus.offen || a.vonFahrer)
                      .map((a) => a.id);

                  hasUnseen = seenService.hasUnseenOwner(uid, ownerIds) ||
                      seenService.hasUnseenRequester(uid, requesterIds);
                }

                return AnimatedSwitcher(
                  duration: _kDuration,
                  child: Stack(
                    key: ValueKey(isSelected),
                    clipBehavior: Clip.none,
                    children: [
                      Transform.translate(
                        offset:
                            isSelected ? const Offset(0, -2) : Offset.zero,
                        child: Icon(
                          isSelected
                              ? Icons.directions_car
                              : Icons.directions_car_outlined,
                          color: isSelected ? _kOrange : Colors.white38,
                          size: isSelected
                              ? SizeHelper.w(context, 0.075)
                              : SizeHelper.w(context, 0.065),
                        ),
                      ),
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
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _kDuration,
              style: TextStyle(
                fontSize: SizeHelper.w(context, 0.028),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? _kOrange : Colors.white38,
              ),
              child: const Text('Fahrten'),
            ),
          ],
        ),
      ),
    );
  }
}