// sizehelper_widget.dart
import 'package:flutter/material.dart';

class SizeHelper {
  static double h(BuildContext context, double percent) =>
      MediaQuery.of(context).size.height * percent;
  static double w(BuildContext context, double percent) =>
      MediaQuery.of(context).size.width * percent;
}
