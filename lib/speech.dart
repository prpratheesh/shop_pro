import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'logger.dart';

class PriceSpeaker {
  final FlutterTts flutterTts;

  PriceSpeaker() : flutterTts = FlutterTts() {
    flutterTts.getEngines.then((engines) {
      if (engines.isNotEmpty) {
        Logger.log('TTS ENGINE IS AVAILABLE.', level: LogLevel.info);
      } else {
        Logger.log('NO TTS ENGINE FOUND.', level: LogLevel.error);
      }
    });
    // Set initial voice and speed
    setVoice("en-US"); // Example for US English
    setSpeechRate(0.5); // Set to 50% speed (0.0 to 1.0 scale)
    // listAvailableLanguages();
    // listAvailableVoices();
  }

  // Function to list available voices
  Future<void> listAvailableVoices() async {
    List<dynamic> voices = await flutterTts.getVoices;
    Logger.log('AVAILABLE VOICE PATTERNS->${voices.toString()}', level: LogLevel.info);
  }

  Future<void> listAvailableLanguages() async {
    List<dynamic> languages = await flutterTts.getLanguages;
    Logger.log('AVAILABLE LANGUAGES->${languages.toString()}', level: LogLevel.error);
  }

  Future<String> getAvailableVoices() async {
    List<dynamic> voices = await flutterTts.getVoices;
    String voiceList = voices.join(', '); // Join voices with a comma and space
    return voiceList; // Return the list of voices as a string
  }

  // Function to set the voice
  Future<void> setVoice(String language) async {
    await flutterTts.setLanguage(language);
    // await flutterTts.setVoice({"name": "en-us-x-sfg-network", "locale": "en-US"});
    // await flutterTts.setVoice({"name": "kn-in-x-knd-network", "locale": "kn-IN"});
  }

  // Function to set the voice
  Future<void> setLanguage(String language) async {
    var isLanguageAvailable = await flutterTts.isLanguageAvailable(language);
    Logger.log('LANGUAGE IS SET.', level: LogLevel.info);
    try {
      await flutterTts.setLanguage(language);
      Logger.log('LANGUAGE IS SET.', level: LogLevel.info);
    } catch (e) {
      Logger.log('ERROR SETTING LANGUAGE.', level: LogLevel.error);
    }
  }

  // Function to set pitch
  Future<void> setPitch(double pitch) async {
    await flutterTts.setPitch(pitch);
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
  // Future<void> speakMessage(String message) async {
  //   flutterTts.getLanguages.then((languages) {
  //     Logger.log('LANGUAGES -> $languages', level: LogLevel.info);
  //   });
  //   flutterTts.getVoices.then((voices) {
  //     Logger.log('VOICES -> $voices', level: LogLevel.info);
  //   });
  //   try {
  //     await flutterTts.speak(message);
  //     Logger.log('SPEAK SUCCESS.', level: LogLevel.error);
  //   }catch(e){
  //     Logger.log('ERROR IN SPEAK ENGINE. $e', level: LogLevel.error);
  //   }
  // }
  Future<void> speakMessage(String message) async {
    // flutterTts.getLanguages.then((languages) {
    //   Logger.log('LANGUAGES -> $languages', level: LogLevel.info);
    // });

    flutterTts.getVoices.then((voices) async {
      // Logger.log('VOICES -> $voices', level: LogLevel.debug);

      // Optionally, set a specific voice or language
      if (voices.isNotEmpty) {
        try {
          Logger.log('NO VOICE IS SET DEFAULT. SETTING ONE NOW.',
              level: LogLevel.critical);
          await flutterTts.setVoice({"name": "en-US-language", "locale": "en-US"});
        }
        catch(e){
          Logger.log('ERROR SETTING VOICE. $e',
              level: LogLevel.error);
        }
      }
    });

    try {
      await flutterTts.speak(message);
      Logger.log('SPEAK SUCCESS.', level: LogLevel.info);  // Correct log level for success
    } catch (e) {
      Logger.log('ERROR IN SPEAK ENGINE. $e', level: LogLevel.error);
    }
  }

  Future<void> setVolume(double volume) async {
    await flutterTts.setVolume(volume);
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

