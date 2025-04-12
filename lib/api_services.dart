import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger.dart';
import 'model_barcode.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  late http.Client _client;
  String _baseUrl = '';

  ApiHelper();

  // Initialize the base URL after fetching server details
  void initializeHttp(String ip, String port) {
    _baseUrl = 'http://$ip:$port';
    Logger.log(
        'INITIALIZING HTTP WITH BASE URL: $_baseUrl', level: LogLevel.debug);
    _client = _createCustomHttpClient();
  }

  // Create a custom HTTP client
  http.Client _createCustomHttpClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true; // Disable HTTPS validation

    // Set a timeout for all requests
    httpClient.connectionTimeout = const Duration(seconds: 10);

    return http.Client();
  }

  Future<List<String>> fetchImageNameList(String imageDirName) async {
    Logger.log('FETCHING IMAGE LIST FROM $_baseUrl.', level: LogLevel.debug);
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/imageList'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageDir': imageDirName}),
      );

      Logger.log(
          'RESPONSE STATUS = ${response.statusCode.toString().toUpperCase()}.',
          level: LogLevel.debug);

      if (response.statusCode == 200) {
        // Assuming the response contains a list of image URLs
        List<String> images = List<String>.from(jsonDecode(response.body));
        Logger.log('IMAGE LIST FETCHED SUCCESSFULLY.', level: LogLevel.debug);
        return images;
      } else {
        Logger.log('FAILED TO FETCH IMAGE LIST.', level: LogLevel.error);
        return [];
      }
    } catch (e) {
      Logger.log('EXCEPTION OCCURRED WHILE FETCHING IMAGES. ${e
          .toString()
          .toUpperCase()}', level: LogLevel.error);
      return [];
    }
  }

  Future<List<String>> fetchVideoNameList() async {
    Logger.log('FETCHING VIDEO LIST FROM $_baseUrl.', level: LogLevel.debug);
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/videoList'),
        headers: {'Content-Type': 'application/json'},
      );

      Logger.log('RESPONSE = ${response.body}.', level: LogLevel.critical);
      Logger.log('RESPONSE STATUS = ${response.statusCode.toString().toUpperCase()}.', level: LogLevel.debug);

      if (response.statusCode == 200) {
        // Extract the list of video names from the "videos" key in the response map
        List<String> videos = List<String>.from(jsonDecode(response.body)['videos']);
        Logger.log('VIDEO LIST FETCHED SUCCESSFULLY.', level: LogLevel.debug);
        return videos;
      } else {
        Logger.log('FAILED TO FETCH VIDEO LIST.', level: LogLevel.error);
        return [];
      }
    } catch (e) {
      Logger.log('EXCEPTION OCCURRED WHILE FETCHING VIDEOS. ${e.toString().toUpperCase()}', level: LogLevel.error);
      return [];
    }
  }

  Future<bool> login(String username, String password) async {
    Logger.log('HTTP USER LOGIN WITH USERNAME=$username, PASSWORD = $password.',
        level: LogLevel.debug);
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        Logger.log('LOGIN SUCCESS.', level: LogLevel.debug);
        return true;
      }
      return false;
    } catch (e) {
      Logger.log('HTTP LOGIN FAILED. ${e.toString().toUpperCase()}',
          level: LogLevel.error);
      return false;
    }
  }

  Future<bool> testConnectivity() async {
    Logger.log('HTTP TEST CONNECTION.', level: LogLevel.debug);
    Logger.log('${Uri.parse('$_baseUrl/ping')}', level: LogLevel.debug);
    try {
      // final response = await _client.get(Uri.parse(('http://10.0.2.2:3000/ping')));
      final response = await _client.get(Uri.parse('http://192.168.0.138:3000/ping'));
      Logger.log('Response received: ${response.body}', level: LogLevel.debug);
      if (response.statusCode == 200) {
        Logger.log('HTTP TEST SUCCESSFUL.', level: LogLevel.debug);
        return true;
      }
      Logger.log('HTTP TEST FAILURE WITH STATUS CODE ${response.statusCode}.',
          level: LogLevel.error);
      return false;
    } catch (e) {
      Logger.log('GENERAL EXCEPTION: ${e.toString().toUpperCase()}.',
          level: LogLevel.error);
      return false;
    }
  }

  Future<BarcodeData?> barcodeScan(String barcode) async {
    Logger.log('HTTP BARCODE SCAN.', level: LogLevel.debug);
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/scanBarcode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barcode': barcode}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message'] == "BARCODE NOT FOUND.") {
          Logger.log('BARCODE NOT FOUND.', level: LogLevel.error);
          return null;
        } else {
          // Parse the data into BarcodeData model
          BarcodeData barcodeData = BarcodeData.fromJson(responseData['data']);
          Logger.log('BARCODE DATA FOUND: ${barcodeData.toJson()}', level: LogLevel.debug);
          return barcodeData;
        }
      } else if (response.statusCode == 429) {
        return BarcodeData(
          barcode: 'STATUS429',
          description: 'STATUS429',
          arabic: '',
          retail: 0.0,
          spFlag: 0,
          spPrice: 0.0,
          spStart: DateTime(1900, 1, 1), // Default start date
          spEnd: DateTime(2099, 12, 31), // Default end date
        );
      }
      Logger.log('HTTP TEST FAILURE WITH STATUS CODE ${response.statusCode}.', level: LogLevel.error);
      return null;
    } catch (e) {
      Logger.log('GENERAL EXCEPTION: ${e.toString().toUpperCase()}.', level: LogLevel.error);
      return null;
    }
  }

  Future<String?> updateTerminalDetailsTServer(payload) async {
    Logger.log('HTTP UPDATING TERMINAL DETAILS IN SERVER...', level: LogLevel.debug);
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/insertTerminalData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        Logger.log('HTTP TERMINAL DETAILS UPDATED...', level: LogLevel.debug);
        return jsonDecode(response.body)['message'];
      }
      Logger.log('HTTP TERMINAL DETAIL UPDATE FAILURE WITH STATUS CODE ${response.statusCode}...',
          level: LogLevel.error);
      return 'TERMINAL UPDATE FAILURE';
    } catch (e) {
      Logger.log('GENERAL EXCEPTION: ${e.toString().toUpperCase()}...',
          level: LogLevel.error);
      return e.toString();
    }
  }

  Future<String?> getActivationDetailsFromServer(payload) async {
    Logger.log('HTTP GETTING ACTIVATION DETAILS FROM SERVER.', level: LogLevel.debug);
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/getActivationData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        Logger.log('HTTP ACTIVATION DATA FETCHED.', level: LogLevel.debug);
        return jsonDecode(response.body)['activationCode'];
      }
      Logger.log('HTTP ACTIVATION DATA FETCH FAILURE WITH STATUS CODE ${response.statusCode}.',
          level: LogLevel.error);
      return 'ERROR';
    } catch (e) {
      Logger.log('GENERAL EXCEPTION: ${e.toString().toUpperCase()}.',
          level: LogLevel.error);
      return 'ERROR';
    }
  }

  Future<Uint8List?> fetchLogo() async {
    Logger.log('FETCHING LOGO FROM $_baseUrl.', level: LogLevel.debug);
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/logo'));

      Logger.log(
          'RESPONSE STATUS = ${response.statusCode.toString().toUpperCase()}.',
          level: LogLevel.debug);

      if (response.statusCode == 200) {
        Logger.log('LOGO FETCHED SUCCESSFULLY.', level: LogLevel.debug);
        return response.bodyBytes; // Return the image bytes
      } else {
        Logger.log('FAILED TO FETCH LOGO.', level: LogLevel.error);
        return null;
      }
    } catch (e) {
      Logger.log('EXCEPTION OCCURRED WHILE FETCHING LOGO. ${e.toString().toUpperCase()}', level: LogLevel.error);
      return null;
    }
  }

  Future<String?> fetchTextScroll() async {
    Logger.log('FETCHING TEXT SCROLL CONTENT FROM $_baseUrl.', level: LogLevel.debug);
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/readTextScrollData'));

      Logger.log(
          'RESPONSE STATUS = ${response.statusCode.toString().toUpperCase()}.',
          level: LogLevel.debug);

      if (response.statusCode == 200) {
        Logger.log('TEXT SCROLL CONTENT FETCHED SUCCESSFULLY.', level: LogLevel.debug);
        return response.body; // Return the text content
      } else {
        Logger.log('FAILED TO FETCH TEXT SCROLL CONTENT.', level: LogLevel.error);
        return null;
      }
    } catch (e) {
      Logger.log('EXCEPTION OCCURRED WHILE FETCHING TEXT SCROLL CONTENT. ${e.toString().toUpperCase()}', level: LogLevel.error);
      return null;
    }
  }
}