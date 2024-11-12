import 'package:flutter_tts/flutter_tts.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'logger.dart';

class PriceSpeaker {
  final FlutterTts flutterTts;

  PriceSpeaker() : flutterTts = FlutterTts() {
    // Set initial voice and speed
    setVoice("en-US"); // Example for US English
    setSpeechRate(0.5); // Set to 50% speed (0.0 to 1.0 scale)
    listAvailableVoices();
  }

  // Function to list available voices
  Future<void> listAvailableVoices() async {
    List<dynamic> voices = await flutterTts.getVoices;
    // Logger.log('AVAILABLE VOICE PATTERNS->${voices.toString()}', level: LogLevel.info);
  }

  Future<String> getAvailableVoices() async {
    List<dynamic> voices = await flutterTts.getVoices;
    String voiceList = voices.join(', '); // Join voices with a comma and space
    return voiceList; // Return the list of voices as a string
  }

  // Function to set the voice
  Future<void> setVoice(String language) async {
    await flutterTts.setLanguage(language);
  }

  // Function to set the speech rate
  Future<void> setSpeechRate(double rate) async {
    await flutterTts.setSpeechRate(rate);
  }

  // Function to speak the price AED
  Future<void> speakPriceAED(double retailPrice) async {
    String formattedPrice = formatPriceAED(retailPrice);
    await flutterTts.speak(formattedPrice);
    // await flutterTts.speak(formattedPrice.replaceAll('.', '')); // Ensure no dots are included
  }

  // Function to speak the price OMR
  Future<void> speakPriceOMR(double retailPrice) async {
    String formattedPrice = formatPriceOMR(retailPrice);
    await flutterTts.speak(formattedPrice);
    // await flutterTts.speak(formattedPrice.replaceAll('.', '')); // Ensure no dots are included
  }

  // Function to speak the price
  Future<void> speakPriceText(double retailPrice) async {
    String formattedPrice = formatPriceToText(retailPrice); // Get the formatted price in words
    await flutterTts.speak(formattedPrice); // Speak the formatted price
  }

  // Function to speak a custom message
  Future<void> speakMessage(String message) async {
    await flutterTts.speak(message);
  }

  // Helper to format the price into words
  // String formatPrice(double price) {
  //   int dirham = price.floor();
  //   int fills = ((price - dirham) * 100).round();
  //
  //   if (fills > 0) {
  //     return '$dirham Dr-ham ${fills} Fills';
  //   } else {
  //     return '$dirham Dr-ham';
  //   }
  // }
  // String formatPrice(double price) {
  //   int dirham = price.floor();
  //   int fills = ((price - dirham) * 100).round();
  //
  //   // Create the formatted string
  //   String formattedPrice = '$dirham Dr-ham';
  //   if (fills > 0) {
  //     formattedPrice += ' $fills Fills'; // Use space instead of dot
  //   }
  //
  //   return formattedPrice;
  // }
  String formatPriceAED(double price) {
    int dirham = price.floor(); // Extract the Dirham part (whole number)
    int fills = ((price - dirham) * 100).round(); // Extract the exact Fils part without rounding

    // Create the formatted string
    String formattedPrice = '$dirham Dr-ham'; // Ensure no dots are included
    if (fills > 0) {
      formattedPrice += ' $fills Fills'; // Add fills only if present
    }
    Logger.log('FORMATTED PRICE : $formattedPrice', level: LogLevel.info);
    return formattedPrice;
  }

  String formatPriceOMR(double price) {
    int riyal = price.floor(); // Extract the Riyal part (whole number)
    int baisa = ((price - riyal) * 1000).round(); // Extract the exact Baisa part without rounding

    // Create the formatted string
    String formattedPrice = '$riyal Ree-yal'; // Ensure no dots are included
    if (baisa > 0) {
      formattedPrice += ' $baisa Baisa'; // Add baisa only if present
    }
    Logger.log('FORMATTED PRICE : $formattedPrice', level: LogLevel.info);
    return formattedPrice;
  }

  String formatPriceToText(double price) {
    int dirham = price.floor(); // Extract the Dirham part (whole number)
    int fills = ((price - dirham) * 100).round(); // Extract the exact Fils part without rounding

    // Convert numbers to words
    String dirhamText = convertNumberToWords(dirham);
    String fillsText = fills > 0 ? ' ${convertNumberToWords(fills)} Fills' : '';

    // Create the formatted string
    String formattedPrice = '$dirhamText Dirham$fillsText'; // Construct the message
    Logger.log('FORMATTED PRICE : $formattedPrice', level: LogLevel.info);
    return formattedPrice;
  }

// Helper function to convert numbers to words
  String convertNumberToWords(int number) {
    if (number == 0) return "Zero";
    const List<String> units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];

    const List<String> tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (number < 20) {
      return units[number];
    } else if (number < 100) {
      return tens[number ~/ 10] + (number % 10 != 0 ? ' ${units[number % 10]}' : '');
    } else if (number < 1000) {
      return '${units[number ~/ 100]} Hundred${number % 100 != 0 ? ' ${convertNumberToWords(number % 100)}' : ''}';
    } else if (number < 1000000) { // Handle thousands
      return '${convertNumberToWords(number ~/ 1000)} Thousand${number % 1000 != 0 ? ' ${convertNumberToWords(number % 1000)}' : ''}';
    } else if (number < 1000000000) { // Handle millions
      return '${convertNumberToWords(number ~/ 1000000)} Million${number % 1000000 != 0 ? ' ${convertNumberToWords(number % 1000000)}' : ''}';
    }

    return number.toString(); // For larger numbers, fallback to string representation
  }

}

