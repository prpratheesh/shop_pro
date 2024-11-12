import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> writeData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      Logger.log('DATA WRITTEN TO SECURE STORAGE...', level: LogLevel.info);
      return true;
    } catch (e) {
      Logger.log('ERROR WRITING TO SECURE STORAGE... ${e.toString().toUpperCase()}', level: LogLevel.critical);
      return false;
    }
  }

// Read data from secure storage
  Future<String?> readData(String key) async {
    try {
      Logger.log('DATA READ FROM SECURE STORAGE...', level: LogLevel.info);
      String? value = await _secureStorage.read(key: key);
      if (value == null) {
        Logger.log('NO DATA FOUND FOR KEY: $key', level: LogLevel.warning);
      }
      return value;
    } catch (e) {
      Logger.log('ERROR READING DATA FROM SECURE STORAGE... ${e.toString().toUpperCase()}', level: LogLevel.critical);
      return null;
    }
  }

// Delete specific data from secure storage
  Future<void> deleteData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      // Optionally check if the data was successfully deleted
      String? deletedValue = await _secureStorage.read(key: key);
      if (deletedValue == null) {
        Logger.log('DATA SUCCESSFULLY DELETED FROM SECURE STORAGE...', level: LogLevel.info);
      } else {
        Logger.log('FAILED TO DELETE DATA FROM SECURE STORAGE... KEY: $key', level: LogLevel.warning);
      }
    } catch (e) {
      Logger.log('ERROR DELETING DATA FROM SECURE STORAGE... ${e.toString().toUpperCase()}', level: LogLevel.critical);
    }
  }

// Delete all data from secure storage
  Future<void> deleteAllData() async {
    try {
      await _secureStorage.deleteAll();
      // Optionally check if all data was successfully deleted
      Map<String, String> allKeys = await _secureStorage.readAll();
      if (allKeys.isEmpty) {
        Logger.log('ALL DATA SUCCESSFULLY DELETED FROM SECURE STORAGE...', level: LogLevel.info);
      } else {
        Logger.log('FAILED TO DELETE ALL DATA FROM SECURE STORAGE... REMAINING KEYS: ${allKeys.keys}', level: LogLevel.warning);
      }
    } catch (e) {
      Logger.log('ERROR DELETING ALL DATA FROM SECURE STORAGE... ${e.toString().toUpperCase()}', level: LogLevel.critical);
    }
  }
}
