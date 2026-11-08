import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/import_word.dart';
import '../models/word.dart';
import '../models/word_book.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'word_memo.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE word_books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        source_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE words (
        id TEXT PRIMARY KEY,
        word_book_id TEXT NOT NULL,
        word TEXT NOT NULL,
        meaning TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (word_book_id) REFERENCES word_books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_words_book_order ON words(word_book_id, order_index)',
    );
  }

  Future<List<WordBookWithCount>> getWordBooksWithCount() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.id, b.name, b.source_type, b.created_at,
             COUNT(w.id) AS word_count
      FROM word_books b
      LEFT JOIN words w ON w.word_book_id = b.id
      GROUP BY b.id
      ORDER BY b.created_at ASC
    ''');
    return rows.map(WordBookWithCount.fromMap).toList();
  }

  Future<List<Word>> getWordsByBook(String wordBookId) async {
    final db = await database;
    final rows = await db.query(
      'words',
      where: 'word_book_id = ?',
      whereArgs: [wordBookId],
      orderBy: 'order_index ASC',
    );
    return rows.map(Word.fromMap).toList();
  }

  Future<String> insertImportedBook({
    required String name,
    required WordBookSource source,
    required List<ImportWord> words,
  }) async {
    assert(words.isNotEmpty, 'words 不能为空');
    final db = await database;
    final now = DateTime.now();
    final bookId = 'book_${now.microsecondsSinceEpoch}';

    final book = WordBook(
      id: bookId,
      name: name,
      source: source,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('word_books', book.toMap());
      final batch = txn.batch();
      for (var i = 0; i < words.length; i++) {
        batch.insert('words', {
          'id': '${bookId}_${i.toString().padLeft(4, '0')}',
          'word_book_id': bookId,
          'word': words[i].word,
          'meaning': words[i].meaning,
          'order_index': i,
        });
      }
      await batch.commit(noResult: true);
    });

    return bookId;
  }

  Future<void> updateWord({
    required String wordId,
    required String word,
    required String meaning,
  }) async {
    final db = await database;
    await db.update(
      'words',
      {'word': word, 'meaning': meaning},
      where: 'id = ?',
      whereArgs: [wordId],
    );
  }

  Future<void> deleteWord(String wordId) async {
    final db = await database;
    await db.delete('words', where: 'id = ?', whereArgs: [wordId]);
  }

  Future<Word> addWordToBook({
    required String wordBookId,
    required String word,
    required String meaning,
  }) async {
    final db = await database;
    final maxRow = await db.rawQuery(
      'SELECT MAX(order_index) AS max_order FROM words WHERE word_book_id = ?',
      [wordBookId],
    );
    final maxOrder = (maxRow.first['max_order'] as int?) ?? -1;
    final id = 'w_${wordBookId}_${DateTime.now().microsecondsSinceEpoch}';
    final newWord = Word(
      id: id,
      wordBookId: wordBookId,
      word: word,
      meaning: meaning,
      orderIndex: maxOrder + 1,
    );
    await db.insert('words', newWord.toMap());
    return newWord;
  }

  Future<void> deleteWordBook(String bookId) async {
    final db = await database;
    await db.delete(
      'word_books',
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }
}