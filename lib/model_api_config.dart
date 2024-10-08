import 'dart:convert';

ApiDataModel configFromJson(String str) {
  final jsonData = json.decode(str);
  return ApiDataModel.fromMap(jsonData);
}

String configToJson(ApiDataModel data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class ApiDataModel {
  int? recNo;
  String serverIP;
  String portNo;
  String currency;
  String voice;
  String clientID;
  String actCode;
  String actKey;
  String actAllow;
  String actStatus;
  String logoEnable;
  String bannerEnable;
  String imageScroll;
  String priceDisplay;
  String imageDisplay;
  String videoScroll;
  String textScroll;
  String dateTime;

  ApiDataModel({
    this.recNo,
    required this.serverIP,
    required this.portNo,
    required this.currency,
    required this.voice,
    required this.clientID,
    required this.actCode,
    required this.actKey,
    required this.actAllow,
    required this.actStatus,
    required this.logoEnable,
    required this.bannerEnable,
    required this.imageScroll,
    required this.priceDisplay,
    required this.imageDisplay,
    required this.videoScroll,
    required this.textScroll,
    required this.dateTime,
  });

  /// Convert a Map (from database) to an ApiDataModel object
  factory ApiDataModel.fromMap(Map<String, dynamic> json) => ApiDataModel(
    recNo: json['RecNO'] as int?,
    serverIP: json['ServerIP'] as String,
    portNo: json['PortNO'] as String,
    currency: json['Currency'] as String,
    voice: json['Voice'] as String,
    clientID: json['ClientID'] as String,
    actCode: json['ActCode'] as String,
    actKey: json['ActKey'] as String,
    actAllow: json['ActAllow'] as String,
    actStatus: json['ActStatus'] as String,
    logoEnable: json['LogoEnable'] as String,
    bannerEnable: json['BannerEnable'] as String,
    imageScroll: json['ImageScroll'] as String,
    priceDisplay: json['PriceDisplay'] as String,
    imageDisplay: json['ImageDisplay'] as String,
    videoScroll: json['VideoScroll'] as String,
    textScroll: json['TextScroll'] as String,
    dateTime: json['DateTime'] as String,
  );

  /// Convert an ApiDataModel object to a Map (for database)
  Map<String, dynamic> toMap() => {
    if (recNo != null) 'RecNO': recNo!,
    'ServerIP': serverIP,
    'PortNO': portNo,
    'Currency': currency,
    'Voice': voice,
    'ClientID': clientID,
    'ActCode': actCode,
    'ActKey': actKey,
    'ActAllow': actAllow,
    'ActStatus': actStatus,
    'LogoEnable': logoEnable,
    'BannerEnable': bannerEnable,
    'ImageScroll': imageScroll,
    'PriceDisplay': priceDisplay,
    'ImageDisplay': imageDisplay,
    'VideoScroll': videoScroll,
    'TextScroll': textScroll,
    'DateTime': dateTime,
  };
  @override
  String toString() {
    return 'ApiDataModel(recNo: $recNo, serverIP: $serverIP, portNo: $portNo, currency: $currency, voice: $voice, clientID: $clientID, actCode: $actCode, actKey: $actKey, actAllow: $actAllow, actStatus: $actStatus, logoEnable: $logoEnable, bannerEnable: $bannerEnable, imageScroll: $imageScroll, PriceDisplay: $priceDisplay, ImageDisplay: $imageDisplay,videoScroll: $videoScroll, textScroll: $textScroll, dateTime: $dateTime)';
  }
}
