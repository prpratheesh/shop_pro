import 'package:flutter/material.dart';

class FontSizes {
  final double smallerFontSize5;   // 5th font size smaller than baseFontSize
  final double smallerFontSize4;   // 4th font size smaller than baseFontSize
  final double smallerFontSize3;   // 3rd font size smaller than baseFontSize
  final double smallerFontSize2;   // 2nd font size smaller than baseFontSize
  final double smallerFontSize1;   // 1st font size smaller than baseFontSize

  final double baseFontSize;       // Base font size (bodyFontSize)

  final double largerFontSize1;    // 1st font size larger than baseFontSize
  final double largerFontSize2;    // 2nd font size larger than baseFontSize
  final double largerFontSize3;    // 3rd font size larger than baseFontSize
  final double largerFontSize4;    // 4th font size larger than baseFontSize
  final double largerFontSize5;    // 5th font size larger than baseFontSize
  final double largerFontSize6;    // 6th font size larger than baseFontSize
  final double largerFontSize7;    // 7th font size larger than baseFontSize
  final double largerFontSize8;    // 8th font size larger than baseFontSize
  final double largerFontSize9;    // 9th font size larger than baseFontSize
  final double largerFontSize10;    // 10th font size larger than baseFontSize

  FontSizes({
    required this.smallerFontSize5,
    required this.smallerFontSize4,
    required this.smallerFontSize3,
    required this.smallerFontSize2,
    required this.smallerFontSize1,
    required this.baseFontSize,
    required this.largerFontSize1,
    required this.largerFontSize2,
    required this.largerFontSize3,
    required this.largerFontSize4,
    required this.largerFontSize5,
    required this.largerFontSize6,
    required this.largerFontSize7,
    required this.largerFontSize8,
    required this.largerFontSize9,
    required this.largerFontSize10,
  });

  // Factory method to create FontSizes based on BuildContext
  factory FontSizes.fromContext(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate base font size based on screen width
    final double baseFontSize = screenWidth * 0.016;  // Base font size (body text size)

    // Calculate the smaller and larger font sizes
    return FontSizes(
      baseFontSize: baseFontSize,
      smallerFontSize1: baseFontSize * 0.9,   // 1st font size smaller
      smallerFontSize2: baseFontSize * 0.8,   // 2nd font size smaller
      smallerFontSize3: baseFontSize * 0.7,   // 3rd font size smaller
      smallerFontSize4: baseFontSize * 0.6,   // 4th font size smaller
      smallerFontSize5: baseFontSize * 0.5,   // 5th font size smaller
      largerFontSize1: baseFontSize * 1.1,    // 1st font size larger
      largerFontSize2: baseFontSize * 1.2,    // 2nd font size larger
      largerFontSize3: baseFontSize * 1.3,    // 3rd font size larger
      largerFontSize4: baseFontSize * 1.4,    // 4th font size larger
      largerFontSize5: baseFontSize * 2.0,    // 5th font size larger
      largerFontSize6: baseFontSize * 2.2,    // 5th font size larger
      largerFontSize7: baseFontSize * 2.4,    // 5th font size larger
      largerFontSize8: baseFontSize * 2.6,    // 5th font size larger
      largerFontSize9: baseFontSize * 2.8,    // 5th font size larger
      largerFontSize10: baseFontSize * 3.0,    // 5th font size larger
    );
  }
}
