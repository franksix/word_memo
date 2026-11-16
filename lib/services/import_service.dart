import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/import_word.dart';
import '../models/word_book.dart';

class ImportParseResult {
  final WordBookSource source;
  final String fileName;
  final String bookName;
  final List<ImportWord> words;
  final int skippedCount;
  final String? error;

  const ImportParseResult({
    required this.source,
    required this.fileName,
    required this.bookName,
    required this.words,
    required this.skippedCount,
    this.error,
  });
}

class ImportService {
  ImportService._();

  static ImportParseResult parse({
    required String fileName,
    required List<int> bytes,
  }) {
    final safeName = _baseName(fileName);
    final ext = _extension(safeName);
    final bookName = _bookNameFromFile(safeName);

    if (ext != 'json') {
      return ImportParseResult(
        source: WordBookSource.json,
        fileName: safeName,
        bookName: bookName,
        words: const [],
        skippedCount: 0,
        error: '不支持的文件类型，仅支持 .json',
      );
    }

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      return ImportParseResult(
        source: WordBookSource.json,
        fileName: safeName,
        bookName: bookName,
        words: const [],
        skippedCount: 0,
        error: '文件编码不是 UTF-8，无法解析',
      );
    }
    if (content.startsWith('\ufeff')) {
      content = content.substring(1);
    }

    try {
      final parsed = _parseJson(content);

      if (parsed.words.isEmpty) {
        return ImportParseResult(
          source: WordBookSource.json,
          fileName: safeName,
          bookName: bookName,
          words: const [],
          skippedCount: parsed.skipped,
          error: '没有可导入的有效词条',
        );
      }

      return ImportParseResult(
        source: WordBookSource.json,
        fileName: safeName,
        bookName: bookName,
        words: parsed.words,
        skippedCount: parsed.skipped,
      );
    } on FormatException catch (e) {
      return ImportParseResult(
        source: WordBookSource.json,
        fileName: safeName,
        bookName: bookName,
        words: const [],
        skippedCount: 0,
        error: e.message,
      );
    } catch (e) {
      return ImportParseResult(
        source: WordBookSource.json,
        fileName: safeName,
        bookName: bookName,
        words: const [],
        skippedCount: 0,
        error: '解析失败：$e',
      );
    }
  }

  /// 从链接下载 JSON 并挑出有效词条。
  /// 成功：(words: 列表, error: null)；
  /// 失败：(words: null, error: 说明)。
  static Future<({List<ImportWord>? words, String? error})> fetchFromUrl(
      String url,
      ) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return (words: null, error: '请求失败：${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        return (words: null, error: 'JSON 顶层必须是数组');
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
        return (words: null, error: '没有可导入的有效词条');
      }
      return (words: words, error: null);
    } on TimeoutException {
      return (words: null, error: '连接超时，请检查网络');
    } on FormatException catch (e) {
      return (words: null, error: 'JSON 格式错误：${e.message}');
    } catch (e) {
      final errStr = e.toString();
      // 识别断网、DNS 解析失败、无法连接主机等底层网络错误
      if (errStr.contains('SocketException') ||
          errStr.contains('ClientException') ||
          errStr.contains('Failed host lookup') ||
          errStr.contains('Network is unreachable')) {
        return (words: null, error: '网络连接失败，请检查网络');
      }
      return (words: null, error: '下载失败，请稍后再试');
    }
  }

  static ({List<ImportWord> words, int skipped}) _parseJson(String content) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const FormatException('JSON 格式错误');
    }
    if (decoded is! List) {
      throw const FormatException('JSON 顶层必须是数组');
    }

    final words = <ImportWord>[];
    var skipped = 0;
    for (final item in decoded) {
      if (item is! Map) {
        skipped++;
        continue;
      }
      final rawWord = item['word'];
      final rawMeaning = item['meaning'];
      if (rawWord is! String || rawMeaning is! String) {
        skipped++;
        continue;
      }
      final word = rawWord.trim();
      final meaning = rawMeaning.trim();
      if (word.isEmpty || meaning.isEmpty) {
        skipped++;
        continue;
      }
      words.add((word: word, meaning: meaning));
    }
    return (words: words, skipped: skipped);
  }

  static String _baseName(String name) {
    final i = name.lastIndexOf(RegExp(r'[/\\]'));
    return i >= 0 ? name.substring(i + 1) : name;
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static String _bookNameFromFile(String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final trimmed = base.trim();
    return trimmed.isEmpty ? '导入词书' : trimmed;
  }
}