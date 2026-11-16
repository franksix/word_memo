import 'dart:convert';
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

  // 云端词库相关（改为 Map 存储：{"bookId": "url"}）
  static const _keyCloudBookMap = 'cloud_book_map';

  // ===== 推荐词书相关 =====
  static const _keyHasEverAddedBook = 'has_ever_added_book';
  static const _keyFirstOpenTime = 'first_open_time';
  static const _keyRecommendedClosed = 'recommended_closed';

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

  // ===== 云端词库 Map 存储 =====
  Future<Map<String, String>> getCloudBookMap() async {
    final p = await _p;
    final str = p.getString(_keyCloudBookMap);
    if (str == null || str.isEmpty) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(str);
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<String?> getCloudUrlByBookId(String bookId) async {
    final map = await getCloudBookMap();
    return map[bookId];
  }

  Future<void> setCloudUrlByBookId(String bookId, String url) async {
    final p = await _p;
    final map = await getCloudBookMap();
    map[bookId] = url;
    await p.setString(_keyCloudBookMap, jsonEncode(map));
  }

  Future<void> removeCloudUrlByBookId(String bookId) async {
    final p = await _p;
    final map = await getCloudBookMap();
    map.remove(bookId);
    await p.setString(_keyCloudBookMap, jsonEncode(map));
  }

  // ===== 推荐词书展示控制 =====

  /// 记录用户是否曾经成功添加过词书（意味着不再是纯新手）
  Future<bool> getHasEverAddedBook() async {
    final p = await _p;
    return p.getBool(_keyHasEverAddedBook) ?? false;
  }

  Future<void> setHasEverAddedBook() async {
    final p = await _p;
    await p.setBool(_keyHasEverAddedBook, true);
  }

  /// 记录用户首次打开 App 的时间（用于计算是否已使用超过 7 天）
  Future<DateTime> getFirstOpenTime() async {
    final p = await _p;
    final ms = p.getInt(_keyFirstOpenTime);
    if (ms == null) {
      // 如果没记录过，说明是首次打开，立刻记录当前时间
      final now = DateTime.now();
      await p.setInt(_keyFirstOpenTime, now.millisecondsSinceEpoch);
      return now;
    }
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 用户是否在空状态下手动关闭了“为你推荐”列表
  Future<bool> getRecommendedClosed() async {
    final p = await _p;
    return p.getBool(_keyRecommendedClosed) ?? false;
  }

  Future<void> setRecommendedClosed() async {
    final p = await _p;
    await p.setBool(_keyRecommendedClosed, true);
  }
}