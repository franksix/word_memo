class AnswerChecker {
  AnswerChecker._();

  static bool checkMeaning(String input, String answer) {
    final candidates = _splitMeanings(answer);
    final inputs = _splitMeanings(input);
    if (inputs.isEmpty || candidates.isEmpty) return false;
    for (final i in inputs) {
      if (candidates.contains(i)) return true;
    }
    return false;
  }

  static bool checkWord(String input, String answer) {
    final a = input.trim().toLowerCase();
    final b = answer.trim().toLowerCase();
    return a.isNotEmpty && a == b;
  }

  static bool canSubmitMeaning(String input) => stripSpaces(input).isNotEmpty;

  static bool canSubmitWord(String input) => input.isNotEmpty;

  static String stripSpaces(String s) =>
      s.replaceAll(RegExp(r'[ \u3000]'), '');

  /// 把一段释义按分隔符切成多个候选，归一化后返回。
  /// 每段同时产出：完整版 + 去掉括号补充说明版。
  static List<String> _splitMeanings(String s) {
    final parts = s.split(RegExp(r'[;；,，/]'));
    final result = <String>[];
    for (final p in parts) {
      final full = _normalize(p);
      if (full.isNotEmpty) result.add(full);

      if (p.contains('(') || p.contains('（')) {
        final stripped =
        p.replaceAll(RegExp(r'[\(（][^)）]*[\)）]'), '');
        final noParen = _normalize(stripped);
        if (noParen.isNotEmpty && noParen != full) {
          result.add(noParen);
        }
      }
    }
    return result;
  }

  /// 归一化：去空格（半角/全角）、去常见中英文标点。
  static String _normalize(String s) {
    return s
        .replaceAll(RegExp(r'[ \u3000]'), '')
        .replaceAll(RegExp(r'[。．\.！!？?、]'), '')
        .trim();
  }
}