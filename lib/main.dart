import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shop_pro/config_page.dart';
import 'db_operations.dart';
import 'logger.dart';
import 'login_page.dart';
import 'mqtt_service.dart'; // Import MqttService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database
  Logger.log('APPLICATION STARTED.', level: LogLevel.info);
  Logger.log('DB SETTINGS STARTED.', level: LogLevel.info);
  await DBProvider.db.initDB(newVersion: 4);
  Logger.log('DB SETTINGS COMPLETED.', level: LogLevel.info);

  // Request Permissions
  Logger.log('PERMISSION SETTINGS STARTED.', level: LogLevel.info);
  bool permissionsGranted = await requestPermissions();
  if (!permissionsGranted) {
    Logger.log('PERMISSIONS NOT GRANTED. Exiting application.', level: LogLevel.error);
    exit(0); // Exit the app if permissions are not granted
  }
  Logger.log('PERMISSION SETTINGS COMPLETED.', level: LogLevel.info);
  runApp(App());
}

Future<bool> requestPermissions() async {
  Logger.log('PERMISSION SETTINGS STARTED.', level: LogLevel.info);
  // Check the status of both storage and camera permissions
  final statusStorage = await Permission.storage.status;
  final statusCamera = await Permission.camera.status;
  // If both permissions are granted, return true
  if (statusStorage.isGranted && statusCamera.isGranted) {
    return true;
  }
  // Request both permissions
  final result = await [
    Permission.storage,
    Permission.camera,
  ].request();

  // Return true if both permissions are granted
  return result[Permission.storage]?.isGranted == true &&
      result[Permission.camera]?.isGranted == true;
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Set preferred orientations for the app
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      title: "Shop Pro",
      debugShowCheckedModeBanner: false,
      home: ConfigPage(), // Pass mqttService to LoginPage
      // home: LoginPage(), // Pass mqttService to LoginPage
    );
  }
}
