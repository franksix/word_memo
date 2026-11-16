import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/app_database.dart';
import '../models/import_word.dart';
import '../models/word_book.dart';
import '../services/settings_service.dart';
import 'help_page.dart';

// ==========================================
// 绑定页（从添加词书进入，纯粹的表单操作）
// ==========================================
class CloudGuidePage extends StatefulWidget {
  const CloudGuidePage({super.key});

  @override
  State<CloudGuidePage> createState() => _CloudGuidePageState();
}

class _CloudGuidePageState extends State<CloudGuidePage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isTesting = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// 从链接中提取词书名：
  /// - 去掉 ? 和 # 之后的参数
  /// - 取最后一段路径
  /// - 去掉 .json 后缀
  /// - 提取不到则返回空串（调用方兜底）
  String _bookNameFromUrl(String url) {
    var clean = url;
    final qIndex = clean.indexOf('?');
    if (qIndex >= 0) clean = clean.substring(0, qIndex);
    final hashIndex = clean.indexOf('#');
    if (hashIndex >= 0) clean = clean.substring(0, hashIndex);

    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }

    final slashIndex = clean.lastIndexOf('/');
    var name = slashIndex >= 0 ? clean.substring(slashIndex + 1) : clean;

    if (name.toLowerCase().endsWith('.json')) {
      name = name.substring(0, name.length - 5);
    }
    return name.trim();
  }

  Future<void> _testAndBind() async {
    final url = _urlController.text.trim();
    var bookName = _nameController.text.trim();

    if (url.isEmpty) {
      _showSnackBar('请先填入链接');
      return;
    }
    if (!url.startsWith('http')) {
      _showSnackBar('链接必须以 http 或 https 开头');
      return;
    }

    // 没填词书名：从链接文件名取名；仍为空则兜底
    if (bookName.isEmpty) {
      bookName = _bookNameFromUrl(url);
      if (bookName.isEmpty) {
        bookName = '云端词书';
      }
    }

    setState(() => _isTesting = true);

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('请求失败：${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('JSON 顶层必须是数组');
      }

      final words = <ImportWord>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final rawWord = item['word'];
        final rawMeaning = item['meaning'];
        if (rawWord is! String || rawMeaning is! String) continue;

        final word = rawWord.trim();
        final meaning = rawMeaning.trim();
        if (word.isNotEmpty && meaning.isNotEmpty) {
          words.add((word: word, meaning: meaning));
        }
      }

      if (words.isEmpty) {
        throw const FormatException('没有可导入的有效词条');
      }

      // 永远新建词书，不覆盖原有数据
      final newBookId = await AppDatabase.instance.insertImportedBook(
        name: bookName,
        source: WordBookSource.cloud,
        words: words,
      );

      await SettingsService.instance.setCloudUrlByBookId(newBookId, url);

      if (!mounted) return;
      _showSnackBar('已添加 ${words.length} 个单词');
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnackBar('添加失败：$e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 简单的提示区
            Text(
              '填入 JSON 文件的 Raw 链接。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // 跳转帮助页的按钮
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpPage()),
                  );
                },
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('不会获取链接？查看教程'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 表单输入区
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '词书名',
                hintText: '不填则用文件名',
                prefixIcon: Icon(Icons.book_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Raw 链接',
                hintText: 'https://.../raw/main/words.json',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isTesting ? null : _testAndBind,
                child: _isTesting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}