enum PracticeMode {
  wordToMeaning,
  meaningToWord;

  String get label => switch (this) {
    PracticeMode.wordToMeaning => '看单词写意译',
    PracticeMode.meaningToWord => '看意译写单词',
  };
}