import 'package:intl/intl.dart';

class BarcodeData {
  final String barcode;
  final String description;
  final String arabic;
  final double retail;
  final int spFlag;
  final double spPrice;
  final DateTime spStart;
  final DateTime spEnd;

  BarcodeData({
    required this.barcode,
    required this.description,
    required this.arabic,
    required this.retail,
    required this.spFlag,
    required this.spPrice,
    required this.spStart,
    required this.spEnd,
  });

  // Factory method to create a BarcodeData object from JSON
  factory BarcodeData.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is String) {
        return int.tryParse(value) ?? 0;
      } else {
        return 0;
      }
    }

    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else {
        return 0.0;
      }
    }

    try {
      return BarcodeData(
        barcode: json['BARCODE'] ?? '',
        description: json['DESCRIPTION'] ?? '',
        arabic: json['ARABIC'] ?? '',
        retail: parseDouble(json['RETAIL']),
        spFlag: parseInt(json['SP_FLAG']),
        spPrice: parseDouble(json['SP_PRICE']),
        spStart: DateFormat('dd-MM-yyyy').parse(json['SP_START'] ?? '01-01-1900'),
        spEnd: DateFormat('dd-MM-yyyy').parse(json['SP_END'] ?? '31-12-2099'),
      );
    } catch (e) {
      // Handle any parsing errors here
      print('Error parsing BarcodeData: $e');
      rethrow; // Optionally rethrow to be caught by caller
    }
  }

  // Convert BarcodeData object to JSON
  Map<String, dynamic> toJson() {
    return {
      'BARCODE': barcode,
      'DESCRIPTION': description,
      'ARABIC': arabic,
      'RETAIL': retail,
      'SP_FLAG': spFlag,
      'SP_PRICE': spPrice,
      'SP_START': DateFormat('dd-MM-yyyy').format(spStart),
      'SP_END': DateFormat('dd-MM-yyyy').format(spEnd),
    };
  }
}
