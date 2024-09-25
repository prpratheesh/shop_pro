import 'dart:convert';

ErrorMsgDataModel configFromJson(String str) {
  final jsonData = json.decode(str);
  return ErrorMsgDataModel.fromMap(jsonData);
}

String configToJson(ErrorMsgDataModel data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class ErrorMsgDataModel {
  int? recNO;
  String page;
  String method;
  String errorMessage;
  String dateTime;

  ErrorMsgDataModel({
    this.recNO,
    required this.page,
    required this.method,
    required this.errorMessage,
    required this.dateTime
  });

  factory ErrorMsgDataModel.fromMap(Map<String, dynamic> json) => ErrorMsgDataModel(
      recNO: json["RecNo"],
      page: json["Page"],
      method: json["Method"],
      errorMessage: json["ErrorMessage"],
      dateTime: json["DateTime"]
  );

  Map<String, dynamic> toMap() => {
    "RecNo": recNO,
    "Page": page,
    "Method": method,
    "ErrorMessage":errorMessage,
    "DateTime": dateTime
  };

  ErrorMsgDataModel.fromMapObject(Map<String, dynamic> map)
    : recNO = map['RecNo'],
        page = map['Page'],
        method = map['Method'],
        errorMessage = map['ErrorMessage'],
        dateTime = map['DateTime'];
}