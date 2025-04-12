import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'logger.dart';

class PriceSpeaker {
  final FlutterTts flutterTts;

  PriceSpeaker() : flutterTts = FlutterTts() {
    flutterTts.getEngines.then((engines) {
      Logger.log('AVAILABLE ENGINES : $engines', level: LogLevel.info);
      if (engines.isNotEmpty) {
        Logger.log('TTS ENGINE IS AVAILABLE.', level: LogLevel.info);
      } else {
        Logger.log('NO TTS ENGINE FOUND.', level: LogLevel.error);
      }
    });
    // Set initial voice and speed
    // setVoice("en-US"); // Example for US English
    // setSpeechRate(0.5); // Set to 50% speed (0.0 to 1.0 scale)
    flutterTts.setLanguage("en-GB");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setVoice({"name": "en-gb-x-gba-local", "locale": "en-GB"});
    // speakTestMessage('Welcome');
    // listAvailableLanguages();
    // listAvailableVoices();
  }

  Future<void> speakSampleMessage(String message) async {
    String languageCode = "en-GB";
    List<dynamic> voices = await flutterTts.getVoices;
    var selectedVoice = voices.firstWhere(
          (voice) => voice["locale"] == languageCode,
      orElse: () => null,
    );
    Map<String, String> voiceMap = Map<String, String>.from(selectedVoice);

    try {
      // Set default language and voice
      await flutterTts.setLanguage(languageCode);
      await flutterTts.setVoice(voiceMap);
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);

      // Speak the message
      await flutterTts.speak(message);
      Logger.log('SPEAK SUCCESS.', level: LogLevel.info);
    } catch (e) {
      Logger.log('ERROR IN SPEAK ENGINE. $e', level: LogLevel.error);
    }
  }

  Future<void> setAndSpeak(String text, String languageCode) async {
    List<dynamic> voices = await flutterTts.getVoices;

    // Find the voice based on the locale
    var selectedVoice = voices.firstWhere(
          (voice) => voice["locale"] == languageCode,
      orElse: () => null,
    );

    if (selectedVoice != null) {
      // Explicitly cast to Map<String, String>
      Map<String, String> voiceMap = Map<String, String>.from(selectedVoice);
      Logger.log('-------------------------------------------------------------');
      Logger.log(voiceMap.toString());
      Logger.log(languageCode);
      Logger.log(text);
      Logger.log('-------------------------------------------------------------');

      // Set the voice using the casted map
      await flutterTts.setVoice(voiceMap);
      await flutterTts.setLanguage(languageCode);
      await flutterTts.speak(text);
    } else {
      Logger.log("Voice not found for $languageCode",level: LogLevel.error);
    }
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
    try {
      List<dynamic> voices = await flutterTts.getVoices;

      if (voices.isNotEmpty) {
        // Find the voice with locale 'en-US'
        var selectedVoice = voices.firstWhere(
              (voice) {
            if (voice is Map<String, String>) {
              return voice['locale'] == 'en-US'; // Check for 'en-US' locale
            }
            return false;
          },
          orElse: () => voices.first, // Fallback to the first voice if none is found
        );

        if (selectedVoice is Map<String, String>) {
          await flutterTts.setVoice(selectedVoice); // Set the selected voice map
          Logger.log('Voice set to: ${selectedVoice["name"]}', level: LogLevel.info);
        } else {
          Logger.log('Voice not found. Using default voice.', level: LogLevel.warning);
        }
      } else {
        Logger.log('No voices available. Using default voice.', level: LogLevel.error);
      }

      await flutterTts.speak(message);
      Logger.log('SPEAK SUCCESS.', level: LogLevel.info);
    } catch (e) {
      Logger.log('ERROR IN SPEAK ENGINE. $e', level: LogLevel.error);
    }
  }

  Future<void> speakTestMessage(String message) async {
    try {
      // Set default language and voice
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);

      // Speak the message
      await flutterTts.speak(message);
      Logger.log('SPEAK SUCCESS.', level: LogLevel.info);
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

