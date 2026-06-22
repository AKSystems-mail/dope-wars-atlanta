import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_state.dart';

class SaveService {
  static const String _fileName = 'dope_wars_save.json';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _file async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  /// Save game state locally
  static Future<void> saveGame(GameState state) async {
    try {
      final file = await _file;
      final json = jsonEncode(state.toJson());
      await file.writeAsString(json);
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  /// Load game state from local storage
  static Future<GameState?> loadGame() async {
    try {
      final file = await _file;
      if (!await file.exists()) return null;
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      return GameState.fromJson(data);
    } catch (e) {
      debugPrint('Load error: $e');
      return null;
    }
  }

  /// Check if a saved game exists
  static Future<bool> hasSaveData() async {
    try {
      final file = await _file;
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete saved game
  static Future<void> deleteSave() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Delete save error: $e');
    }
  }
}
