// navbar_widget.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/data/app_user.dart';
import 'package:my_app/data/block_service.dart';
import 'package:my_app/data/chat_conversation.dart';
import 'package:my_app/data/chat_service.dart';
import 'package:my_app/data/event_request.dart';
import 'package:my_app/data/interfaces/i_auth_repository.dart';
import 'package:my_app/data/anfrage_daten.dart';
import 'package:my_app/data/anfrage_service.dart';
import 'package:my_app/data/license_request.dart';
import 'package:my_app/data/notifiers.dart';
import 'package:my_app/data/seen_anfragen_service.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';
import 'package:provider/provider.dart';

const _kOrange   = Color(0xFFF5A04A);
const _kDuration = Duration(milliseconds: 320);
const _kCurve    = Curves.easeOutCubic;

class NavBarWidget extends StatelessWidget {
  const NavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, _) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeHelper.w(context, 0.04),
              vertical: SizeHelper.h(context, 0.005),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  height: SizeHelper.h(context, 0.085),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF140F0C).withValues(alpha: 0.62),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth / 3;
                      final pillWidth = itemWidth * 0.78;
                      final pillLeft =
                          selectedPage * itemWidth + (itemWidth - pillWidth) / 2;

                      return Stack(
                        children: [
                          // Sliding Pill
                          AnimatedPositioned(
                            duration: _kDuration,
                            curve: _kCurve,
                            left: pillLeft,
                            top: constraints.maxHeight * 0.14,
                            bottom: constraints.maxHeight * 0.14,
                            width: pillWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: _kOrange.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: _kOrange.withValues(alpha: 0.32),
                                  width: 1,
                                ),
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
                              _NavItemProfil(
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
            ),
          );
        },
      ),
    );
  }
}

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
                scale: animation, child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? _kOrange : Colors.white.withValues(alpha: 0.55),
                size: SizeHelper.w(context, 0.065),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _kDuration,
              style: TextStyle(
                fontSize: SizeHelper.w(context, 0.028),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _kOrange : Colors.white.withValues(alpha: 0.55),
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
class _NavItemFahrten extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final BuildContext context;

  const _NavItemFahrten({
    required this.isSelected,
    required this.onTap,
    required this.context,
  });

  @override
  State<_NavItemFahrten> createState() => _NavItemFahrtenState();
}

class _NavItemFahrtenState extends State<_NavItemFahrten> {
  List<ChatConversation> _conversations = [];
  StreamSubscription<List<ChatConversation>>? _chatSub;
  StreamSubscription<AppUser?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = context.read<IAuthRepository>().authStateChanges.listen(
      (user) {
        _chatSub?.cancel();
        _chatSub = null;
        if (!mounted) return;
        setState(() => _conversations = []);
        if (user != null) {
          _chatSub = context
              .read<ChatService>()
              .conversationsStream(user.userId)
              .listen(
                (convos) {
                  if (mounted) setState(() => _conversations = convos);
                },
                onError: (_) {
                  if (mounted) setState(() => _conversations = []);
                },
              );
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer3<AnfrageService, SeenAnfragenService, BlockService>(
              builder: (context, anfrageService, seenService, blockService, _) {
                final uid = context.read<IAuthRepository>().currentUser?.userId;
                bool hasAnfrageUnseen = false;
                bool hasChatUnread = false;
                if (uid != null) {
                  final blockedIds = blockService.blockedUserIds;
                  final visibleConvos = _conversations.where((c) {
                    final other = c.ownerId == uid ? c.requesterId : c.ownerId;
                    return !blockedIds.contains(other);
                  }).toList();

                  final requesterIds = anfrageService
                      .getAnfragenByRequester(uid)
                      .where((a) =>
                          (a.status != AnfrageStatus.offen &&
                              a.status != AnfrageStatus.storniert) ||
                          (a.vonFahrer && a.status == AnfrageStatus.offen))
                      .map((a) => a.id);
                  hasAnfrageUnseen =
                      seenService.hasUnseenRequester(uid, requesterIds);

                  final activePassengerFahrtIds = anfrageService.alleAnfragen
                      .where((a) =>
                          a.requesterId == uid &&
                          a.status != AnfrageStatus.storniert &&
                          a.status != AnfrageStatus.abgelehnt &&
                          a.status != AnfrageStatus.fahrtGeloescht)
                      .map((a) => a.fahrtId)
                      .toSet();

                  hasChatUnread = visibleConvos.any((c) {
                    if (!c.isUnreadFor(uid)) return false;
                    if (c.requesterId == uid) {
                      return activePassengerFahrtIds.contains(c.fahrtId);
                    }
                    return c.ownerId == uid;
                  });
                }
                final hasUnseen = hasAnfrageUnseen || hasChatUnread;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: _kDuration,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Icon(
                        widget.isSelected
                            ? Icons.directions_car
                            : Icons.directions_car_outlined,
                        key: ValueKey(widget.isSelected),
                        color: widget.isSelected
                            ? _kOrange
                            : Colors.white.withValues(alpha: 0.55),
                        size: SizeHelper.w(widget.context, 0.065),
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
                );
              },
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _kDuration,
              style: TextStyle(
                fontSize: SizeHelper.w(widget.context, 0.028),
                fontWeight:
                    widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: widget.isSelected
                    ? _kOrange
                    : Colors.white.withValues(alpha: 0.55),
              ),
              child: const Text('Fahrten'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _NavItemProfil extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final BuildContext context;

  const _NavItemProfil({
    required this.isSelected,
    required this.onTap,
    required this.context,
  });

  @override
  State<_NavItemProfil> createState() => _NavItemProfilState();
}

class _NavItemProfilState extends State<_NavItemProfil> {
  int _licenseCount = 0;
  int _eventCount = 0;
  StreamSubscription<List<LicenseRequest>>? _licenseSub;
  StreamSubscription<List<EventRequest>>? _eventSub;
  StreamSubscription<AppUser?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = context.read<IAuthRepository>().authStateChanges.listen(
      (user) {
        _licenseSub?.cancel();
        _eventSub?.cancel();
        _licenseSub = null;
        _eventSub = null;
        if (!mounted) return;
        setState(() {
          _licenseCount = 0;
          _eventCount = 0;
        });
        final auth = context.read<IAuthRepository>();
        if (user != null && auth.isAdmin) {
          _licenseSub = auth.pendingLicenseRequests.listen(
            (list) { if (mounted) setState(() => _licenseCount = list.length); },
            onError: (_) {},
          );
          _eventSub = auth.pendingEventRequests.listen(
            (list) { if (mounted) setState(() => _eventCount = list.length); },
            onError: (_) {},
          );
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _licenseSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext _) {
    final hasPending = _licenseCount > 0 || _eventCount > 0;
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: _kDuration,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    widget.isSelected
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded,
                    key: ValueKey(widget.isSelected),
                    color: widget.isSelected
                        ? _kOrange
                        : Colors.white.withValues(alpha: 0.55),
                    size: SizeHelper.w(widget.context, 0.065),
                  ),
                ),
                if (hasPending)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _kOrange,
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
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _kDuration,
              style: TextStyle(
                fontSize: SizeHelper.w(widget.context, 0.028),
                fontWeight:
                    widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: widget.isSelected
                    ? _kOrange
                    : Colors.white.withValues(alpha: 0.55),
              ),
              child: const Text('Profil'),
            ),
          ],
        ),
      ),
    );
  }
}
