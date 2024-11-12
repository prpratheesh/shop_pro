import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart' as barcode_scanner;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_pro/model_barcode.dart';
import 'package:shop_pro/price_display.dart';
import 'package:shop_pro/speech.dart';
import 'api_config.dart';
import 'config_page.dart';
import 'db_operations.dart';
import 'font_sizes.dart';
import 'logger.dart';
import 'messages.dart';
import 'package:dio/dio.dart';
import 'api_services.dart';
import 'model_api_config.dart';
import 'model_error_log.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // For compute
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'mqtt_service.dart';
import 'package:restart_app/restart_app.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const platform = MethodChannel('nativeScanner');
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isBarcodeScanned = false;
  bool processing = false;
  String? lastBarcode;
  DateTime? lastScanTime;
  final Duration debounceDuration = const Duration(milliseconds: 300);
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  late ApiHelper _apiHelper;
  List<String> imageUrls = [];
  int _currentImageIndex = 0;
  Timer? _overlayRemovalTimer; // Timer for overlay removal
  Timer? _imageScrollTimer; // Timer for image scrolling
  bool imageLoadComplete = false;
  List<Uint8List> imageBytesList = []; // To store all downloaded images
  final dbProvider = DBProvider.db;
  late ApiDataModel apiData;
  bool _isApiInitialized = false;
  double _opacity = 0.0; // Initial opacity set to 0 (hidden)
  bool _apiAvailable = true;
  OverlayEntry? _overlayEntry;
  final priceSpeaker = PriceSpeaker();
  bool overlay_show = false;
  int imageDuration = 5;
  int displayDuration = 5;
  bool bannerEnable = false;
  bool logoEnable = false;
  Uint8List? _logoImageData; // Variable to hold the logo image data
  late MqttService mqttService;
  List<String> _notifications = [];
  String imageDirName = 'dir1';
  bool isTimerPaused = false; // Flag to track timer status
  String receivedMessage = '';
  int imagesDownloaded = 0; // Counter for downloaded images
  String old_notification = 'dir1';

  @override
  void initState() {
    super.initState();
    priceSpeaker.setVoice("en"); // British English
    priceSpeaker.setSpeechRate(0.5); // Speed at 70%
    // Access the MqttProvider
    _initialize();
  }

  @override
  void dispose() {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _barcodeController.removeListener(_handleBarcodeInput);
    _barcodeController.dispose();
    _focusNode.dispose();
    _overlayRemovalTimer?.cancel();
    _imageScrollTimer?.cancel();
    mqttService.disconnect();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await getServerData(); // Fetch server data and initialize API
      await _loadImageNameListFromApi(imageDirName); // Proceed with loading images

      // Set state variables from API data
      setState(() {
        imageDuration = int.parse(apiData.imageDisplay);
        displayDuration = int.parse(apiData.priceDisplay);
        bannerEnable = apiData.bannerEnable.toLowerCase() == 'true';
        logoEnable = apiData.logoEnable.toLowerCase() == 'true';
        Logger.log('TIMER DATA LOADED: IMAGE TRANSITION IN->$imageDuration, PRICE DISPLAY IN->$displayDuration', level: LogLevel.info);
      });

      _startImageScrollTimer();

      // Initialize image scrolling timer
      // _imageScrollTimer = Timer.periodic(Duration(seconds: imageDuration), (Timer timer) {
      //   if (imageUrls.isNotEmpty && imageLoadComplete) {
      //     setState(() {
      //       _currentImageIndex = (_currentImageIndex + 1) % imageUrls.length;
      //     });
      //   }
      // });

      // Initialize MQTT service
      mqttService = MqttService(
        broker: apiData.serverIP,
        clientIdentifier: 'PC_${apiData.clientID}',
        port: 1883,
        onNotificationReceived: _handleNotification, // Pass the callback
      );
      await initializeMqtt();

      platform.setMethodCallHandler((MethodCall call) async {
        try {
          if (call.method == 'onBarcodeScanned') {
            String barcode = call.arguments as String;
            setState(() {
              _opacity = 1.0; // Set opacity to 1 when a barcode is scanned
              _barcodeController.text = barcode;
            });

            Logger.log('BARCODE SCANNED: $barcode', level: LogLevel.info);

            if (_isApiInitialized && _apiAvailable) {
              await barcodeInquire(barcode);
            } else {
              Logger.log('PLEASE WAIT. API NOT AVAILABLE.', level: LogLevel.error);
            }

            // Reduce opacity and clear barcode after display duration
            Future.delayed(Duration(seconds: displayDuration), () {
              setState(() {
                _opacity = 0.0;
                _barcodeController.text = '';
              });
            });
          }
        } catch (e) {
          Logger.log('Error in handling native method call: $e', level: LogLevel.error);
        }
      });
    } catch (e) {
      Logger.log('INITIALIZATION ERROR: $e', level: LogLevel.error);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ConfigPage()),
      );
    }
  }

  Future<void> initializeMqtt() async {
    mqttService.statusStream.listen((status) {
      switch (status) {
        case MqttConnectionStatus.connected:
        // Handle connected status
          scaffoldMsg('CONNECTED TO SERVER BROKER');
          break;
        case MqttConnectionStatus.disconnected:
        // Handle disconnected status
          scaffoldMsg('DISCONNECTED FROM SERVER BROKER');
          break;
        case MqttConnectionStatus.error:
        // Handle error status
          scaffoldMsg('BROKER CONNECTION ERROR');
          break;
      }
    });

    try {
      await mqttService.connect();
      mqttService.messageStream.listen(
            (List<MqttReceivedMessage<MqttMessage>> messages) async {
          for (var receivedMessage in messages) {
            final MqttPublishMessage mqttMessage = receivedMessage.payload as MqttPublishMessage;
            final String notification = utf8.decode(mqttMessage.payload.message);
          }
        },
        onError: (error) {
          Logger.log('MQTT BROKER STREAM ERROR: $error', level: LogLevel.critical);
        },
      );
    } catch (e) {
      Logger.log('MQTT CONNECTION ERROR: $e', level: LogLevel.critical);
    }
  }

  Future<void> _handleNotification(notification) async{
    setState(() {
      receivedMessage = notification;
    });
    if(notification == 'dir1'){
      _pauseImageScrollTimer();
      Logger.log('NEW NOTIFICATION RECEIVED: $notification', level: LogLevel.critical);
      imageDirName = 'dir1';
      setState(() {
        _currentImageIndex = 0;
        imageBytesList.clear();
      });
      await _loadImageNameListFromApi(imageDirName);
      _resumeImageScrollTimer();
    }else if(notification == 'dir2'){
      _pauseImageScrollTimer();
      Logger.log('NEW NOTIFICATION RECEIVED: $notification', level: LogLevel.critical);
      imageDirName = 'dir2';
      setState(() {
        _currentImageIndex = 0;
        imageBytesList.clear();
      });
      await _loadImageNameListFromApi(imageDirName);
      _resumeImageScrollTimer();
    }
  }

  // Future<void> connect() async {
  //   try {
  //     await mqttService.connect(['system/notifications']);
  //     Logger.log('CONNECTED TO MQTT BROKER.', level: LogLevel.info);
  //   } catch (e) {
  //     Logger.log('ERROR CONNECTING MQTT BROKER.', level: LogLevel.error);
  //     mqttService.disconnect();
  //     Logger.log('MQTT SERVICE DISCONNECTED.', level: LogLevel.error);
  //     Logger.log(e.toString().toUpperCase(), level: LogLevel.error);
  //     throw e; // Rethrow the error if needed for handling in the caller
  //   }
  // }

  Future<void> _loadImageNameListFromApi(imageDirName) async {
    int totalImages = 0; // Set this before starting the download process
    totalImages = 0;
    if (_apiHelper == null) {
      Logger.log('API NOT INITIALIZED, WAITING...', level: LogLevel.info);
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isApiInitialized = false;
      });
      return _loadImageNameListFromApi(imageDirName); // Retry after delay
    }

    try {
      final fetchedImages = await _apiHelper.fetchImageNameList(imageDirName);
      Logger.log('IMAGE LIST FETCHED: $fetchedImages', level: LogLevel.info);
      setState(() {
        imageUrls = fetchedImages ?? ['assets/images/bg1.jpg'];
        imageLoadComplete = true;
      });
      totalImages = imageUrls.length;
      Logger.log('IMAGE COUNT = $totalImages', level: LogLevel.info);

      // Call to fetch the logo image
      final logoBytes = await _apiHelper.fetchLogo(); // Fetch logo
      if (logoBytes != null) {
        Logger.log('LOGO FETCHED SUCCESSFULLY, SIZE: ${logoBytes.length} bytes', level: LogLevel.info);
        // Store the logo bytes in a variable
        // Assuming you have a variable declared like this:
        _logoImageData = logoBytes; // Create this variable in your class to hold logo data
      } else {
        Logger.log('FAILED TO FETCH LOGO.', level: LogLevel.error);
        _logoImageData = null; // Reset logo data if fetching failed
      }

      for (String imageName in imageUrls) {
        _handleImageDownload(imageDirName, totalImages, imageName);
      }
      setState(() {
        _isApiInitialized = true;
      });
    } catch (e) {
      Logger.log('ERROR FETCHING IMAGES: $e', level: LogLevel.error);
      setState(() {
        imageUrls = ['assets/images/bg1.jpg'];
        imageLoadComplete = false;
      });
      setState(() {
        _isApiInitialized = false;
      });
    }
  }

  // Function to start the timer
  void _startImageScrollTimer() {
    // If the timer is already running, return
    if (_imageScrollTimer != null && _imageScrollTimer!.isActive) return;

    _imageScrollTimer = Timer.periodic(Duration(seconds: imageDuration), (Timer timer) {
      if (imageUrls.isNotEmpty && imageLoadComplete && !isTimerPaused) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % imageUrls.length;
        });
      }
    });
  }

  // Function to pause the timer
  void _pauseImageScrollTimer() {
    if (_imageScrollTimer != null) {
      _imageScrollTimer!.cancel(); // Cancel the timer
      _imageScrollTimer = null; // Clear the reference
      isTimerPaused = true; // Set the flag to true
    }
  }

  // Function to resume the timer
  void _resumeImageScrollTimer() {
    if (isTimerPaused) {
      isTimerPaused = false; // Reset the pause flag
      _startImageScrollTimer(); // Restart the timer
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    final methodName = call.method;
    final arguments = call.arguments as String;
    final currentTime = DateTime.now();
    final formattedTime = dateFormat.format(currentTime);
    Logger.log('METHOD CALL RECEIVED AT $formattedTime WITH METHOD: $methodName', level: LogLevel.info);
    Logger.log('RECEIVED ARGUMENTS: $arguments', level: LogLevel.info);

    if (methodName == 'onBarcodeScanned') {
      final handleStartTime = DateTime.now();
      Logger.log('HANDLER STARTED: $methodName', level: LogLevel.info);
      if (processing) {
        Logger.log('PROCESSING IN PROGRESS, IGNORING NEW BARCODE', level: LogLevel.info);
        return;
      }

      if (arguments.isEmpty) {
        Logger.log('ERROR: EMPTY BARCODE RECEIVED', level: LogLevel.error);
        return;
      }

      if (lastBarcode == arguments &&
          DateTime.now().difference(lastScanTime ?? DateTime.fromMillisecondsSinceEpoch(0)) < debounceDuration) {
        Logger.log('BARCODE SCAN DEBOUNCED: $arguments', level: LogLevel.info);
        return;
      }

      lastBarcode = arguments;
      lastScanTime = DateTime.now();

      setState(() {
        _barcodeController.text = arguments;
        isBarcodeScanned = true;
      });

      Logger.log('START HANDLING BARCODE AT ${dateFormat.format(handleStartTime)}', level: LogLevel.info);
      await _handleBarcodeInput();
      final handleEndTime = DateTime.now();
      Logger.log('END HANDLING BARCODE AT ${dateFormat.format(handleEndTime)}', level: LogLevel.info);
      Logger.log('PROCESSING TIME: ${handleEndTime.difference(handleStartTime).inMilliseconds} MS', level: LogLevel.info);

      setState(() {
        processing = false;
      });
      if(!processing){
        // _barcodeController.clear();
      }
    }
  }

  Future<void> _handleBarcodeInput() async {
    if (DateTime.now().difference(lastScanTime ?? DateTime.fromMillisecondsSinceEpoch(0)) < debounceDuration) {
      return;
    }
    lastScanTime = DateTime.now();
    final barcodeInput = _barcodeController.text;
    Logger.log('BARCODE SCANNED - $barcodeInput', level: LogLevel.info);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      isBarcodeScanned = false;
      processing = false;
    });
  }

  Future<void> _handleImageDownload(String imageDirName, int totalImages, String imageName) async {
    setState(() {
      imagesDownloaded = 0;
      imageBytesList.clear();
    });
    try {
      // Bundle the arguments in a Map
      final Map<String, String> args = {
        'imagePath': imageDirName, // Added imagePath here
        'imageName': imageName,
        'ipAddress': apiData.serverIP ?? '',
        'portNo': apiData.portNo ?? ''
      };

      final Uint8List imageBytes = await compute(downloadImage, args);

      setState(() {
        imageBytesList.add(imageBytes); // Add downloaded image to the list
        imagesDownloaded++; // Increment the counter for downloaded images
      });

      Logger.log('$imagesDownloaded IMAGE DOWNLOADED SUCCESSFULLY OUT OF $totalImages', level: LogLevel.info);
    } catch (e) {
      Logger.log('IMAGE $imagesDownloaded DOWNLOAD FAILED.', level: LogLevel.error);
      Logger.log('ERROR DOWNLOADING IMAGE: $e', level: LogLevel.error);
    }
  }

  void _hideSystemBars() {
    // Hides both the status bar and the navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Optional: Make the system navigation bar and status bar transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  Future<void> getServerData() async {
    try {
      // Logger.log('ENTERED L1-----', level: LogLevel.info);
      apiData = (await dbProvider.getApiData())!;
      if (apiData.serverIP != null && apiData.portNo != null) {
        // Logger.log('ENTERED L2-----', level: LogLevel.info);
        _apiHelper = ApiHelper(); // Initialize _apiHelper
        _apiHelper.initializeDio(apiData.serverIP, apiData.portNo);
        Logger.log('DIO INITIALIZED SUCCESSFULLY.', level: LogLevel.info);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ConfigPage()),
        );
      }
    } catch (e) {
      Logger.log('ERROR FETCHING SERVER DATA: $e', level: LogLevel.error);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ConfigPage()),
      );
      rethrow; // Re-throw exception to handle it in the calling function
    }
  }

  Future<void> barcodeInquire(String barcode) async {
    setState(() {
      _apiAvailable = false;
    });
    if(barcode=="\$TRIOSSETUP\$"){
      _hideSystemBars();
      setState(() {
        _apiAvailable = true;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ConfigPage()),
      );
    }
    else {
      try {
        Logger.log('CALLING BARCODE INQUIRY: $barcode', level: LogLevel.info);
        final data = await _apiHelper.barcodeScan(barcode);
        if (data != null) {
          _onScanCompleted(data);
        } else {
          if(!overlay_show) {
            setState(() {
              overlay_show = true;
            });
            _removeOverlay();
            priceSpeaker.speakMessage("ITEM NOTT FOUND");
            Logger.log('ITEM NOT FOUND', level: LogLevel.info);
            final overlay = Overlay.of(context);
            _overlayEntry = OverlayEntry(
              builder: (context) => TemporaryOverlay(errorMessage: 'ITEM NOT FOUND', duration: Duration(seconds: displayDuration)),
            );
            overlay.insert(_overlayEntry!);
            // Automatically remove the overlay after 5 seconds and update the state
            _overlayRemovalTimer = Timer(Duration(seconds: displayDuration), () async {
              _removeOverlay();
              setState(() {
                overlay_show = false;
              });
            });
          }
          priceSpeaker.speakMessage("ITEM NOTT FOUND");
          Logger.log('NO DATA FOUND', level: LogLevel.info);
        }
      } catch (e) {
        Logger.log('ERROR IN BARCODE INQUIRY: $e', level: LogLevel.error);
      }
    }
    setState(() {
      _apiAvailable = true;
    });
  }

  void _showOverlay(BarcodeData message) async{
    // Remove any existing overlay before showing a new one
    if(message.barcode!='' || message.barcode!=null) {
      if (message.barcode != 'STATUS429' &&
          message.description != 'STATUS429') {
        setState(() {
          overlay_show = true;
        });
        _removeOverlay();
        // Logger.log('CURRENCY : ${apiData.currency}', level: LogLevel.error);
        if(apiData.voice=='VOICE1' && apiData.currency == 'AED') {
          priceSpeaker.speakPriceAED(message.retail);
        }else if(apiData.voice=='VOICE1' && apiData.currency == 'OMR'){
          priceSpeaker.speakPriceOMR(message.retail);
        }
        else{
          priceSpeaker.speakPriceText(message.retail);
        }
        Logger.log('PRICE DISPLAY STARTING FOR $displayDuration SECONDS', level: LogLevel.info);
        final overlay = Overlay.of(context);
        // Determine the logo to display
        Uint8List? logoData = _logoImageData; // Use network logo if available
        logoData ??= (await rootBundle.load('assets/images/Logo.jpg')).buffer.asUint8List();
        _overlayEntry = OverlayEntry(
          builder: (context) => TemporaryOverlay(
            message: message,
            duration: Duration(seconds: displayDuration),
            showLogo: logoEnable, // Pass the logoEnable boolean
            logoData: logoData, // Pass logo data to TemporaryOverlay
            currencySymbol: apiData.currency,
          ),
        );
        overlay.insert(_overlayEntry!);
        // Automatically remove the overlay after 5 seconds and update the state
        _overlayRemovalTimer = Timer(Duration(seconds: displayDuration), () async {
          _removeOverlay();
          setState(() {
            overlay_show = false;
          });
        });
      } else {
        priceSpeaker.speakMessage('SCAN LIMIT REACHED');
      }
    }else{
      setState(() {
        overlay_show = true;
      });
      _removeOverlay();
      priceSpeaker.speakMessage('ITEM NOT FOUND');
      final overlay = Overlay.of(context);
      _overlayEntry = OverlayEntry(
        builder: (context) => TemporaryOverlay(message: message),
      );
      overlay.insert(_overlayEntry!);
      // Automatically remove the overlay after 5 seconds and update the state
      _overlayRemovalTimer = Timer(const Duration(seconds: 8), () async {
        _removeOverlay();
        setState(() {
          overlay_show = false;
        });
      });
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    if (_overlayRemovalTimer != null) {
      _overlayRemovalTimer?.cancel();
      _overlayRemovalTimer = null;
    }
  }

  void _onScanCompleted(BarcodeData data) {
    if(!overlay_show) {
      Logger.log('ENTERED $overlay_show', level: LogLevel.info);
      _showOverlay(data);
    }
  }

  void scaffoldMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        textAlign: TextAlign.center,
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ));
  }

  @override
  Widget _barcodeScanner(FontSizes fontSizes) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: Duration(seconds: displayDuration),
      child: Container(
        width: MediaQuery.of(context).size.width / 3,
        height: MediaQuery.of(context).size.height / 10,
        alignment: Alignment.center,
        child: Stack(
          children: [
            // Container for background color
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200], // Off-white background color
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                focusNode: _focusNode,
                autofocus: false,
                // enabled: false,
                controller: _barcodeController,
                style: TextStyle(
                  fontSize: fontSizes.baseFontSize,
                  color: Colors.black, // Text color inside the text field
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black, width: 5.0),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  labelStyle: const TextStyle(color: Colors.black),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onEditingComplete: () {
                  _hideSystemBars();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            // Positioned widgets for icons
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                onPressed: () {
                  _hideSystemBars();
                },
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                onPressed: () {
                  _hideSystemBars();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSizes = FontSizes.fromContext(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: AnimatedSwitcher(
          duration: const Duration(seconds: 1), // Animation duration
          child: Container(
            key: ValueKey<int>(_currentImageIndex), // Unique key for the current image
            // padding: const EdgeInsets.symmetric(horizontal: 20),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageBytesList.isNotEmpty
                    ? MemoryImage(imageBytesList[_currentImageIndex]) // Use downloaded image
                    : const AssetImage('assets/images/bg1.jpg') as ImageProvider, // Use fallback predefined image
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0), BlendMode.luminosity),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(0)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: Colors.grey.shade200,
                    offset: const Offset(2, 4),
                    blurRadius: 5,
                    spreadRadius: 2)
              ],
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue, Colors.purple],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0), // Optional: Add padding for spacing from the bottom
                  child: _barcodeScanner(fontSizes), // Place the barcode scanner at the bottom
                ),
                // Conditionally display the banner
                Visibility(
                  visible: bannerEnable, // Banner visibility based on bannerEnable
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      color: Colors.black.withOpacity(0.7), // Banner background color
                      height: MediaQuery.of(context).size.height/10,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Text(
                          'Scan Your Price Here',
                          style: TextStyle(color: Colors.white, fontSize: fontSizes.largerFontSize8), // Use fontSizes for consistency
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // void _changeImage() {
  //   setState(() {
  //     _currentImageIndex = (_currentImageIndex + 1) % imageBytesList.length; // Cycle through images
  //   });
  // }
}

Future<Uint8List> downloadImage(Map<String, String> args) async {
  final String imagePath = args['imagePath']!; // Retrieve imagePath
  final String imageName = args['imageName']!;
  final String ipAddress = args['ipAddress']!;
  final String portNo = args['portNo']!;

  final Dio dio = Dio();
  final String url = 'http://$ipAddress:$portNo/image/$imagePath/$imageName';

  try {
    final response = await dio.get<Uint8List>(
      url,
      options: Options(responseType: ResponseType.bytes), // Use ResponseType.bytes for binary data
    );

    return response.data!;
  } catch (e) {
    throw Exception('Failed to download image: $e');
  }
}
