import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Logger {
  static void log(String message, {LogLevel level = LogLevel.info}) {
    if (kReleaseMode) return; // Disable logging in release mode

    final color = _getColor(level);
    final logMessage = _getLogMessage(message, level);

    debugPrint(
      logMessage,
      wrapWidth: 1024, // Adjust the width to avoid wrapping issues
    );
  }

  static String _getLogMessage(String message, LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[36m[DEBUG] $message\x1B[0m'; // Cyan
      case LogLevel.info:
        return '\x1B[32m[INFO] $message\x1B[0m'; // Green
      case LogLevel.warning:
        return '\x1B[33m[WARNING] $message\x1B[0m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m[ERROR] $message\x1B[0m'; // Red
      case LogLevel.critical:
        return '\x1B[35m[CRITICAL] $message\x1B[0m'; // Magenta
      default:
        return message;
    }
  }

  static Color _getColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.cyan;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.yellow;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
      default:
        return Colors.white;
    }
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}
