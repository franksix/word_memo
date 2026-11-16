import 'package:flutter/material.dart';

class HelpConceptPage extends StatelessWidget {
  const HelpConceptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('产品理念')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Text('内容待补充'),
      ),
    );
  }
}