import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';

class AES {
  static const String key = "426494037028426494037028";
  static const String AES_IV = "PGKEYENCDECIVSPC";
  static const String HEX_DIGITS = "0123456789abcdef";

  static Uint8List createUint8ListFromHexString(String hex) {
    final buffer = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < buffer.length; i++) {
      buffer[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return buffer;
  }

  static String byteArrayToHexString(Uint8List data) {
    return hex.encode(data);
  }

  static String encryptAES(String encryptString) {
    try {
      final ivSpec = Uint8List.fromList(utf8.encode(AES_IV));
      final keySpec = Uint8List.fromList(utf8.encode(key));

      final cipher = PaddedBlockCipher("AES/CBC/PKCS7");
      final params = PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(keySpec), ivSpec), null);

      cipher.init(true, params); // true=encrypt

      final encrypted = cipher.process(
          Uint8List.fromList(utf8.encode(encryptString)));
      return byteArrayToHexString(encrypted).toUpperCase();
    } catch (e) {
      print("Error during encryption: $e");
      return '';
    }
  }

  static String decryptAES(String encryptedString) {
    try {
      final ivSpec = Uint8List.fromList(utf8.encode(AES_IV));
      final keySpec = Uint8List.fromList(utf8.encode(key));

      final cipher = PaddedBlockCipher("AES/CBC/PKCS7");
      final params = PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(keySpec), ivSpec), null);

      cipher.init(false, params); // false=decrypt

      final encryptedBytes = createUint8ListFromHexString(encryptedString);
      final decrypted = cipher.process(encryptedBytes);
      return utf8.decode(decrypted);
    } catch (e) {
      print("Error during decryption: $e");
      return '';
    }
  }
}