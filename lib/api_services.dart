import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger.dart';
import 'model_barcode.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  final Dio _dio = Dio();
  String _baseUrl = '';

  ApiHelper();

  // Initialize Dio after fetching server details
  void initializeDio(String ip, String port) {
    _baseUrl = 'http://$ip:$port';
    Logger.log(
        'INITIALIZING DIO WITH BASE URL: $_baseUrl', level: LogLevel.debug);
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        // Allow all responses < 500 and include 429
        Logger.log(status.toString(), level: LogLevel.debug);
        return status != null && (status == 429 || (status >= 200 && status < 300));
      },
    );
    Logger.log('DIO INITIALIZED SUCCESSFULLY.', level: LogLevel.debug);
  }

  Future<List<String>> fetchImageNameList(String imageDirName) async {
    Logger.log('FETCHING IMAGE LIST FROM $_baseUrl.', level: LogLevel.debug);
    try {
      final response = await _dio.post(
          '/imageList',
        data: {'imageDir': imageDirName},
      ); // Endpoint to get image list

      Logger.log(
          'RESPONSE STATUS = ${response.statusCode.toString().toUpperCase()}.',
          level: LogLevel.debug);

      if (response.statusCode == 200) {
        // Assuming the response contains a list of image URLs
        List<String> images = List<String>.from(response.data);
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
      final response = await _dio.post('/videoList'); // Endpoint to get video list
      Logger.log('RESPONSE = ${response.toString()}.', level: LogLevel.critical);
      Logger.log('RESPONSE STATUS = ${response.statusCode.toString().toUpperCase()}.', level: LogLevel.debug);

      if (response.statusCode == 200) {
        // Extract the list of video names from the "videos" key in the response map
        List<String> videos = List<String>.from(response.data['videos']);
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
    Logger.log('DIO USER LOGIN WITH USERNAME=$username, PASSWORD = $password.',
        level: LogLevel.debug);
    try {
      final response = await _dio.post(
        '/login',
        data: {'username': username, 'password': password},
        options: Options(
          receiveTimeout: const Duration(seconds: 2),
          sendTimeout: const Duration(seconds: 2),
        ),
      );
      if (response.statusCode == 200) {
        Logger.log('LOGIN SUCCESS.', level: LogLevel.debug);
        return true;
      }
      return false;
    } catch (e) {
      Logger.log('DIO LOGIN FAILED. ${e.toString().toUpperCase()}',
          level: LogLevel.error);
      return false;
    }
  }

  Future<bool> testConnectivity() async {
    Logger.log('DIO TEST CONNECTION.', level: LogLevel.debug);
    try {
      final response = await _dio.get('/ping');
      Logger.log('Response received: ${response.data}', level: LogLevel.debug);
      if (response.statusCode == 200) {
        Logger.log('DIO TEST SUCCESSFUL.', level: LogLevel.debug);
        return true;
      }
      Logger.log('DIO TEST FAILURE WITH STATUS CODE ${response.statusCode}.',
          level: LogLevel.error);
      return false;
    } catch (e) {
      Logger.log('GENERAL EXCEPTION: ${e.toString().toUpperCase()}.',
          level: LogLevel.error);
      return false;
    }
  }

  Future<BarcodeData?> barcodeScan(String barcode) async {
    Logger.log('DIO BARCODE SCAN.', level: LogLevel.debug);
    try {
      final response = await _dio.post(
        '/scanBarcode',
        data: {'barcode': barcode},
      );

      if (response.statusCode == 200) {
        if (response.data['message'] == "BARCODE NOT FOUND.") {
          Logger.log('BARCODE NOT FOUND.', level: LogLevel.error);
          return null;
        } else {
          // Parse the data into BarcodeData model
          print(response.data['data']);
          BarcodeData barcodeData = BarcodeData.fromJson(response.data['data']);
          Logger.log('BARCODE DATA FOUND: ${barcodeData.toJson()}', level: LogLevel.debug);
          return barcodeData;
        }
      }
      else if (response.statusCode == 429) {
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
      Logger.log('DIO TEST FAILURE WITH STATUS CODE ${response.statusCode}.', level: LogLevel.error);
      return null;
    } catch (e) {
      Logger.log('GENERAL EXCEPTION: ${e.toString().toUpperCase()}.', level: LogLevel.error);
      return null;
    }
  }

  Future<String?> updateTerminalDetailsTServer(payload) async {
    Logger.log('DIO UPDATING TERMINAL DETAILS IN SERVER...', level: LogLevel.debug);
    try {
      final response = await _dio.post('/insertTerminalData', data: payload);
      if (response.statusCode == 200) {
        Logger.log('DIO TERMINAL DETAILS UPDATED...', level: LogLevel.debug);
        return response.data['message'];
      }
      Logger.log('DIO TERMINAL DETAIL UPDATE FAILURE WITH STATUS CODE ${response.statusCode}...',
          level: LogLevel.error);
      return 'TERMINAL UPDATE FAILURE';
    } catch (e) {
      Logger.log('GENERAL EXCEPTION: ${e.toString().toUpperCase()}...',
          level: LogLevel.error);
      return e.toString();
    }
  }

  Future<String?> getActivationDetailsFromServer(payload) async{
    Logger.log('DIO GETTING ACTIVATION DETAILS FROM SERVER.', level: LogLevel.debug);
    try {
      final response = await _dio.post('/getActivationData', data: payload);
      if (response.statusCode == 200) {
        Logger.log('DIO ACTIVATION DATA FETCHED.', level: LogLevel.debug);
        return response.data['activationCode'];
      }
      Logger.log('DIO ACTIVATION DATA FETCH FAILURE WITH STATUS CODE ${response.statusCode}.',
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
      // Adjust the endpoint to match your API route for fetching the logo
      final response = await _dio.get('/logo', options: Options(responseType: ResponseType.bytes));

      Logger.log(
          'RESPONSE STATUS = ${response.statusCode.toString().toUpperCase()}.',
          level: LogLevel.debug);

      if (response.statusCode == 200) {
        // Assuming the response contains the logo image bytes
        Logger.log('LOGO FETCHED SUCCESSFULLY.', level: LogLevel.debug);
        return response.data; // Return the image bytes
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
      // Adjust the endpoint to match your API route for fetching the text scroll content
      final response = await _dio.get('/readTextScrollData');
      Logger.log(
          'RESPONSE STATUS = ${response.statusCode.toString().toUpperCase()}.',
          level: LogLevel.debug);
      if (response.statusCode == 200) {
        // Assuming the response contains the text content as a string
        Logger.log('TEXT SCROLL CONTENT FETCHED SUCCESSFULLY.', level: LogLevel.debug);
        return response.data.toString(); // Return the text content
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


