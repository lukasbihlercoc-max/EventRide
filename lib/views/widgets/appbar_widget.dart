// appbar_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/widgets/calendar_widget.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? rightWidget;
  final bool showLogo;
  final VoidCallback? onLogoTap;

  const AppBarWidget({
    super.key,
    required this.title,
    this.rightWidget,
    this.showLogo = false,
    this.onLogoTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // ✅ Zurück zur Standardhöhe

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(SizeHelper.h(context, 0.07)), // ✅ Hier ist context verfügbar
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeHelper.w(context, 0.04)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showLogo)
                GestureDetector(
                  onTap: onLogoTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: SizeHelper.w(context, 0.055),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Event',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Ride',
                              style: TextStyle(color: Color(0xFFF5A623)),
                            ),
                          ],
                        ),
                      ),
                      if (onLogoTap != null) ...[
                        SizedBox(width: SizeHelper.w(context, 0.015)),
                        Icon(
                          Icons.info_outline,
                          size: SizeHelper.w(context, 0.042),
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ],
                    ],
                  ),
                )
              else
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: SizeHelper.w(context, 0.045),
                    color: Colors.white,
                  ),
                ),
              rightWidget ?? _buildDefaultCalendarButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCalendarButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showCalendarOverlay(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.yMMMd("de_DE").format(DateTime.now()),
              style: TextStyle(
                fontSize: SizeHelper.w(context, 0.03),
                color: Colors.white,
              ),
            ),
            SizedBox(width: SizeHelper.w(context, 0.02)),
            Icon(
              Icons.calendar_today,
              size: SizeHelper.w(context, 0.05),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
