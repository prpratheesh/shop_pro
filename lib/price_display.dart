import 'package:flutter/material.dart';
import 'package:shop_pro/model_barcode.dart';
import 'font_sizes.dart';

class TemporaryOverlay extends StatelessWidget {
  final BarcodeData? message; // Optional BarcodeData
  final String? errorMessage; // Optional error message
  final Duration duration;

  TemporaryOverlay({
    this.message, // Make it nullable to allow for an error message
    this.errorMessage, // Allow passing a string message
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
                        text: 'AED: ',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: fontSizes.largerFontSize9,
                        ),
                      ),
                      TextSpan(
                        text: message!.retail.toStringAsFixed(2),
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
                ), // RETAIL CURRENCY, PRICE AND SEPARATOR
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
