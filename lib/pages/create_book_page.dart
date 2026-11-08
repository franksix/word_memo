import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/import_word.dart';
import '../models/word_book.dart';

class CreateBookPage extends StatefulWidget {
  const CreateBookPage({super.key});

  @override
  State<CreateBookPage> createState() => _CreateBookPageState();
}

class _Entry {
  final String id;
  final TextEditingController word;
  final TextEditingController meaning;

  _Entry()
      : id = UniqueKey().toString(),
        word = TextEditingController(),
        meaning = TextEditingController();

  void dispose() {
    word.dispose();
    meaning.dispose();
  }

  bool get isValid =>
      word.text.trim().isNotEmpty && meaning.text.trim().isNotEmpty;
}

class _CreateBookPageState extends State<CreateBookPage> {
  final TextEditingController _nameController = TextEditingController();
  final List<_Entry> _entries = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entries.add(_Entry());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _addEntry() {
    setState(() => _entries.add(_Entry()));
  }

  void _removeEntry(int index) {
    if (_entries.length <= 1) return;
    setState(() {
      final removed = _entries.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入词书名称');
      return;
    }

    final words = <ImportWord>[];
    for (final e in _entries) {
      if (e.isValid) {
        words.add((
        word: e.word.text.trim(),
        meaning: e.meaning.text.trim(),
        ));
      }
    }
    if (words.isEmpty) {
      setState(() => _error = '至少填写一条完整的词条');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AppDatabase.instance.insertImportedBook(
        name: name,
        source: WordBookSource.manual,
        words: words,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '保存失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.create_new_folder_outlined),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '词书名称',
                prefixIcon: Icon(Icons.book_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_entries.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _entries.length; i++)
              KeyedSubtree(
                key: ValueKey(_entries[i].id),
                child: _buildEntryRow(i),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _addEntry,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加词条'),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryRow(int index) {
    final entry = _entries[index];
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: entry.word,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '单词',
                    prefixIcon: Icon(Icons.abc, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: entry.meaning,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: '释义',
                    prefixIcon: Icon(Icons.translate, size: 20),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          if (_entries.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: _saving ? null : () => _removeEntry(index),
              ),
            )
          else
            const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}