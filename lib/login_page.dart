import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
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
import 'package:video_player/video_player.dart';
import 'package:auto_scroll_text/auto_scroll_text.dart';

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
  List<String> videoUrls = [];
  int _currentImageIndex = 0;
  Timer? _overlayRemovalTimer; // Timer for overlay removal
  Timer? _imageScrollTimer; // Timer for image scrolling
  bool imageLoadComplete = false;
  bool videoLoadComplete = false;
  List<Uint8List> imageBytesList = []; // To store all downloaded images
  List<Uint8List> videoBytesList = []; // To store all downloaded images
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
  String videoDirName = '1';
  bool isTimerPaused = false; // Flag to track timer status
  String receivedMessage = '';
  int imagesDownloaded = 0; // Counter for downloaded images
  int videosDownloaded = 0; // Counter for downloaded images
  String old_notification = 'dir1';
  VideoPlayerController? _videoController;
  int _currentVideoIndex = 0; // Track the current video
  bool videoEnable = false; // Example flag to enable video
  bool videDownloadComplete = false;
  String textScrollContent = '';
  String textScrollData = '';
  final GlobalKey<_LoginPageState> _textScrollKey = GlobalKey<_LoginPageState>();
  bool _loadComplete = false;

  @override
  void initState() {
    super.initState();
    // priceSpeaker.setVoice("en"); // British English
    // priceSpeaker.setSpeechRate(0.5); // Speed at 70%
    // // Access the MqttProvider
    // priceSpeaker.setVoice({"name": "en-gb-x-gba-local", "locale": "en-GB"});
    priceSpeaker.setLanguage("en-GB");
    priceSpeaker.setVolume(1.0);
    priceSpeaker.setSpeechRate(0.5);
    priceSpeaker.setPitch(1.0);
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
    _videoController?.removeListener(_videoPlayerListener);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await getServerData(); // Fetch server data and initialize API
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
              Logger.log(
                  'PLEASE WAIT. API NOT AVAILABLE.', level: LogLevel.error);
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
          scaffoldMsg('ERROR IN HANDLING BARCODE SCAN');
          Logger.log('Error in handling native method call: $e',
              level: LogLevel.error);
        }
      });
      if (apiData.imageScroll == 'true') {
        await _loadImageNameListFromApi(
            imageDirName); // Proceed with loading images
        // Set state variables from API data
        setState(() {
          videoEnable = false;
          imageDuration = int.parse(apiData.imageDisplay);
          displayDuration = int.parse(apiData.priceDisplay);
          bannerEnable = apiData.bannerEnable.toLowerCase() == 'true';
          logoEnable = apiData.logoEnable.toLowerCase() == 'true';
          Logger.log(
              'TIMER DATA LOADED: IMAGE TRANSITION IN->$imageDuration, PRICE DISPLAY IN->$displayDuration',
              level: LogLevel.info);
        });
        _startImageScrollTimer();
        mqttService = MqttService(
          broker: apiData.serverIP,
          clientIdentifier: 'PC_${apiData.clientID}',
          port: 1883,
          onNotificationReceived: _handleNotification, // Pass the callback
        );
        await initializeMqtt();
      } //Fetch image scroll
      if (apiData.videoScroll == 'true') {
        Logger.log('VIDEO SCROLL', level: LogLevel.info);
        try {
          await getServerData();
          if (apiData.videoScroll == 'true') {
            await _loadVideoListFromApi();
            if (videoBytesList.isNotEmpty) {
              _initializeVideoPlayer();
              setState(() {
                Logger.log('VIDEO LOADED', level: LogLevel.critical);
                videoEnable = true;
              });
            }
          }
        } catch (e) {
          Logger.log('INITIALIZATION ERROR: $e', level: LogLevel.error);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ConfigPage()));
        }
      } //Fetch video scroll
      if(apiData.textScroll == 'true') {
        textScrollContent = (await _apiHelper.fetchTextScroll())!;
        Logger.log(textScrollContent, level: LogLevel.error);
        setState(() {
          textScrollData = textScrollContent;
        });
      } //Fetch text scroll
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
            final MqttPublishMessage mqttMessage = receivedMessage
                .payload as MqttPublishMessage;
            final String notification = utf8.decode(
                mqttMessage.payload.message);
          }
        },
        onError: (error) {
          Logger.log(
              'MQTT BROKER STREAM ERROR: $error', level: LogLevel.critical);
        },
      );
    } catch (e) {
      Logger.log('MQTT CONNECTION ERROR: $e', level: LogLevel.critical);
    }
  }

  //video player functions
  Future<void> _initializeVideoPlayer() async {
    // Get the temporary directory to save the video file.
    final directory = await getApplicationDocumentsDirectory();
    final videoFile = await _saveVideoToFile(videoBytesList[_currentVideoIndex], directory);
    // Initialize the video player with the saved file.
    _videoController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {
          _videoController?.play();
          videoEnable = true; // Set video enable flag to true after initialization
        });
        _videoController?.setLooping(false);
        _videoController?.addListener(_videoPlayerListener);
      });
  }

// Save the video to a specific directory and return the File object.
  Future<File> _saveVideoToFile(Uint8List videoData, Directory directory) async {
    // Define the file path and name in the directory.
    final videoPath = '${directory.path}/downloaded_video_${_currentVideoIndex}.mp4';
    final videoFile = File(videoPath);

    // Write the video data to the file.
    await videoFile.writeAsBytes(videoData);
    return videoFile;
  }

  void _videoPlayerListener() {
    if (_videoController != null &&
        _videoController!.value.position == _videoController!.value.duration) {
      // Video has finished playing, move to the next video
      _loadNextVideo();
    }
  }

  void _loadNextVideo() {
    _currentVideoIndex = (_currentVideoIndex + 1) % videoBytesList.length;
    _videoController?.removeListener(_videoPlayerListener);
    _videoController?.dispose();

    _initializeVideoPlayer();
  }

  //video player functions

  Future<void> _handleNotification(notification) async {
    setState(() {
      receivedMessage = notification;
    });
    if (notification == 'dir1') {
      _pauseImageScrollTimer();
      Logger.log(
          'NEW NOTIFICATION RECEIVED: $notification', level: LogLevel.critical);
      imageDirName = 'dir1';
      setState(() {
        _currentImageIndex = 0;
        imageBytesList.clear();
      });
      await _loadImageNameListFromApi(imageDirName);
      _resumeImageScrollTimer();
    } else if (notification == 'dir2') {
      _pauseImageScrollTimer();
      Logger.log(
          'NEW NOTIFICATION RECEIVED: $notification', level: LogLevel.critical);
      imageDirName = 'dir2';
      setState(() {
        _currentImageIndex = 0;
        imageBytesList.clear();
      });
      await _loadImageNameListFromApi(imageDirName);
      _resumeImageScrollTimer();
    } else if (notification == 'msg') {
      textScrollContent = (await _apiHelper.fetchTextScroll())!;
      Logger.log(textScrollContent, level: LogLevel.error);
      setState(() {
        textScrollData = textScrollContent;
      });
    }
  }

  Future<void> _loadImageNameListFromApi(imageDirName) async {
    int totalImages = 0; // Set this before starting the download process
    totalImages = 0;

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
        Logger.log('LOGO FETCHED SUCCESSFULLY, SIZE: ${logoBytes.length} bytes',
            level: LogLevel.info);
        // Store the logo bytes in a variable
        // Assuming you have a variable declared like this:
        _logoImageData =
            logoBytes; // Create this variable in your class to hold logo data
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

  Future<void> _loadVideoListFromApi() async {
    int totalVideos = 0;

    try {
      final fetchedVideos = await _apiHelper.fetchVideoNameList();
      Logger.log('VIDEO LIST FETCHED: $fetchedVideos', level: LogLevel.info);
      setState(() {
        videoUrls = fetchedVideos ?? [];
        videoLoadComplete = true;
      });
      totalVideos = videoUrls.length;
      Logger.log('VIDEO COUNT = $totalVideos', level: LogLevel.info);

      for (String videoName in videoUrls) {
        _handleVideoDownload(totalVideos, videoName);
      }
      setState(() {
        _isApiInitialized = true;
      });
    } catch (e) {
      Logger.log('ERROR FETCHING VIDEOS: $e', level: LogLevel.error);
      setState(() {
        videoUrls = [];
        videoLoadComplete = false;
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

    _imageScrollTimer =
        Timer.periodic(Duration(seconds: imageDuration), (Timer timer) {
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
    Logger.log(
        'METHOD CALL RECEIVED AT $formattedTime WITH METHOD: $methodName',
        level: LogLevel.info);
    Logger.log('RECEIVED ARGUMENTS: $arguments', level: LogLevel.info);

    if (methodName == 'onBarcodeScanned') {
      final handleStartTime = DateTime.now();
      Logger.log('HANDLER STARTED: $methodName', level: LogLevel.info);
      if (processing) {
        Logger.log('PROCESSING IN PROGRESS, IGNORING NEW BARCODE',
            level: LogLevel.info);
        return;
      }

      if (arguments.isEmpty) {
        Logger.log('ERROR: EMPTY BARCODE RECEIVED', level: LogLevel.error);
        return;
      }

      if (lastBarcode == arguments &&
          DateTime.now().difference(
              lastScanTime ?? DateTime.fromMillisecondsSinceEpoch(0)) <
              debounceDuration) {
        Logger.log('BARCODE SCAN DEBOUNCED: $arguments', level: LogLevel.info);
        return;
      }

      lastBarcode = arguments;
      lastScanTime = DateTime.now();

      setState(() {
        _barcodeController.text = arguments;
        isBarcodeScanned = true;
      });

      Logger.log(
          'START HANDLING BARCODE AT ${dateFormat.format(handleStartTime)}',
          level: LogLevel.info);
      await _handleBarcodeInput();
      final handleEndTime = DateTime.now();
      Logger.log('END HANDLING BARCODE AT ${dateFormat.format(handleEndTime)}',
          level: LogLevel.info);
      Logger.log('PROCESSING TIME: ${handleEndTime
          .difference(handleStartTime)
          .inMilliseconds} MS', level: LogLevel.info);

      setState(() {
        processing = false;
      });
      if (!processing) {
        // _barcodeController.clear();
      }
    }
  }

  Future<void> _handleBarcodeInput() async {
    if (DateTime.now().difference(
        lastScanTime ?? DateTime.fromMillisecondsSinceEpoch(0)) <
        debounceDuration) {
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

  Future<void> _handleImageDownload(String imageDirName, int totalImages,
      String imageName) async {
    setState(() {
      imagesDownloaded = 0;
      imageBytesList.clear();
      videDownloadComplete = false;
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

      Logger.log(
          '$imagesDownloaded IMAGE DOWNLOADED SUCCESSFULLY OUT OF $totalImages',
          level: LogLevel.info);
    } catch (e) {
      Logger.log(
          'IMAGE $imagesDownloaded DOWNLOAD FAILED.', level: LogLevel.error);
      Logger.log('ERROR DOWNLOADING IMAGE: $e', level: LogLevel.error);
    }
  }

// Call this method after video download is complete.
  Future<void> _handleVideoDownload(int totalVideos, String videoName) async {
    setState(() {
      videosDownloaded = 0;
      videoBytesList.clear();
    });

    try {
      final Map<String, String> args = {
        'videoPath': videoDirName,
        'videoName': videoName,
        'ipAddress': apiData.serverIP ?? '',
        'portNo': apiData.portNo ?? ''
      };

      // Download the video
      final Uint8List videoBytes = await compute(downloadVideo, args);
      setState(() {
        videoBytesList.add(videoBytes);
        videosDownloaded++;
      });

      Logger.log('$videosDownloaded VIDEO DOWNLOADED SUCCESSFULLY OUT OF $totalVideos', level: LogLevel.info);

      // Once all videos are downloaded, initialize the player with the first one
      if (videosDownloaded == totalVideos) {
        await _initializeVideoPlayer(); // Initialize and play the first video
        setState(() {
          videDownloadComplete = true;
        });
      }
    } catch (e) {
      setState(() {
        videDownloadComplete = false;
      });
      Logger.log('VIDEO DOWNLOAD FAILED.', level: LogLevel.error);
      Logger.log('ERROR DOWNLOADING VIDEO: $e', level: LogLevel.error);
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
      apiData = (await dbProvider.getApiData());
      _apiHelper = ApiHelper(); // Initialize _apiHelper
      _apiHelper.initializeHttp(apiData.serverIP, apiData.portNo);
      Logger.log('DIO INITIALIZED SUCCESSFULLY.', level: LogLevel.info);
      setState(() {
        _loadComplete = true;
      });
        } catch (e) {
      setState(() {
        _loadComplete = false;
      });
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
    if (barcode == "\$TRIOSSETUP\$") {
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
          if (!overlay_show) {
            setState(() {
              overlay_show = true;
            });
            _removeOverlay();
            priceSpeaker.speakMessage("ITEM NOTT FOUND");
            Logger.log('ITEM NOT FOUND', level: LogLevel.info);
            final overlay = Overlay.of(context);
            _overlayEntry = OverlayEntry(
              builder: (context) =>
                  TemporaryOverlay(errorMessage: 'ITEM NOT FOUND',nfpluBarcode: barcode,
                      duration: Duration(seconds: displayDuration)),
            );
            overlay.insert(_overlayEntry!);
            // Automatically remove the overlay after 5 seconds and update the state
            _overlayRemovalTimer =
                Timer(Duration(seconds: displayDuration), () async {
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

  void _showOverlay(BarcodeData message) async {
    // Remove any existing overlay before showing a new one
    // Logger.log('${message.retail.runtimeType}',level: LogLevel.critical);
    if (message.barcode.isNotEmpty) {
      if (message.barcode != 'STATUS429' &&
          message.description != 'STATUS429') {
        setState(() {
          overlay_show = true;
        });
        _removeOverlay();
        // Logger.log('CURRENCY : ${apiData.currency}', level: LogLevel.error);
        if (apiData.voice == 'VOICE1' && apiData.currency == 'AED') {
          priceSpeaker.speakPriceAED(message.retail);
        } else if (apiData.voice == 'VOICE1' && apiData.currency == 'OMR') {
          priceSpeaker.speakPriceOMR(message.retail);
        }
        else {
          priceSpeaker.speakPriceText(message.retail);
        }
        Logger.log('PRICE DISPLAY STARTING FOR $displayDuration SECONDS',
            level: LogLevel.info);
        final overlay = Overlay.of(context);
        // Determine the logo to display
        Uint8List? logoData = _logoImageData; // Use network logo if available
        logoData ??= (await rootBundle.load('assets/images/Logo.jpg')).buffer
            .asUint8List();
        _overlayEntry = OverlayEntry(
          builder: (context) =>
              TemporaryOverlay(
                message: message,
                duration: Duration(seconds: displayDuration),
                showLogo: logoEnable,
                // Pass the logoEnable boolean
                logoData: logoData,
                // Pass logo data to TemporaryOverlay
                currencySymbol: apiData.currency,
              ),
        );
        overlay.insert(_overlayEntry!);
        // Automatically remove the overlay after 5 seconds and update the state
        _overlayRemovalTimer =
            Timer(Duration(seconds: displayDuration), () async {
              _removeOverlay();
              setState(() {
                overlay_show = false;
              });
            });
      } else {
        priceSpeaker.speakMessage('SCAN LIMIT REACHED');
      }
    } else {
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
    if (!overlay_show) {
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

  Widget _barcodeScanner(FontSizes fontSizes) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: Duration(seconds: displayDuration),
      child: Container(
        width: MediaQuery
            .of(context)
            .size
            .width / 3,
        height: MediaQuery
            .of(context)
            .size
            .height / 10,
        alignment: Alignment.center,
        child: Stack(
          children: [
            // Container for background color
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200], // Off-white background color
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: GestureDetector(
                // onTap: () {
                //   // Prevent focus on the TextFormField
                //   FocusScope.of(context).requestFocus(FocusNode());
                //   _hideSystemBars();
                // },
                // onDoubleTap: () {
                //   // Prevent focus on the TextFormField
                //   FocusScope.of(context).requestFocus(FocusNode());
                //   _hideSystemBars();
                // },
                child: TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
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
                      borderSide: const BorderSide(
                          color: Colors.black, width: 5.0),
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
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    _hideSystemBars();
                  },
                  onEditingComplete: () {
                    _hideSystemBars();
                    FocusScope.of(context).unfocus();
                  },
                ),
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
    if(_loadComplete) {
      return Scaffold(
        body: Stack(
          children: [
            // The background content: video or image
            videDownloadComplete
                ? Container(
              key: ValueKey<int>(_currentImageIndex),
              // Unique key for the current image
              height: MediaQuery
                  .of(context)
                  .size
                  .height,
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              child: AspectRatio(
                aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
                child: _videoController != null &&
                    _videoController!.value.isInitialized
                    ? VideoPlayer(_videoController!)
                    : const Center(
                    child: CircularProgressIndicator()), // Show a loader if the video isn't initialized
              ),
            )
                : AnimatedSwitcher(
              duration: const Duration(seconds: 1), // Animation duration
              child: Container(
                key: ValueKey<int>(_currentImageIndex),
                // Unique key for the current image
                height: MediaQuery
                    .of(context)
                    .size
                    .height,
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageBytesList.isNotEmpty
                        ? MemoryImage(
                        imageBytesList[_currentImageIndex]) // Use downloaded image
                        : const AssetImage(
                        'assets/images/bg1.jpg') as ImageProvider,
                    // Use fallback predefined image
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
              ),
            ),
            // Persistent TextScroll widget (This is outside the AnimatedSwitcher now)
            if (textScrollData.isNotEmpty)
              Positioned(
                bottom: 65,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: AutoScrollText(
                    textScrollData,
                    style: TextStyle(fontSize: fontSizes.largerFontSize6, color: Colors.white),
                  ),
                ),
              ),
            // Barcode scanner at the bottom
            // Positioned(
            //   bottom: 50.0,
            //   // Adjust based on the desired position from the bottom
            //   left: 0,
            //   right: 0,
            //   child: _barcodeScanner(
            //       fontSizes), // Place the barcode scanner at the bottom
            // ),
            // Conditionally display the banner
            Visibility(
              visible: bannerEnable, // Banner visibility based on bannerEnable
              child: Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  // Banner background color
                  height: MediaQuery
                      .of(context)
                      .size
                      .height / 10,
                  child: Center(
                    child: Text(
                      'Scan Your Price Here',
                      style: TextStyle(color: Colors.white,
                          fontSize: fontSizes
                              .largerFontSize8), // Use fontSizes for consistency
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    else{
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
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

Future<Uint8List> downloadVideo(Map<String, String> args) async {
  final String videoPath = args['videoPath']!;
  final String videoName = args['videoName']!;
  final String ipAddress = args['ipAddress']!;
  final String portNo = args['portNo']!;
  final Dio dio = Dio();
  final String url = 'http://$ipAddress:$portNo/video/$videoName';
  try {
    final response = await dio.get<Uint8List>(
      url,
      options: Options(responseType: ResponseType.bytes), // Use ResponseType.bytes for binary data
    );
    return response.data!;
  } catch (e) {
    throw Exception('Failed to download video: $e');
  }
}