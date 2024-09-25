import 'package:flutter/material.dart';
import 'font_sizes.dart';

class SnackbarHelper {
  static void show(BuildContext context, String msg, Color color) {
    final fontSizes = FontSizes.fromContext(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        style: TextStyle(
          color: color,
          fontSize: fontSizes.baseFontSize,
        ),
        textAlign: TextAlign.center,
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ));
  }
}
