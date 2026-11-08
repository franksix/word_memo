class Word {
  final String id;
  final String wordBookId;
  final String word;
  final String meaning;
  final int orderIndex;

  const Word({
    required this.id,
    required this.wordBookId,
    required this.word,
    required this.meaning,
    required this.orderIndex,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'word_book_id': wordBookId,
    'word': word,
    'meaning': meaning,
    'order_index': orderIndex,
  };

  factory Word.fromMap(Map<String, Object?> map) => Word(
    id: map['id'] as String,
    wordBookId: map['word_book_id'] as String,
    word: map['word'] as String,
    meaning: map['meaning'] as String,
    orderIndex: map['order_index'] as int,
  );
}