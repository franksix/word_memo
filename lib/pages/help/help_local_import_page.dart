import 'package:flutter/material.dart';

class HelpLocalImportPage extends StatelessWidget {
  const HelpLocalImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('从本地导入')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Text('内容待补充'),
      ),
    );
  }
}