import 'dart:convert';

import 'package:csv/csv.dart';

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

    final WordBookSource source;
    switch (ext) {
      case 'csv':
        source = WordBookSource.csv;
        break;
      case 'json':
        source = WordBookSource.json;
        break;
      case 'txt':
        source = WordBookSource.txt;
        break;
      default:
        return ImportParseResult(
          source: WordBookSource.csv,
          fileName: safeName,
          bookName: bookName,
          words: const [],
          skippedCount: 0,
          error: '不支持的文件类型，仅支持 .csv / .json / .txt',
        );
    }

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      return ImportParseResult(
        source: source,
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
      final parsed = switch (source) {
        WordBookSource.csv => _parseCsv(content),
        WordBookSource.json => _parseJson(content),
        WordBookSource.txt => _parseTxt(content),
        WordBookSource.builtin => throw StateError('unreachable'),
        WordBookSource.manual => throw StateError('unreachable'),
      };

      if (parsed.words.isEmpty) {
        return ImportParseResult(
          source: source,
          fileName: safeName,
          bookName: bookName,
          words: const [],
          skippedCount: parsed.skipped,
          error: '没有可导入的有效词条',
        );
      }

      return ImportParseResult(
        source: source,
        fileName: safeName,
        bookName: bookName,
        words: parsed.words,
        skippedCount: parsed.skipped,
      );
    } on FormatException catch (e) {
      return ImportParseResult(
        source: source,
        fileName: safeName,
        bookName: bookName,
        words: const [],
        skippedCount: 0,
        error: e.message,
      );
    } catch (e) {
      return ImportParseResult(
        source: source,
        fileName: safeName,
        bookName: bookName,
        words: const [],
        skippedCount: 0,
        error: '解析失败：$e',
      );
    }
  }

  static ({List<ImportWord> words, int skipped}) _parseCsv(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalized);

    if (rows.isEmpty) {
      throw const FormatException('CSV 文件为空');
    }

    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList(growable: false);
    if (header.length < 2 || header[0] != 'word' || header[1] != 'meaning') {
      throw const FormatException('CSV 首行表头必须为 word,meaning');
    }

    final words = <ImportWord>[];
    var skipped = 0;
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) {
        if (row.isNotEmpty && row.first.toString().trim().isNotEmpty) {
          skipped++;
        }
        continue;
      }
      final word = row[0].toString().trim();
      final meaning = row[1].toString().trim();
      if (word.isEmpty || meaning.isEmpty) {
        skipped++;
        continue;
      }
      words.add((word: word, meaning: meaning));
    }
    return (words: words, skipped: skipped);
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

  static ({List<ImportWord> words, int skipped}) _parseTxt(String content) {
    final lines = content.split(RegExp(r'\r\n|\r|\n'));
    final words = <ImportWord>[];
    var skipped = 0;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final idx = line.indexOf(',');
      if (idx < 0) {
        skipped++;
        continue;
      }
      final word = line.substring(0, idx).trim();
      final meaning = line.substring(idx + 1).trim();
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