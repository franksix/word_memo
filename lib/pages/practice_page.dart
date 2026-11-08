import 'package:flutter/material.dart';

import '../models/practice_mode.dart';
import '../models/word.dart';
import '../services/answer_checker.dart';
import '../theme/monet_theme.dart';
import '../widgets/squiggly_progress_bar.dart';

class PracticePage extends StatefulWidget {
  final String wordBookName;
  final PracticeMode mode;
  final List<Word> words;

  const PracticePage({
    super.key,
    required this.wordBookName,
    required this.mode,
    required this.words,
  });

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _index = 0;
  bool _submitted = false;
  bool _isCorrect = false;
  bool _finished = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Word? get _currentWord =>
      (_index >= 0 && _index < widget.words.length)
          ? widget.words[_index]
          : null;

  bool get _canSubmit {
    final input = _controller.text;
    return widget.mode == PracticeMode.wordToMeaning
        ? AnswerChecker.canSubmitMeaning(input)
        : AnswerChecker.canSubmitWord(input);
  }

  void _submit() {
    if (!_canSubmit) return;
    final word = _currentWord;
    if (word == null) return;

    final input = _controller.text;
    final correct = widget.mode == PracticeMode.wordToMeaning
        ? AnswerChecker.checkMeaning(input, word.meaning)
        : AnswerChecker.checkWord(input, word.word);

    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });

    if (!correct) _requestFocus();
  }

  void _next() {
    if (!_submitted || !_isCorrect) return;
    final nextIndex = _index + 1;
    if (nextIndex >= widget.words.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index = nextIndex;
      _submitted = false;
      _isCorrect = false;
      _controller.clear();
    });
    _requestFocus();
  }

  void _restart() {
    setState(() {
      _index = 0;
      _submitted = false;
      _isCorrect = false;
      _finished = false;
      _controller.clear();
    });
    _requestFocus();
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Icon(Icons.inbox_outlined, size: 64)),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _finished ? _buildFinished() : _buildPracticeWithProgress(),
      ),
    );
  }

  // ---------------- 练习 ----------------

  Widget _buildPracticeWithProgress() {
    final theme = Theme.of(context);
    final progress = (_index + 1) / widget.words.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: SquigglyProgressBar(
            value: progress,
            height: 8,
            activeColor: theme.colorScheme.primary,
            inactiveColor:
            theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.24),
          ),
        ),
        Expanded(child: _buildPracticeContent()),
        _buildBottomAction(),
      ],
    );
  }

  Widget _buildPracticeContent() {
    final word = _currentWord!;
    final theme = Theme.of(context);
    final isWordToMeaning = widget.mode == PracticeMode.wordToMeaning;
    final prompt = isWordToMeaning ? word.word : word.meaning;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
      children: [
        Center(
          child: Text(
            prompt,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: !_submitted || !_isCorrect,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            prefixIcon: Icon(isWordToMeaning ? Icons.translate : Icons.abc),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_submitted) ...[
          const SizedBox(height: 24),
          Center(child: _buildResultIcon()),
        ],
      ],
    );
  }

  Widget _buildResultIcon() {
    final theme = Theme.of(context);
    final accents = theme.extension<MonetAccents>();
    final color = _isCorrect
        ? (accents?.success ?? theme.colorScheme.primary)
        : theme.colorScheme.error;
    final icon = _isCorrect ? Icons.check_circle : Icons.cancel;
    return Icon(icon, color: color, size: 56);
  }

  Widget _buildBottomAction() {
    final isLast = _index + 1 >= widget.words.length;

    final Widget button;
    if (!_submitted) {
      button = FilledButton(
        onPressed: _canSubmit ? _submit : null,
        child: const Icon(Icons.send),
      );
    } else if (_isCorrect) {
      button = FilledButton(
        onPressed: _next,
        child: Icon(isLast ? Icons.done_all : Icons.arrow_forward),
      );
    } else {
      button = FilledButton(
        onPressed: _canSubmit ? _submit : null,
        child: const Icon(Icons.refresh),
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: button,
      ),
    );
  }

  // ---------------- 完成页 ----------------

  Widget _buildFinished() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 庆祝图标：圆形主色底 + 大图标
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          // 本轮单词数：图标 + 大号数字
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.format_list_numbered,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.words.length}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          // 主操作：再练一次
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _restart,
              child: const Icon(Icons.replay, size: 28),
            ),
          ),
          const SizedBox(height: 12),
          // 次操作：返回首页
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(Icons.home_outlined, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}