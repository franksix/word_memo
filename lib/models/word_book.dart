enum WordBookSource {
  builtin,
  csv,
  json,
  txt,
  manual;

  static WordBookSource fromString(String? value) {
    switch (value) {
      case 'csv':
        return WordBookSource.csv;
      case 'json':
        return WordBookSource.json;
      case 'txt':
        return WordBookSource.txt;
      case 'manual':
        return WordBookSource.manual;
      default:
        return WordBookSource.builtin;
    }
  }

  String get dbValue => name;
}

class WordBook {
  final String id;
  final String name;
  final WordBookSource source;
  final DateTime createdAt;

  const WordBook({
    required this.id,
    required this.name,
    required this.source,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'source_type': source.dbValue,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory WordBook.fromMap(Map<String, Object?> map) => WordBook(
    id: map['id'] as String,
    name: map['name'] as String,
    source: WordBookSource.fromString(map['source_type'] as String?),
    createdAt:
    DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

class WordBookWithCount {
  final WordBook book;
  final int wordCount;

  const WordBookWithCount({required this.book, required this.wordCount});

  factory WordBookWithCount.fromMap(Map<String, Object?> map) {
    return WordBookWithCount(
      book: WordBook.fromMap(map),
      wordCount: (map['word_count'] as int?) ?? 0,
    );
  }
}