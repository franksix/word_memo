import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/practice_mode.dart';
import '../models/word.dart';
import '../services/answer_checker.dart';
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

class _PracticePageState extends State<PracticePage>
    with SingleTickerProviderStateMixin {
  // ===== 阈值 =====
  static const int _promptThreshold = 3;
  static const int _revealThreshold = 2;

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
  bool _finished = false;
  bool _isFinishing = false;
  String? _finishMessage;

  // ===== 提示机制状态 =====
  int _wrongCount = 0;
  bool _helpEnabled = false;
  bool _helpDeclined = false;
  int _answerShownAtCount = 0;
  bool _answerVisible = false;

  // ===== 分享截图 Key =====
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_finished) _focusNode.requestFocus();
    });
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
    if (_isFinishing) return false;
    final input = _controller.text;
    return widget.mode == PracticeMode.wordToMeaning
        ? AnswerChecker.canSubmitMeaning(input)
        : AnswerChecker.canSubmitWord(input);
  }

  bool get _showPromptButton =>
      !_helpEnabled && !_helpDeclined && _wrongCount >= _promptThreshold;

  bool get _showRevealButton =>
      _helpEnabled && (_wrongCount - _answerShownAtCount) >= _revealThreshold;

  void _submit() {
    if (!_canSubmit) return;
    final word = _currentWord;
    if (word == null) return;

    final input = _controller.text;
    final correct = widget.mode == PracticeMode.wordToMeaning
        ? AnswerChecker.checkMeaning(input, word.meaning)
        : AnswerChecker.checkWord(input, word.word);

    if (correct) {
      _next();
    } else {
      setState(() {
        _submitted = true;
        _wrongCount++;
      });
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _onPromptButtonTap() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('是否允许再答错后显示答案？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('不用'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('好的'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result == true) {
        _helpEnabled = true;
        _answerShownAtCount = _wrongCount;
      } else {
        _helpDeclined = true;
      }
    });
  }

  void _onRevealButtonTap() {
    setState(() {
      _answerVisible = true;
      _answerShownAtCount = _wrongCount;
    });
  }

  void _next() {
    final nextIndex = _index + 1;

    if (nextIndex >= widget.words.length) {
      setState(() {
        _isFinishing = true;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        FocusScope.of(context).unfocus();

        final randomMessage =
        _finishMessages[Random().nextInt(_finishMessages.length)];

        setState(() {
          _finished = true;
          _isFinishing = false;
          _finishMessage = randomMessage;
        });
      });
      return;
    }

    setState(() {
      _index = nextIndex;
      _submitted = false;
      _controller.clear();
      _wrongCount = 0;
      _answerShownAtCount = 0;
      _answerVisible = false;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _submitted = false;
      _finished = false;
      _isFinishing = false;
      _finishMessage = null;
      _controller.clear();
      _wrongCount = 0;
      _helpEnabled = false;
      _helpDeclined = false;
      _answerShownAtCount = 0;
      _answerVisible = false;
    });
    _focusNode.requestFocus();
  }

  // ===== 分享逻辑 =====
  Future<void> _shareResult() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // 稍微等一帧，确保隐藏卡片渲染完成
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary = _shareCardKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('找不到截图区域');

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 放大 3 倍，确保极其清晰 (1080 x 1440)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('图片数据为空');

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/word_memo_result.png');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '记单词，慢慢来，比较快。',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      debugPrint('分享失败原因: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生成图片失败，请检查网络或稍后再试')),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.words.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Icon(Icons.inbox_outlined,
                size: 64, color: theme.colorScheme.outline),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        // 关键：允许超出屏幕的组件正常渲染
        clipBehavior: Clip.none,
        children: [
          _buildBackgroundGlow(isDark),
          SafeArea(
            child: _finished ? _buildFinished(isDark) : _buildPractice(isDark),
          ),
          // 把卡片移出屏幕外，彻底隐藏，但保证引擎去绘制它
          if (_finished)
            Positioned(
              left: 9999,
              top: 0,
              child: _buildHiddenShareCard(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow(bool isDark) {
    final theme = Theme.of(context);
    final themeColor = theme.colorScheme.primary;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.4),
            radius: 1.2,
            colors: [
              themeColor.withValues(alpha: isDark ? 0.35 : 0.1),
              isDark
                  ? Colors.black.withValues(alpha: 0.9)
                  : theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: isDark
            ? BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.expand(),
        )
            : const SizedBox.expand(),
      ),
    );
  }

  Widget _buildPractice(bool isDark) {
    final targetProgress = _isFinishing ? 1.0 : _index / widget.words.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: targetProgress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SquigglyProgressBar(
                value: value,
                height: 6,
                activeColor: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Theme.of(context).colorScheme.primary,
                inactiveColor: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.2),
              );
            },
          ),
        ),

        Expanded(
          child: _buildLyricsArea(isDark),
        ),

        _buildHelpArea(),
        _buildBottomInput(isDark),
      ],
    );
  }

  Widget _buildHelpArea() {
    final showPrompt = _showPromptButton;
    final showReveal = _showRevealButton;
    final show = showPrompt || showReveal;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: show
          ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: TextButton(
          onPressed:
          showPrompt ? _onPromptButtonTap : _onRevealButtonTap,
          child: Text(showPrompt ? '需要帮助？' : '查看答案'),
        ),
      )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  Widget _buildLyricsArea(bool isDark) {
    final word = _currentWord!;
    final isWordToMeaning = widget.mode == PracticeMode.wordToMeaning;
    final prompt = isWordToMeaning ? word.word : word.meaning;
    final answerText = isWordToMeaning ? word.meaning : word.word;

    final prevWord = _index > 0 ? widget.words[_index - 1] : null;
    final prevText = prevWord != null
        ? (isWordToMeaning ? prevWord.word : prevWord.meaning)
        : '';

    final textColor =
    isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final fadeColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.3);
    final answerColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final isIncoming = child.key == ValueKey(_index);
              final offset = Tween<Offset>(
                begin:
                isIncoming ? const Offset(0, 0.3) : const Offset(0, -0.3),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offset,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0)
                        .animate(animation),
                    child: child,
                  ),
                ),
              );
            },
            child: SingleChildScrollView(
              key: ValueKey(_index),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prevText.isNotEmpty)
                      Text(
                        prevText,
                        style: TextStyle(
                          fontSize: 20,
                          color: fadeColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const SizedBox(height: 28),

                    const SizedBox(height: 32),

                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Text(
                        prompt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: textColor,
                          shadows: isDark
                              ? [
                            Shadow(
                              color:
                              Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                              : null,
                        ),
                      ),
                    ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _answerVisible
                          ? Padding(
                        key: const ValueKey('answer-on'),
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          '答案：$answerText',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: answerColor,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      )
                          : const SizedBox.shrink(
                        key: ValueKey('answer-off'),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomInput(bool isDark) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomInset > 0 ? bottomInset + 16 : 32,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
              sigmaX: isDark ? 16 : 8, sigmaY: isDark ? 16 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    readOnly: _isFinishing,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_submitted) {
                        setState(() => _submitted = false);
                      } else {
                        setState(() {});
                      }
                    },
                    onSubmitted: (_) => _submit(),
                    cursorColor: isDark
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                    decoration: InputDecoration(
                      hintText: widget.mode == PracticeMode.wordToMeaning
                          ? '输入中文释义…'
                          : '输入英文单词…',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                _buildActionButton(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    final theme = Theme.of(context);
    final canSubmit = _canSubmit;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: canSubmit
            ? (isDark ? Colors.white : theme.colorScheme.primary)
            : (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: canSubmit ? _submit : null,
        icon: Icon(
          _submitted ? Icons.refresh : Icons.arrow_upward,
          color: canSubmit
              ? (isDark ? Colors.black : Colors.white)
              : (isDark
              ? Colors.white.withValues(alpha: 0.3)
              : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildFinished(bool isDark) {
    final theme = Theme.of(context);
    final successColor = theme.colorScheme.primary;
    final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

    final message = _finishMessage ?? '';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: successColor,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.words.length}',
                style: TextStyle(
                  fontSize: 64,
                  color: successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '个单词',
                style: TextStyle(
                  fontSize: 20,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: textColor.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          // ===== 分享按钮 =====
          const SizedBox(height: 24),
          IconButton(
            onPressed: _isSharing ? null : _shareResult,
            icon: _isSharing
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.ios_share, size: 28),
            color: textColor.withValues(alpha: 0.5),
            tooltip: '保存图片或分享',
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _restart,
              style: FilledButton.styleFrom(
                backgroundColor:
                isDark ? Colors.white : theme.colorScheme.primary,
                foregroundColor:
                isDark ? Colors.black : theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.replay, size: 28),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: textColor.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.home_outlined, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 专用于截图的卡片 =====
  Widget _buildHiddenShareCard(bool isDark) {
    final theme = Theme.of(context);
    final successColor = theme.colorScheme.primary;
    final message = _finishMessage ?? '';

    final now = DateTime.now();
    final dateStr =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    // 浅色模式直接用纯白，深色用深灰，文字绝对清晰
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return RepaintBoundary(
      key: _shareCardKey,
      child: Container(
        width: 360,
        height: 480,
        decoration: BoxDecoration(
          // 去掉渐变，只留纯色
          color: bgColor,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: successColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: successColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${widget.words.length}',
                        style: TextStyle(
                          fontSize: 64,
                          color: successColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '个单词',
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 底部落款
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Text(
                '$dateStr  ·  记单词',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.4),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}