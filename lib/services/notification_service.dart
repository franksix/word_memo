import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // 使用 100 到 106 这 7 个 ID 来轮转未来一周的通知
  static const int _baseId = 100;
  static const String _channelId = 'daily_reminder_channel';
  static const String _channelName = '每日单词提醒';

  // 文艺治愈系文案池
  static const List<String> _messages = [
    '今天的光线刚刚好，适合和几个单词打个照面。',
    '留 5 分钟给单词，把今天的浮躁沉淀下来。',
    '睡莲池边，单词们在安静地晒太阳，偶尔也来看看它们吧。',
    '慢慢来，比较快。今天也随便看几个词吧。',
    '微风吹过，不如顺手翻开那本属于你的词书。',
    '不用着急，每天记住一点点就好。',
    '泡一杯茶，花几分钟和单词独处一会儿。',
    '词句在时间里慢慢发酵，今天也来看看它们吧。',
    '给忙碌的生活按个暂停键，和单词说声嗨。',
    '不慌不忙，把今天的几个单词收进脑袋里。',
  ];

  /// 初始化插件与时区
  Future<void> init() async {
    // 1. 初始化时区数据
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(currentTimeZone);
      tz.setLocalLocation(location);
    } catch (_) {
      // 如果获取失败，使用默认本地时间
    }

    // 2. 初始化 Android 通知设置
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 用户点击通知后的回调（可用来跳转到练习页等，暂留空）
      },
    );
  }

  /// 请求通知权限 (Android 13+)
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final bool? granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// 设置未来 7 天的随机文案提醒
  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      // 1. 先清除旧的排程
      await cancelDailyReminder();

      final now = tz.TZDateTime.now(tz.local);
      final random = Random();

      // 2. 循环安排未来 7 天
      for (int i = 0; i < 7; i++) {
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + i,
          hour,
          minute,
        );

        // 如果是今天，且时间已经过了，就跳过今天
        if (scheduledDate.isBefore(now)) {
          continue;
        }

        // 从文案池中随机抽取一句
        final message = _messages[random.nextInt(_messages.length)];

        const androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: '每天固定时间温柔提醒',
          importance: Importance.max,
          priority: Priority.high,
        );

        await _plugin.zonedSchedule(
          _baseId + i, // 每天用不同的 ID
          '记单词', // 标题极简
          message, // 文艺文案
          scheduledDate,
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          // 去掉了 matchDateTimeComponents，因为每天文案不同，不能用系统自动循环
        );
      }
      return true;
    } catch (e) {
      debugPrint('设置通知失败: $e');
      return false;
    }
  }

  /// 取消每日提醒
  Future<void> cancelDailyReminder() async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_baseId + i);
    }
  }
}