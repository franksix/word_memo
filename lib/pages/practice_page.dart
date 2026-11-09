import 'dart:async';
import 'package:flutter/material.dart';

import '../models/practice_mode.dart';
import '../models/word.dart';
import '../services/answer_checker.dart';
import '../theme/monet_theme.dart';
import '../widgets/squiggly_progress_bar.dart';
import 'dart:math';

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

class _PracticePageState extends State<PracticePage>
    with SingleTickerProviderStateMixin {
  // 完成页的随机治愈文案
  static const List<String> _finishMessages = [
    '今天的心流时刻。',
    '知识又悄悄增加了一点。',
    '很棒，今天的光线刚刚好。',
    '慢慢来，比较快。',
    '让这些词在脑袋里安静地睡一觉吧。',
    '今天的专注，值得给自己泡杯茶。',
    '不慌不忙，你又变强了一点点。',
  ];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  int _index = 0;
  bool _submitted = false;
  bool _isCorrect = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Word? get _currentWord => (_index >= 0 && _index < widget.words.length)
      ? widget.words[_index]
      : null;

  bool get _canSubmit {
    if (_submitted && _isCorrect) return false; // 答对后禁止再次提交
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

    if (correct) {
      // 答对：延迟 600 毫秒后自动进入下一题
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _submitted && _isCorrect) {
          _next();
        }
      });
    } else {
      // 答错：触发抖动，不显示任何图标
      _shakeController.forward(from: 0);
      _requestFocus();
    }
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

    // 核心逻辑：如果当前题已经答对，进度条直接显示为下一格，给用户即时的正反馈
    // 如果已经是最后一题答对，进度最大为 1.0
    final targetProgress = _isCorrect
        ? ((_index + 2) / widget.words.length).clamp(0.0, 1.0)
        : (_index + 1) / widget.words.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          // 使用 TweenAnimationBuilder 让进度条平滑滑动
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: targetProgress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic, // 顺滑的曲线
            builder: (context, value, child) {
              return SquigglyProgressBar(
                value: value, // 传入动画过渡中的值
                height: 8,
                activeColor: theme.colorScheme.primary,
                inactiveColor:
                theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.24),
              );
            },
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
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            // 答对后锁定输入框，防止在延迟期间输入
            enabled: !_submitted || !_isCorrect,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: isWordToMeaning ? '输入中文释义…' : '输入英文单词…',
              hintStyle: TextStyle(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(isWordToMeaning ? Icons.translate : Icons.abc),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (_submitted && _isCorrect) ...[
          const SizedBox(height: 24),
          Center(child: _buildResultIcon()),
        ],
      ],
    );
  }

  Widget _buildResultIcon() {
    final theme = Theme.of(context);
    final accents = theme.extension<MonetAccents>();
    final color = accents?.success ?? theme.colorScheme.primary;

    // 只显示正确的图标
    return AnimatedScale(
      scale: _submitted ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Icon(Icons.check_circle, color: color, size: 56),
    );
  }

  Widget _buildBottomAction() {

    final Widget button;
    if (!_submitted) {
      // 未提交
      button = FilledButton(
        onPressed: _canSubmit ? _submit : null,
        child: const Icon(Icons.send),
      );
    } else if (_isCorrect) {
      // 答对：显示一个不可点击的加载圈，过渡完后自动进入下一题
      button = FilledButton(
        onPressed: null, // 禁用点击
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
        ),
      );
    } else {
      // 答错：重新提交
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
    final accents = theme.extension<MonetAccents>();
    final successColor = accents?.success ?? theme.colorScheme.primary;

    // 随机抽取一句文案
    final random = Random();
    final message = _finishMessages[random.nextInt(_finishMessages.length)];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 庆祝图标：莫奈绿色圆底
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: successColor,
            ),
          ),
          const SizedBox(height: 32),

          // 突出显示练了多少词
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.words.length}',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '个单词',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 随机治愈文案
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 56),

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
