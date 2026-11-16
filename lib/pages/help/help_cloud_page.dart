import 'package:flutter/material.dart';

class HelpCloudPage extends StatelessWidget {
  const HelpCloudPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('连接云端词库')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Text('内容待补充'),
      ),
    );
  }
}