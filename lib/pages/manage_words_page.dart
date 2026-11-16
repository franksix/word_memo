import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/word.dart';
import '../models/word_book.dart';
import '../services/export_service.dart';

class ManageWordsPage extends StatefulWidget {
  final WordBook book;

  const ManageWordsPage({super.key, required this.book});

  @override
  State<ManageWordsPage> createState() => _ManageWordsPageState();
}

class _ManageWordsPageState extends State<ManageWordsPage> {
  bool _loading = true;
  String? _error;
  List<Word> _words = const [];

  // 词书名可能被修改，用本地变量维护
  late String _bookName = widget.book.name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final words =
      await AppDatabase.instance.getWordsByBook(widget.book.id);
      if (!mounted) return;
      setState(() {
        _words = words;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  // ===== 重命名词书 =====
  Future<void> _renameBook() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initialName: _bookName),
    );

    if (newName == null || newName.isEmpty || !mounted) return;
    if (newName == _bookName) return;

    try {
      await AppDatabase.instance.updateWordBookName(
        bookId: widget.book.id,
        name: newName,
      );
      if (!mounted) return;
      setState(() => _bookName = newName);
      _iconToast(Icons.check);
    } catch (e) {
      _iconToast(Icons.error_outline);
    }
  }

  Future<void> _addWord() async {
    final input = await showDialog<({String word, String meaning})>(
      context: context,
      builder: (_) => const _WordDialog(),
    );
    if (input == null || !mounted) return;

    try {
      await AppDatabase.instance.addWordToBook(
        wordBookId: widget.book.id,
        word: input.word,
        meaning: input.meaning,
      );
      await _load();
      _iconToast(Icons.check);
    } catch (e) {
      _iconToast(Icons.error_outline);
    }
  }

  Future<void> _editWord(Word word) async {
    final input = await showDialog<({String word, String meaning})>(
      context: context,
      builder: (_) => _WordDialog(
        initialWord: word.word,
        initialMeaning: word.meaning,
      ),
    );
    if (input == null || !mounted) return;

    try {
      await AppDatabase.instance.updateWord(
        wordId: word.id,
        word: input.word,
        meaning: input.meaning,
      );
      await _load();
      _iconToast(Icons.check);
    } catch (e) {
      _iconToast(Icons.error_outline);
    }
  }

  Future<void> _deleteWord(Word word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '删除「${word.word}」？',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // 按钮组：平分宽度的大按钮
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await AppDatabase.instance.deleteWord(word.id);
      await _load();
      _iconToast(Icons.check);
    } catch (e) {
      _iconToast(Icons.error_outline);
    }
  }

  Future<void> _export() async {
    if (_words.isEmpty) {
      _iconToast(Icons.inbox_outlined);
      return;
    }
    try {
      final jsonStr = ExportService.toJson(_words);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      final fileName = ExportService.fileNameFor(_bookName);

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出词书',
        fileName: fileName,
        bytes: bytes,
      );

      if (savedPath == null) return;
      _iconToast(Icons.check);
    } catch (e) {
      _iconToast(Icons.error_outline);
    }
  }

  void _iconToast(IconData icon) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Icon(
          icon,
          color: theme.colorScheme.onSecondaryContainer,
          size: 24,
        ),
        backgroundColor: theme.colorScheme.secondaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 12),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        // 词书名可点击重命名
        title: InkWell(
          onTap: _loading ? null : _renameBook,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              _bookName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
        actions: [
          // 仅保留导出按钮
          IconButton(
            tooltip: '导出为 JSON',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _loading ? null : _export,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      // 底部栏：纯添加按钮
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _addWord,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );
    }

    if (_words.isEmpty) {
      return Center(
        child: Icon(Icons.inbox_outlined,
            size: 64, color: Theme.of(context).colorScheme.outline),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      // 长度 + 1，最后一项用来显示统计文字
      itemCount: _words.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        // 列表最后一项（统计区）
        if (index == _words.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 32),
            child: Center(
              child: Text(
                '共 ${_words.length} 个单词',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        // 正常的单词卡片
        final word = _words[index];
        final theme = Theme.of(context);
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            // 删除了左侧数字，调整了边距，整体更清爽
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            // 整张卡片可点 -> 编辑
            onTap: () => _editWord(word),
            title: Text(
              word.word,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              word.meaning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              tooltip: '删除',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: theme.colorScheme.error,
              onPressed: () => _deleteWord(word),
            ),
          ),
        );
      },
    );
  }
}

// ===== 重命名词书弹窗 =====
class _RenameDialog extends StatefulWidget {
  final String initialName;

  const _RenameDialog({required this.initialName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改词书名'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: '词书名',
          prefixIcon: Icon(Icons.book_outlined),
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close),
        ),
        FilledButton(
          onPressed: _save,
          child: const Icon(Icons.check),
        ),
      ],
    );
  }
}

// ===== 添加/编辑单词弹窗 =====
class _WordDialog extends StatefulWidget {
  final String initialWord;
  final String initialMeaning;

  const _WordDialog({
    this.initialWord = '',
    this.initialMeaning = '',
  });

  @override
  State<_WordDialog> createState() => _WordDialogState();
}

class _WordDialogState extends State<_WordDialog> {
  late final TextEditingController _wordController;
  late final TextEditingController _meaningController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.initialWord);
    _meaningController = TextEditingController(text: widget.initialMeaning);
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop((
    word: _wordController.text.trim(),
    meaning: _meaningController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _wordController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '单词',
                prefixIcon: Icon(Icons.abc),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? '请输入单词' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _meaningController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: '释义',
                prefixIcon: Icon(Icons.translate),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? '请输入释义' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close),
        ),
        FilledButton(
          onPressed: _save,
          child: const Icon(Icons.check),
        ),
      ],
    );
  }
}