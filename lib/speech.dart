import 'package:flutter_tts/flutter_tts.dart';

import 'package:flutter_tts/flutter_tts.dart';

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
    voices.forEach((voice) {
      print(voice);
    });
  }

  // Function to set the voice
  Future<void> setVoice(String language) async {
    await flutterTts.setLanguage(language);
  }

  // Function to set the speech rate
  Future<void> setSpeechRate(double rate) async {
    await flutterTts.setSpeechRate(rate);
  }

  // Function to speak the price
  Future<void> speakPrice(double retailPrice) async {
    String formattedPrice = formatPrice(retailPrice);
    await flutterTts.speak(formattedPrice);
  }

  // Function to speak a custom message
  Future<void> speakMessage(String message) async {
    await flutterTts.speak(message);
  }

  // Helper to format the price into words
  String formatPrice(double price) {
    int dirham = price.floor();
    int fills = ((price - dirham) * 100).round();

    if (fills > 0) {
      return '$dirham Dr-ham ${fills} Fills';
    } else {
      return '$dirham Dr-ham';
    }
  }
}

