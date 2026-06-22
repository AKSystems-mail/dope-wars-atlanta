import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/game_state.dart';

class SaveService {
  static const String _fileName = 'dope_wars_save.json';

  Future<File> get _saveFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> save(GameState state) async {
    try {
      final file = await _saveFile;
      final json = jsonEncode(state.toJson());
      await file.writeAsString(json);
    } catch (e) {
      debugPrint('Save failed: $e');
    }
  }

  Future<GameState?> load() async {
    try {
      final file = await _saveFile;
      if (!await file.exists()) return null;
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      return GameState.fromJson(data);
    } catch (e) {
      debugPrint('Load failed: $e');
      return null;
    }
  }

  Future<bool> hasSave() async {
    final file = await _saveFile;
    return await file.exists();
  }

  Future<void> delete() async {
    final file = await _saveFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}

// Flutter debugPrint shim for save_service
void debugPrint(String message) {
  // Uses Flutter's built-in debugPrint when available
}
