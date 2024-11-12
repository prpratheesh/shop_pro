import 'dart:typed_data';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:flutter/material.dart';
import 'package:shop_pro/model_barcode.dart';
import 'font_sizes.dart';

class TemporaryOverlay extends StatelessWidget {
  final BarcodeData? message; // Optional BarcodeData
  final String? errorMessage; // Optional error message
  final Duration duration;
  final bool showLogo; // New parameter to control logo visibility
  final Uint8List? logoData;
  final String currencySymbol;

  TemporaryOverlay({
    this.message, // Nullable to allow for an error message
    this.errorMessage, // Allow passing a string message
    this.showLogo = false, // Default is false if not provided
    this.logoData,
    this.currencySymbol = 'AED', // Default currency symbol if not provided
    Duration? duration,
  }) : duration = duration ?? const Duration(seconds: 5);

  @override
  Widget build(BuildContext context) {
    final fontSizes = FontSizes.fromContext(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final width = screenWidth * 0.999;
    final height = screenHeight * 0.999;

    return Positioned(
      top: (screenHeight - height) / 2, // Center vertically
      left: (screenWidth - width) / 2, // Center horizontally
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Conditionally show the logo based on the showLogo parameter
              if (showLogo && logoData != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Image.memory(
                    logoData!,
                    height: screenHeight/5, // Adjust as needed
                    width: screenWidth/5, // Adjust as needed
                    fit: BoxFit.contain,
                  ),
                ),
              if (message != null) ...[
                Text(
                  message!.barcode,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSizes.largerFontSize8,
                    color: Colors.red,
                  ),
                ), // BARCODE
                Text(
                  message!.description,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSizes.largerFontSize5,
                    color: Colors.blue,
                  ),
                ), // NAME ENGLISH
                if (message!.arabic != null && message!.arabic!.trim().isNotEmpty)
                Text(
                  message!.arabic,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSizes.largerFontSize7,
                    color: Colors.blue,
                  ),
                ), // NAME ARABIC
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$currencySymbol ', // Add currency symbol
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: fontSizes.largerFontSize9,
                        ),
                      ),
                      TextSpan(
                        text: currencySymbol == 'OMR'
                            ? message!.retail.toStringAsFixed(3) // 3 decimal places for OMR
                            : message!.retail.toStringAsFixed(2), // 2 decimal places for AED or others
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSizes.largerFontSize10,
                        ), // Set the color and style for retail price
                      ),
                      TextSpan(
                        text: ' /-',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: fontSizes.largerFontSize8,
                        ), // Set the color and font size for "/-"
                      ),
                    ],
                  ),
                ),
                // RETAIL CURRENCY, PRICE AND SEPARATOR
                Center(
                  child: Container(
                    height: height/8,
                width: width/4,
                child:
                SfBarcodeGenerator(
                  value: message?.barcode,
                  symbology: Code128(),
                  showValue: true,
                ),
                  ),
                ),
              ] else if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSizes.largerFontSize8,
                    color: Colors.red, // Set error message color
                  ),
                ), // ERROR MESSAGE
              ],
            ],
          ),
        ),
      ),
    );
  }
}
