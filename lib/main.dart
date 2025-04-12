import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shop_pro/config_page.dart';
import 'package:shop_pro/speech.dart';
import 'db_operations.dart';
import 'logger.dart';
import 'login_page.dart';
import 'mqtt_service.dart'; // Import MqttService
import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
  int androidVersion = androidInfo.version.sdkInt;
  // _initializePermissions();

  // Initialize Database
  Logger.log('APPLICATION STARTED.', level: LogLevel.info);
  Logger.log('DB SETTINGS STARTED.', level: LogLevel.info);
  await DBProvider.db.initDB(newVersion: 4);
  Logger.log('DB SETTINGS COMPLETED.', level: LogLevel.info);
  Logger.log('ANDROID VERSION: $androidVersion', level: LogLevel.info);

  // Initialize PriceSpeaker
  // PriceSpeaker priceSpeaker = PriceSpeaker();

  // Test PriceSpeaker functionality
  // await priceSpeaker.speakSampleMessage("Hello, welcome to Shop Pro. This is a sample text!");
  // await priceSpeaker.setAndSpeak("Hello there", "en-GB");

  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: App(androidInfo: androidInfo))); // Pass androidInfo to App widget
}

class App extends StatefulWidget {
  final AndroidDeviceInfo androidInfo;

  const App({Key? key, required this.androidInfo}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // Request Permissions after the widget is created
    _initializePermissions();
  }

  void _initializePermissions() {
    // Call the async method without awaiting it
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      // Bluetooth Permissions (Android 12+)
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.location,
      Permission.microphone,
      Permission.camera,
      Permission.speech,
      Permission.audio, // Audio permission
    ].request();

    statuses.forEach((permission, status) {
      if (status.isGranted) {
        Logger.log('$permission permission granted.', level: LogLevel.info);
      } else if (status.isDenied) {
        Logger.log('$permission permission denied.', level: LogLevel.warning);
      } else if (status.isPermanentlyDenied) {
        Logger.log('$permission permission permanently denied.', level: LogLevel.critical);
        // Open app settings to allow the user to grant permission manually
        openAppSettings();
      } else if (status.isRestricted) {
        Logger.log('$permission permission is restricted.', level: LogLevel.warning);
      } else {
        Logger.log('$permission permission is in an unknown state.', level: LogLevel.warning);
      }
    });
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
      home: LoginPage(), // You can switch this to LoginPage or another screen
      // home: ConfigPage(), // You can switch this to LoginPage or another screen
    );
  }
}

Future<bool> requestPermissions(AndroidDeviceInfo androidInfo, BuildContext context) async {
  // Get the Android version
  String releaseVersion = androidInfo.version.release;
  int? releaseVersionInt = int.tryParse(releaseVersion.split('.')[0]); // Major version number

  if (releaseVersionInt == null) {
    Logger.log('ANDROID VERSION ERROR: Unable to parse version', level: LogLevel.error);
    return false;
  }

  Logger.log('ANDROID VERSION DECODED: $releaseVersionInt', level: LogLevel.info);

  if (releaseVersionInt >= 10) {
    // Handle permissions for Android 10 and above
    return _requestPermissionsForAndroid10AndAbove(context);
  } else {
    // Handle permissions for below Android 10
    return _requestPermissionsForBelowAndroid10(context);
  }
}

Future<bool> _requestPermissionsForAndroid10AndAbove(BuildContext context) async {
  Logger.log('PERMISSION SETTINGS STARTED.', level: LogLevel.info);
  // Check the current status of Camera and Photos permissions
  final statusCamera = await Permission.camera.status;
  final statusPhotos = await Permission.photos.status;
  final statusMicrophone = await Permission.microphone.status;

  // Log permission statuses
  Logger.log('PERMISSION -> CAMERA = $statusCamera', level: LogLevel.info);
  Logger.log('PERMISSION -> PHOTOS = $statusPhotos', level: LogLevel.info);
  Logger.log('PERMISSION -> AUDIO = $statusMicrophone', level: LogLevel.info);

  // If both Camera and Photos permissions are already granted, return true
  if (statusCamera.isGranted && statusPhotos.isGranted && statusMicrophone.isGranted) {
    Logger.log('Audio, Camera and Photos permissions already granted.', level: LogLevel.info);
    return true;
  }

  // Request both permissions (Camera and Photos)
  final result = await [
    Permission.camera,
    Permission.photos,
    Permission.audio,
  ].request();

  // Return true if both permissions are granted
  if (result[Permission.camera]?.isGranted == true &&
      result[Permission.photos]?.isGranted == true &&
      result[Permission.audio]?.isGranted == true) {
    Logger.log('Audio, Camera and Photos permissions granted.', level: LogLevel.info);
    return true;
  } else {
    Logger.log('Some permissions are still not granted.', level: LogLevel.error);
    return false;
  }
}

Future<bool> _requestPermissionsForBelowAndroid10(BuildContext context) async {
  Logger.log('PERMISSION SETTINGS STARTED.', level: LogLevel.info);

  // Check the current status of the Storage and Camera permissions
  final statusStorage = await Permission.storage.status;
  final statusCamera = await Permission.camera.status;

  // Log permission statuses
  Logger.log('PERMISSION -> STORAGE = $statusStorage', level: LogLevel.info);
  Logger.log('PERMISSION -> CAMERA = $statusCamera', level: LogLevel.info);

  // If both Storage and Camera permissions are already granted, return true
  if (statusStorage.isGranted && statusCamera.isGranted) {
    Logger.log('Both Storage and Camera permissions already granted.', level: LogLevel.info);
    return true;
  }

  // Request both permissions (Storage and Camera)
  final result = await [
    Permission.storage,
    Permission.camera,
  ].request();

  // Return true if both permissions are granted
  if (result[Permission.storage]?.isGranted == true &&
      result[Permission.camera]?.isGranted == true) {
    Logger.log('Both Storage and Camera permissions granted.', level: LogLevel.info);
    return true;
  } else {
    Logger.log('Some permissions are still not granted.', level: LogLevel.error);
    return false;
  }
}

Future<void> _showPermissionDialog(BuildContext context, String permissionName, Permission permission) async {
  return showCupertinoDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: const Text('Permission Required'),
        content: SingleChildScrollView(
          // Wrap the content in SingleChildScrollView
          child: ListBody(
            // ListBody widget allows for a vertical arrangement of content
            children: <Widget>[
              Text('This app requires $permissionName permission to function properly.'),
            ],
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              // Request the permission
              await permission.request();
            },
            child: const Text('Allow'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}