import 'package:flutter/material.dart';

class HelpPracticePage extends StatelessWidget {
  const HelpPracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单词练习')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Text('内容待补充'),
      ),
    );
  }
}