import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _keyCurrentWordBook = 'current_word_book_id';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _p async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  Future<String?> getCurrentWordBookId() async {
    final p = await _p;
    return p.getString(_keyCurrentWordBook);
  }

  Future<void> setCurrentWordBookId(String id) async {
    final p = await _p;
    await p.setString(_keyCurrentWordBook, id);
  }

  Future<void> clearCurrentWordBookId() async {
    final p = await _p;
    await p.remove(_keyCurrentWordBook);
  }
}