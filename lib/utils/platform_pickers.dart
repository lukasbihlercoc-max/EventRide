import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showPlatformDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  if (Platform.isIOS) {
    DateTime selected = initialDate;
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (ctx) => _CupertinoDatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        onChanged: (dt) => selected = dt,
        onConfirm: () => Navigator.pop(ctx, selected),
      ),
    );
  }
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: const Locale('de', 'DE'),
  );
}

Future<TimeOfDay?> showPlatformTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  if (Platform.isIOS) {
    TimeOfDay selected = initialTime;
    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (ctx) => _CupertinoTimePickerSheet(
        initialTime: initialTime,
        onChanged: (t) => selected = t,
        onConfirm: () => Navigator.pop(ctx, selected),
      ),
    );
  }
  return showTimePicker(context: context, initialTime: initialTime);
}

class _CupertinoDatePickerSheet extends StatelessWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onConfirm;

  const _CupertinoDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark ||
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Container(
      height: 320,
      color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: onConfirm,
                child: const Text('Fertig'),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CupertinoTimePickerSheet extends StatelessWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;
  final VoidCallback onConfirm;

  const _CupertinoTimePickerSheet({
    required this.initialTime,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark ||
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Container(
      height: 280,
      color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: onConfirm,
                child: const Text('Fertig'),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  initialTime.hour,
                  initialTime.minute,
                ),
                onDateTimeChanged: (dt) =>
                    onChanged(TimeOfDay(hour: dt.hour, minute: dt.minute)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
