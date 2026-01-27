// appbar_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/widgets/calendar_widget.dart';
import 'package:my_app/views/widgets/sizehelper_widget.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? rightWidget;

  const AppBarWidget({
    super.key, 
    required this.title,
    this.rightWidget,
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
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: SizeHelper.w(context, 0.045),
                  color: Colors.white
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat.yMMMd("de_DE").format(DateTime.now()),
            style: TextStyle(
              fontSize: SizeHelper.w(context, 0.03),
              color: Colors.white
            ),
          ),
          SizedBox(width: SizeHelper.w(context, 0.02)),
          Icon(Icons.calendar_today, 
            size: SizeHelper.w(context, 0.05),
            color: Colors.white
          ),
        ],
      ),
    );
  }
}
