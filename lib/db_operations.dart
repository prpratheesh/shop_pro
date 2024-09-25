import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'logger.dart';
import 'model_api_config.dart';
import 'model_error_log.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }
  Future<int> _getOldDbVersion() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final oldPath = join(documentsDirectory.path, 'ShopPro.db');
    final oldDatabase = await openDatabase(oldPath);
    final oldVersion = await oldDatabase.getVersion();
    await oldDatabase.close();
    return oldVersion;
  }
  Future<Database> initDB({int? newVersion}) async {
    if(newVersion!=null);
    else{
      newVersion = await _getOldDbVersion();
    }
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "ShopPro.db");
    return await openDatabase(path, version: newVersion,
        onCreate: (Database db, int version) async {
          Logger.log('CREATING TABLES.', level: LogLevel.debug);
          await db.execute("CREATE TABLE ApiData ("
              "RecNO INTEGER PRIMARY KEY AUTOINCREMENT,"
              "ServerIP TEXT NOT NULL,"
              "PortNO TEXT NOT NULL,"
              "Currency TEXT NOT NULL,"
              "Voice TEXT NOT NULL,"
              "ClientID TEXT NOT NULL,"
              "ActCode TEXT NOT NULL,"
              "ImageScroll TEXT NOT NULL,"
              "VideoScroll TEXT NOT NULL,"
              "TextScroll TEXT NOT NULL,"
              "DateTime TEXT NOT NULL"
              ")");
          Logger.log('TABLE APIDATA CREATED.', level: LogLevel.debug);
          await db.execute("CREATE TABLE ErrorLog ("
              "RecNO INTEGER PRIMARY KEY AUTOINCREMENT,"
              "Page TEXT NOT NULL,"
              "Method TEXT NOT NULL,"
              "ErrorMessage TEXT NOT NULL,"
              "DateTime TEXT NOT NULL"
              ")");
          Logger.log('TABLE ERRORLOG CREATED.', level: LogLevel.debug);
        },onUpgrade: (db, oldDbVersion, newVersion) async {
          Logger.log('DB UPGRADE.', level: LogLevel.debug);
      await db.setVersion(newVersion);
    },onDowngrade: (db, oldDbVersion, newVersion) async {
          Logger.log('DB DOWNGRADE.', level: LogLevel.debug);
      await db.setVersion(oldDbVersion);
        }
        );
  }
  /////////////////////////////////////Config Operations///////////////////////////////////////
  Future<bool> insertApiData(ApiDataModel config) async {
    Logger.log('INSERT API DATA CALLED.', level: LogLevel.debug);
    final db = await database;
    if (db != null) {
      try {
        await db.delete("ApiData");
        await db.insert(
          "ApiData",
          config.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return true;
      } catch (e) {
        Logger.log('ERROR INSERTING DATA TO TABLE API DATA... ${e.toString().toUpperCase()}.', level: LogLevel.error);
        return false;
      }
    }else{
      Logger.log('DATABASE NOT INITIALIZED...', level: LogLevel.error);
      return false;
    }
  }
  Future<ApiDataModel?> getApiData() async {
    Logger.log('GET API DATA CALLED.', level: LogLevel.debug);
    final db = await database;
    try {
      final res = await db?.query("ApiData");
      Logger.log('$res', level: LogLevel.debug);
      return res!.isNotEmpty ? ApiDataModel.fromMap(res.first) : null;
    } catch (e) {
      Logger.log('ERROR GETTING DATA FROM TABLE API DATA. ${e.toString().toUpperCase()}.', level: LogLevel.error);
      return null;
    }
  }
  Future<bool> deleteApiData() async {
    Logger.log('DELETE API DATA CALLED.', level: LogLevel.debug);
    final db = await database;
    try {
      await db?.delete("ApiData");
      return true;
    } catch (e) {
      Logger.log('ERROR DELETING DATA FROM TABLE API DATA. ${e.toString().toUpperCase()}.', level: LogLevel.error);
      return false;
    }
  }
  /////////////////////////////////////Error Logging ////////////////////////////////////////
  Future<bool> insertErrorLog(ErrorMsgDataModel msg) async {
    Logger.log('INSERT API DATA CALLED.', level: LogLevel.debug);
    final db = await database;
    if (db != null) {
      try {
        await db.insert(
          "ErrorLog",
          msg.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return true;
      } catch (e) {
        Logger.log('ERROR INSERTING DATA TO TABLE ERROR LOG. ${e.toString().toUpperCase()}.', level: LogLevel.error);
        return false;
      }
    }else{
      Logger.log('DATABASE NOT INITIALIZED.', level: LogLevel.error);
      return false;
    }
  }
  Future<List<ErrorMsgDataModel>> getErrorLogs() async {
    Logger.log('GET ERROR LOG CALLED.', level: LogLevel.debug);
    final db = await database;
    try {
      final res = await db?.query("ErrorLog");
      return res?.map((e) => ErrorMsgDataModel.fromMap(e)).toList() ?? [];
    } catch (e) {
      Logger.log('ERROR GETTING DATA FROM TABLE ERROR LOGS. ${e.toString().toUpperCase()}.', level: LogLevel.error);
      return [];
    }
  }
  Future<bool> deleteErrorLog(int id) async {
    Logger.log('DELETE ERROR LOG CALLED.', level: LogLevel.debug);
    final db = await database;
    try {
      await db?.delete("ErrorLog", where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      Logger.log('ERROR DELETING DATA FROM TABLE ERROR LOGS. ${e.toString().toUpperCase()}.', level: LogLevel.error);
      return false;
    }
  }
}