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
      builder: (context) => AlertDialog(
        content: Text('「${word.word}」'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Icon(Icons.close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Icon(Icons.delete_outline),
          ),
        ],
      ),
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
      final fileName = ExportService.fileNameFor(widget.book.name);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.name),
        actions: [
          IconButton(
            tooltip: '导出为 JSON',
            icon: const Icon(Icons.download_outlined),
            onPressed: _loading ? null : _export,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.format_list_numbered, size: 16),
                  const SizedBox(width: 4),
                  Text('${_words.length}',
                      style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
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
      itemCount: _words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final word = _words[index];
        final theme = Theme.of(context);
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 8),
            leading: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '编辑',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: theme.colorScheme.primary,
                  onPressed: () => _editWord(word),
                ),
                const SizedBox(width: 8), // 间距
                IconButton(
                  tooltip: '删除',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: theme.colorScheme.error,
                  onPressed: () => _deleteWord(word),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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