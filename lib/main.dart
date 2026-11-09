import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_themes.dart'; // 改用新文件

// 两个全局控制器
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<AppThemeStyle> themeStyleNotifier = ValueNotifier(AppThemeStyle.monet);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.init();
  await NotificationService.instance.init();

  final isNotifyEnabled = await SettingsService.instance.getNotificationEnabled();
  if (isNotifyEnabled) {
    final hour = await SettingsService.instance.getNotificationHour();
    final minute = await SettingsService.instance.getNotificationMinute();
    NotificationService.instance.scheduleDailyReminder(hour: hour, minute: minute);
  }

  // 初始化读取设置
  final savedMode = await SettingsService.instance.getThemeMode();
  themeModeNotifier.value = switch (savedMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  final savedStyle = await SettingsService.instance.getThemeStyle();
  themeStyleNotifier.value = switch (savedStyle) {
    'paper' => AppThemeStyle.paper,
    'glacier' => AppThemeStyle.glacier,
    'peach' => AppThemeStyle.peach,
    _ => AppThemeStyle.monet,
  };

  runApp(const WordMemoApp());
}

class WordMemoApp extends StatelessWidget {
  const WordMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<AppThemeStyle>(
          valueListenable: themeStyleNotifier,
          builder: (context, currentStyle, _) {
            return MaterialApp(
              title: '记单词',
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(currentStyle, Brightness.light),
              darkTheme: buildAppTheme(currentStyle, Brightness.dark),
              themeMode: currentMode,
              home: const HomePage(),
            );
          },
        );
      },
    );
  }
}