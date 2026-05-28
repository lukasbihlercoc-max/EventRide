import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────

const _kGradient = LinearGradient(
  begin: Alignment(0.26, -1.0),
  end: Alignment(-0.26, 1.0),
  colors: [Color(0xFF2E3F5E), Color(0xFF28395A), Color(0xFF22324F)],
  stops: [0.0, 0.5, 1.0],
);

const kSheetBarrierColor = Color(0x73080C16);

// Consistently open a sheet with correct barrier + transparency
Future<T?> showAppSheet<T>(
  BuildContext context,
  Widget Function(BuildContext ctx) builder, {
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: kSheetBarrierColor,
    isScrollControlled: true,
    isDismissible: isDismissible,
    builder: builder,
  );
}

// Shared input decoration for text fields inside sheets
InputDecoration sheetInputDecoration({
  required String label,
  IconData? prefixIcon,
  String? errorText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    errorText: errorText,
    prefixIcon:
        prefixIcon != null ? Icon(prefixIcon, color: Colors.white54) : null,
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFF5A04A), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSheetShell — outer gradient container + drag handle
// Use this directly for complex sheets with custom content.
// ─────────────────────────────────────────────────────────────────────────────

class AppSheetShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AppSheetShell({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final effectivePadding =
        padding ?? EdgeInsets.fromLTRB(22, 14, 22, 26 + bottomPadding);

    return Container(
      decoration: BoxDecoration(
        gradient: _kGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: effectivePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSheetHeader — Icon-Kreis + Titel in einer Zeile
// ─────────────────────────────────────────────────────────────────────────────

class AppSheetHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const AppSheetHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────────────────────

class AppSheetPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppSheetPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5A04A), Color(0xFFE08A35)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5A04A).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppSheetDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppSheetDangerButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF5350).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppSheetGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppSheetGhostButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBottomSheet — einfaches Icon + Titel + Body + 2 Buttons
// ─────────────────────────────────────────────────────────────────────────────

class AppBottomSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  // danger: true → roter Primär-Button (für destruktive Aktionen)
  final bool danger;

  const AppBottomSheet({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSheetHeader(icon: icon, iconColor: iconColor, title: title),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 22),
          danger
              ? AppSheetDangerButton(label: primaryLabel, onTap: onPrimary)
              : AppSheetPrimaryButton(label: primaryLabel, onTap: onPrimary),
          const SizedBox(height: 10),
          AppSheetGhostButton(label: secondaryLabel, onTap: onSecondary),
        ],
      ),
    );
  }
}