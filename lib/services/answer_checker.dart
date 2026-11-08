class AnswerChecker {
  AnswerChecker._();

  static bool checkMeaning(String input, String answer) {
    final a = stripSpaces(input);
    final b = stripSpaces(answer);
    return a.isNotEmpty && a == b;
  }

  static bool checkWord(String input, String answer) {
    return input.isNotEmpty && input == answer;
  }

  static bool canSubmitMeaning(String input) => stripSpaces(input).isNotEmpty;

  static bool canSubmitWord(String input) => input.isNotEmpty;

  static String stripSpaces(String s) =>
      s.replaceAll(RegExp(r'[ \u3000]'), '');
}