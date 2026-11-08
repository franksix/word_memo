import 'dart:convert';

import '../models/word.dart';

class ExportService {
  ExportService._();

  /// 导出为与导入兼容的 JSON：
  /// 顶层数组，每个元素 {word, meaning}
  static String toJson(List<Word> words) {
    final list = words
        .map((w) => {'word': w.word, 'meaning': w.meaning})
        .toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  /// 由词书名生成安全文件名：去掉非法字符，空则“词书”
  static String fileNameFor(String bookName) {
    final cleaned = bookName
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .trim();
    final name = cleaned.isEmpty ? '词书' : cleaned;
    return '$name.json';
  }
}