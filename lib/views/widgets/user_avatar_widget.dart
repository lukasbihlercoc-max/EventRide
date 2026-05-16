// user_avatar_widget.dart
// Zeigt ein rundes Profilbild (Network) oder Initialen als Fallback.
//
// UserAvatarWidget  – wenn photoUrl schon bekannt ist
// UserAvatarById    – holt photoUrl einmalig aus Firestore

import 'package:flutter/material.dart';
import 'package:my_app/data/interfaces/i_user_repository.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserAvatarWidget
// ─────────────────────────────────────────────────────────────────────────────

class UserAvatarWidget extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const UserAvatarWidget({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initialsAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF2F5ED6),
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.65,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final avatar = (photoUrl != null && photoUrl!.isNotEmpty)
        ? SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: Stack(
              children: [
                initialsAvatar,
                ClipOval(
                  child: Image.network(
                    photoUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                        child: child,
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ],
            ),
          )
        : initialsAvatar;

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserAvatarById
// Lädt die photoUrl einmalig aus Firestore users/{userId}.
// Verwendet als Fallback Initialen aus [name].
//
// onTap    – wird mit der geladenen photoUrl aufgerufen (nur Avatar tappbar)
// onPhotoLoaded – benachrichtigt den Parent, wenn das Foto geladen ist,
//                 damit er selbst eine größere Tap-Fläche anbieten kann
// ─────────────────────────────────────────────────────────────────────────────

class UserAvatarById extends StatefulWidget {
  final String userId;
  final String name;
  final double radius;
  final Color? backgroundColor;

  /// Nur Avatar tappbar – wird mit der geladenen photoUrl aufgerufen.
  final void Function(String? photoUrl)? onTap;

  /// Benachrichtigt den Parent sobald die photoUrl aus Firestore geladen wurde.
  final void Function(String? photoUrl)? onPhotoLoaded;

  const UserAvatarById({
    super.key,
    required this.userId,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
    this.onTap,
    this.onPhotoLoaded,
  });

  @override
  State<UserAvatarById> createState() => _UserAvatarByIdState();
}

class _UserAvatarByIdState extends State<UserAvatarById> {
  static final _cache = <String, String>{};
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    final cached = _cache[widget.userId];
    if (cached != null) {
      _photoUrl = cached;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPhotoLoaded?.call(cached);
      });
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final url = await context.read<IUserRepository>().getPhotoUrl(widget.userId);
      if (url != null) _cache[widget.userId] = url;
      if (mounted && url != null) {
        setState(() => _photoUrl = url);
        widget.onPhotoLoaded?.call(url);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return UserAvatarWidget(
      name: widget.name,
      photoUrl: _photoUrl,
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      onTap: widget.onTap == null ? null : () => widget.onTap!(_photoUrl),
    );
  }
}
