import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recommended_book.dart';

class RecommendedBookService {
  RecommendedBookService._();
  static final RecommendedBookService instance = RecommendedBookService._();

  static const _manifestUrl =
      'https://raw.gitcode.com/frank_mia/wordbook/raw/master/books.json';
  static const _cacheKey = 'recommended_books_cache';

  /// 兜底清单：首次安装 + 没网时用。内容和远端保持一致。
  static const List<RecommendedBook> fallbackList = [
    RecommendedBook(
      name: '四级词汇 1',
      description: '英语四级考试词汇，A 部分',
      wordCount: 268,
      url: 'https://raw.gitcode.com/frank_mia/wordbook/raw/master/a.json',
    ),
    RecommendedBook(
      name: '四级词汇 2',
      description: '英语四级考试词汇，B 部分',
      wordCount: 167,
      url: 'https://raw.gitcode.com/frank_mia/wordbook/raw/master/b.json',
    ),
    RecommendedBook(
      name: '四级词汇 3',
      description: '英语四级考试词汇，C 部分',
      wordCount: 402,
      url: 'https://raw.gitcode.com/frank_mia/wordbook/raw/master/c.json',
    ),
  ];

  /// 读本地缓存。没缓存返回 null。
  Future<List<RecommendedBook>?> getCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      return _parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// 去远端拉清单。成功就写缓存并返回，失败返回 null。
  Future<List<RecommendedBook>?> fetchRemote() async {
    try {
      final response = await http
          .get(Uri.parse(_manifestUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final body = utf8.decode(response.bodyBytes);
      final books = _parse(body);
      if (books == null || books.isEmpty) return null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      return books;
    } catch (_) {
      return null;
    }
  }

  List<RecommendedBook>? _parse(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      final result = <RecommendedBook>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final name = item['name'];
        final description = item['description'];
        final wordCount = item['wordCount'];
        final url = item['url'];
        if (name is! String || description is! String || url is! String) {
          continue;
        }
        if (name.isEmpty || url.isEmpty) continue;
        result.add(RecommendedBook(
          name: name,
          description: description,
          wordCount: wordCount is int ? wordCount : 0,
          url: url,
        ));
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }
}