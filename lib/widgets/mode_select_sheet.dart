import 'package:flutter/material.dart';

import '../models/practice_mode.dart';
import '../models/word.dart';

class ModeSelectSheet extends StatelessWidget {
  /// 用当前词书的第一个词做示例，代入感最强。
  final Word sample;

  const ModeSelectSheet({super.key, required this.sample});

  static Future<PracticeMode?> show(
      BuildContext context, {
        required Word sample,
      }) {
    return showModalBottomSheet<PracticeMode>(
      context: context,
      showDragHandle: true,
      builder: (_) => ModeSelectSheet(sample: sample),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        // IntrinsicHeight 让两张卡按内容自适应并严格等高
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ModeCard(
                  sampleText: sample.word,
                  inputHint: '输入释义',
                  inputIcon: Icons.translate,
                  onTap: () =>
                      Navigator.of(context).pop(PracticeMode.wordToMeaning),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  sampleText: sample.meaning,
                  inputHint: '输入单词',
                  inputIcon: Icons.abc,
                  onTap: () =>
                      Navigator.of(context).pop(PracticeMode.meaningToWord),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String sampleText;
  final String inputHint;
  final IconData inputIcon;
  final VoidCallback onTap;

  const _ModeCard({
    required this.sampleText,
    required this.inputHint,
    required this.inputIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 居中显示
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 示例词
              Text(
                sampleText,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // 占位样式的输入框
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      inputIcon,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        inputHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}