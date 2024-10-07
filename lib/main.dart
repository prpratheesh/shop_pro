import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shop_pro/config_page.dart';
import 'db_operations.dart';
import 'logger.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatefulWidget {
  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    Logger.log('APPLICATION STARTED.', level: LogLevel.info);
    Logger.log('DB SETTINGS STARTED.', level: LogLevel.info);
    DBProvider.db.initDB(newVersion: 4);
    Logger.log('DB SETTINGS COMPLETED.', level: LogLevel.info);
    requestPermissions();
    Logger.log('PERMISSION SETTINGS COMPLETED.', level: LogLevel.info);
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
      home: LoginPage(),//LIVE
      // home: ConfigPage(),//TESTING
    );
  }
}
