import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  // 词书相关
  static const _keyCurrentWordBook = 'current_word_book_id';

  // 主题相关
  static const _keyThemeMode = 'theme_mode';
  static const _keyThemeStyle = 'theme_style';

  // 通知相关
  static const _keyNotificationEnabled = 'notification_enabled';
  static const _keyNotificationHour = 'notification_hour';
  static const _keyNotificationMinute = 'notification_minute';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _p async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ===== 词书 =====
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

  // ===== 主题模式 =====
  Future<String> getThemeMode() async {
    final p = await _p;
    return p.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final p = await _p;
    await p.setString(_keyThemeMode, mode);
  }

  // ===== 主题配色 =====
  Future<String> getThemeStyle() async {
    final p = await _p;
    return p.getString(_keyThemeStyle) ?? 'monet';
  }

  Future<void> setThemeStyle(String style) async {
    final p = await _p;
    await p.setString(_keyThemeStyle, style);
  }

  // ===== 通知提醒 =====
  Future<bool> getNotificationEnabled() async {
    final p = await _p;
    return p.getBool(_keyNotificationEnabled) ?? false;
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    final p = await _p;
    await p.setBool(_keyNotificationEnabled, enabled);
  }

  Future<int> getNotificationHour() async {
    final p = await _p;
    return p.getInt(_keyNotificationHour) ?? 20;
  }

  Future<void> setNotificationHour(int hour) async {
    final p = await _p;
    await p.setInt(_keyNotificationHour, hour);
  }

  Future<int> getNotificationMinute() async {
    final p = await _p;
    return p.getInt(_keyNotificationMinute) ?? 0;
  }

  Future<void> setNotificationMinute(int minute) async {
    final p = await _p;
    await p.setInt(_keyNotificationMinute, minute);
  }
}