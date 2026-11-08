import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'services/settings_service.dart';
import 'theme/monet_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.init();
  runApp(const WordMemoApp());
}

class WordMemoApp extends StatelessWidget {
  const WordMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记单词',
      debugShowCheckedModeBanner: false,
      theme: buildMonetLightTheme(),
      darkTheme: buildMonetDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}