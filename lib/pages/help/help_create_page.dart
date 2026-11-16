import 'package:flutter/material.dart';

class HelpCreatePage extends StatelessWidget {
  const HelpCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手动创建词书')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Text('内容待补充'),
      ),
    );
  }
}