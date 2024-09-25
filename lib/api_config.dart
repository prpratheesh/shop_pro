/*
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart'
as barcode_scanner;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_services.dart';
import 'db_operations.dart';
import 'font_sizes.dart';
import 'messages.dart';
import 'package:android_id/android_id.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:android_id/android_id.dart';

import 'model_api_config.dart';
import 'model_error_log.dart';


class APIConfig extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _APIConfigState();
}

class _APIConfigState extends State<APIConfig> with SingleTickerProviderStateMixin{
  final GlobalKey<FormState> _apiKey = GlobalKey<FormState>();
  static const String fontFamily = 'Lato';
  TextEditingController ipAddressController = TextEditingController();
  TextEditingController portNumberController = TextEditingController();
  TextEditingController deviceIDController = TextEditingController();
  TextEditingController locationIDController = TextEditingController();
  FocusNode ipAddressFocusNode = FocusNode();
  FocusNode portNumberFocusNode = FocusNode();
  FocusNode deviceIDFocusNode = FocusNode();
  FocusNode locationIDFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  String statusMsg = '';
  List<String> statusMessages = [];
  Timer? _timer;
  late AnimationController animationController;
  final ScrollController _scrollController = ScrollController();
  static const _androidIdPlugin = AndroidId();
  var _androidId = 'NA';
  final dbProvider = DBProvider.db;
  String deviceIdType = 'NA';
  final ApiHelper _apiHelper = ApiHelper();

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    animationController.repeat();
    _getSavedApiData();
  }

  @override
  void dispose() {
    animationController.dispose();
    ipAddressController.dispose();
    portNumberController.dispose();
    deviceIDController.dispose();
    locationIDController.dispose();
    ipAddressFocusNode.dispose();
    portNumberFocusNode.dispose();
    deviceIDFocusNode.dispose();
    locationIDFocusNode.dispose();
    scrollController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Widget _title(FontSizes fontSizes) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height / 10,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: 'S',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSizes.baseFontSize,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
          children: <TextSpan>[
            TextSpan(
              text: 'ystem ',
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.white,
                fontSize: fontSizes.baseFontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
            TextSpan(
              text: 'S',
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.blue,
                fontSize: fontSizes.baseFontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
            TextSpan(
              text: 'ettings',
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.blue,
                fontSize: fontSizes.baseFontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _configEntry(FontSizes fontSizes) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width / 2.1, // Set the desired width here
              height: MediaQuery.of(context).size.height / 18,
              margin: const EdgeInsets.all(1.0),
              decoration: BoxDecoration(
                color: Colors.transparent, // Transparent background
                borderRadius: BorderRadius.circular(5.0), // Rounded corners
                border: Border.all(
                  color: Colors.white, // Border color
                  width: 1.0,
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: TextFormField(
                  autofocus: true,
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(portNumberFocusNode);
                  },
                  style: TextStyle(
                    fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Lato',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5, // Add letter spacing
                  ),
                  focusNode: ipAddressFocusNode,
                  controller: ipAddressController,
                  textInputAction: TextInputAction.next,
                  cursorColor: Colors.white, // Set cursor color here
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lan, color: Colors.blue, size: fontSizes.baseFontSize),
                    hintText: 'IP ADDRESS',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    LengthLimitingTextInputFormatter(15), // Limit to 15 characters
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2.1, // Set the desired width here
              height: MediaQuery.of(context).size.height / 18,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.transparent, // Transparent background
                borderRadius: BorderRadius.circular(5.0), // Rounded corners
                border: Border.all(
                  color: Colors.white, // Border color
                  width: 1.0,
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: TextFormField(
                  autofocus: true,
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(locationIDFocusNode);
                  },
                  style: TextStyle(
                    fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Lato',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5, // Add letter spacing
                  ),
                  focusNode: portNumberFocusNode,
                  controller: portNumberController,
                  textInputAction: TextInputAction.next,
                  cursorColor: Colors.white, // Set cursor color here
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.computer, color: Colors.blue, size: fontSizes.baseFontSize),
                    hintText: 'PORT NO',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(5), // Limit to 5 characters
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width / 2.1, // Set the desired width here
              height: MediaQuery.of(context).size.height / 18,
              margin: const EdgeInsets.all(1.0),
              decoration: BoxDecoration(
                color: Colors.transparent, // Transparent background
                borderRadius: BorderRadius.circular(5.0), // Rounded corners
                border: Border.all(
                  color: Colors.white, // Border color
                  width: 1.0,
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: TextFormField(
                  autofocus: false,
                  enabled: false,
                  style: TextStyle(
                    fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Lato',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5, // Add letter spacing
                  ),
                  focusNode: deviceIDFocusNode,
                  controller: deviceIDController,
                  textInputAction: TextInputAction.next,
                  cursorColor: Colors.white, // Set cursor color here
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.card_membership, color: Colors.blue, size: fontSizes.baseFontSize),
                    hintText: 'DEVICE ID',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(16), // Limit to 15 characters
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2.1, // Set the desired width here
              height: MediaQuery.of(context).size.height / 18,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.transparent, // Transparent background
                borderRadius: BorderRadius.circular(5.0), // Rounded corners
                border: Border.all(
                  color: Colors.white, // Border color
                  width: 1.0,
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: TextFormField(
                  autofocus: true,
                  onEditingComplete: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  style: TextStyle(
                    fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Lato',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5, // Add letter spacing
                  ),
                  focusNode: locationIDFocusNode,
                  controller: locationIDController,
                  textInputAction: TextInputAction.next,
                  cursorColor: Colors.white, // Set cursor color here
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined, color: Colors.blue, size: fontSizes.baseFontSize),
                    hintText: 'LOC ID',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(3), // Limit to 5 characters
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 2.1, // Set the desired width here
                height: MediaQuery.of(context).size.height / 18,
                child: InkWell(
                  onTap: () async{
                    if((ipAddressController.text.isNotEmpty) && (portNumberController.text.isNotEmpty)) {
                      _addStatusMessage('CONNECTING TO SERVER...');
                      _apiHelper.updateBaseUrl(ipAddressController.text,portNumberController.text);
                      try{
                        if(await _apiHelper.testConnectivity()){
                          _addStatusMessage('SERVER CONNECTION SUCCESS...');
                        }else{
                          _addStatusMessage('SERVER CONNECTION FAILURE...');
                        }
                      }catch(e){
                        _addStatusMessage('SERVER CONNECTION FAILURE...');
                      }
                      }else{
                      SnackbarHelper.show(context, 'All Fields are Mandatory', Colors.white);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3), // Slightly transparent purple background
                      borderRadius: BorderRadius.circular(5.0), // Rounded corners
                      border: Border.all(
                        color: Colors.purple, // Purple border
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'TEST',
                        style: TextStyle(
                          fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Lato',
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.5, // Add letter spacing
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 2.1, // Set the desired width here
                height: MediaQuery.of(context).size.height / 18,
                child: InkWell(
                  onTap: () async{
                    _addStatusMessage('VALIDATING DATA...');
                    if(ipAddressController.text.isNotEmpty && portNumberController.text.isNotEmpty && deviceIDController.text.isNotEmpty && locationIDController.text.isNotEmpty){
                      _apiHelper.updateBaseUrl(ipAddressController.text,portNumberController.text);
                      if(await _apiHelper.testConnectivity()){
                        ApiDataModel apiData = ApiDataModel(
                          serverIP: ipAddressController.text,
                          portNO: portNumberController.text,
                          deviceID: deviceIDController.text,
                          deviceIDType: deviceIdType,
                          locID: locationIDController.text,
                          dateTime: DateTime.now().toIso8601String(),
                        );
                        if(await dbProvider.insertApiData(apiData)){
                          _addStatusMessage('DATABASE UPDATED...');
                        }else{
                          _addStatusMessage('DATABASE UPDATE FAILURE...');
                        }
                    }else{
                        _addStatusMessage('SERVER CONNECTION FAILURE...');
                      }
                    }else{
                      SnackbarHelper.show(context, 'All Fields are Mandatory', Colors.white);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3), // Slightly transparent purple background
                      borderRadius: BorderRadius.circular(5.0), // Rounded corners
                      border: Border.all(
                        color: Colors.blue, // Purple border
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'SAVE',
                        style: TextStyle(
                          fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Lato',
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.5, // Add letter spacing
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width/1.04, // Set the desired width here
                height: MediaQuery.of(context).size.height / 15,
                child: InkWell(
                  onTap: () {
                    print("Container pressed");
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3), // Slightly transparent purple background
                      borderRadius: BorderRadius.circular(5.0), // Rounded corners
                      border: Border.all(
                        color: Colors.red, // Purple border
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'SYNC',
                        style: TextStyle(
                          fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Lato',
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.5, // Add letter spacing
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 2.1, // Set the desired width here
                height: MediaQuery.of(context).size.height / 15,
                child: InkWell(
                  onTap: () {
                    print("Container pressed");
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3), // Slightly transparent purple background
                      borderRadius: BorderRadius.circular(5.0), // Rounded corners
                      border: Border.all(
                        color: Colors.green, // Purple border
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'INIT DB',
                        style: TextStyle(
                          fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Lato',
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.5, // Add letter spacing
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 2.1, // Set the desired width here
                height: MediaQuery.of(context).size.height / 15,
                child: InkWell(
                  onTap: () {
                    print("Container pressed");
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.3), // Slightly transparent purple background
                      borderRadius: BorderRadius.circular(5.0), // Rounded corners
                      border: Border.all(
                        color: Colors.yellow, // Purple border
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'RESET APP',
                        style: TextStyle(
                          fontSize: fontSizes.baseFontSize, // Adjust font size as needed
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Lato',
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.5, // Add letter spacing
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          padding: EdgeInsets.all(10.0),
          width: MediaQuery.of(context).size.width / 1.05,
          height: MediaQuery.of(context).size.height / 2,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(
              color: Colors.white,
              width: 1.0,
            ),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Ensure alignment to the start
                children: <Widget>[
                  for (var message in statusMessages)
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: fontSizes.baseFontSize,
                        fontStyle: FontStyle.normal,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  void _addStatusMessage(String message) {
    String currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    setState(() {
      statusMessages.add('$currentTime: $message');
    });
    Timer(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _initAndroidId() async {
    String androidId;
    try {
      androidId = await _androidIdPlugin.getId() ?? 'NA';
      if(androidId == 'NA'){
        setState(() {
          deviceIdType = 'MANUAL';
        });
      }
    } on PlatformException {
      setState(() {
        deviceIdType = 'MANUAL';
      });
      ErrorMsgDataModel errorMsg = ErrorMsgDataModel(
        page: "API_CONFIG",
        method: "_initAndroidId",
        errorMessage: e.toString(),
        dateTime: DateTime.now().toString(),
      );
      await dbProvider.insertErrorLog(errorMsg);
      SnackbarHelper.show(context, 'Error Generating Device ID', Colors.red);
      androidId = 'Failed to get Android ID.';
    }
    if (!mounted) return;
    setState(() {
      deviceIdType = 'AUTO';
      _androidId = androidId;
      deviceIDController.text = _androidId;
      print(_androidId.length);
    });
  }

  void _getSavedApiData() async {
    ApiDataModel? data;
    try {
      data = await dbProvider.getApiData();
      if(data!=null){
        setState(() {
          ipAddressController.text = data!.serverIP;
          portNumberController.text = data!.portNO;
          deviceIDController.text = data!.deviceID;
          locationIDController.text = data!.locID;
          deviceIdType = data.deviceIDType;
        });
        FocusScope.of(context).unfocus();
        //TODO -- HANDLE DEVICE ID MATCHING AND MANUAL ENTRY.
      }else{
        _initAndroidId();
      }
    }catch(e){
      ErrorMsgDataModel errorMsg = ErrorMsgDataModel(
        page: "API_CONFIG",
        method: "_getSavedApiData",
        errorMessage: e.toString(),
        dateTime: DateTime.now().toString(),
      );
      await dbProvider.insertErrorLog(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a FontSizes object based on the current context
    final fontSizes = FontSizes.fromContext(context);
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background image with transparency and lighting effect
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7), // Adjust transparency here
              BlendMode.darken, // Adjust lighting effect here
            ),
            child: Image.asset(
              'assets/images/cloud.jpg', // Replace with your image asset path
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SingleChildScrollView(
            child: SizedBox(
              // padding: const EdgeInsets.symmetric(horizontal: 0),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const SizedBox(
                    height: 20,
                  ),
                  _title(fontSizes),
                  _configEntry(fontSizes),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
