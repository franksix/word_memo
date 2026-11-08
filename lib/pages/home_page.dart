import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/word_book.dart';
import '../services/settings_service.dart';
import '../widgets/mode_select_sheet.dart';
import 'create_book_page.dart';
import 'import_page.dart';
import 'manage_words_page.dart';
import 'practice_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;
  List<WordBookWithCount> _books = const [];
  String? _currentBookId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await SettingsService.instance.init();
      final books = await AppDatabase.instance.getWordBooksWithCount();
      final savedId = await SettingsService.instance.getCurrentWordBookId();

      String? currentId;
      if (savedId != null && books.any((b) => b.book.id == savedId)) {
        currentId = savedId;
      } else if (books.isNotEmpty) {
        currentId = books.first.book.id;
        await SettingsService.instance.setCurrentWordBookId(currentId);
      } else {
        await SettingsService.instance.clearCurrentWordBookId();
      }

      if (!mounted) return;
      setState(() {
        _books = books;
        _currentBookId = currentId;
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

  Future<void> _selectBook(WordBookWithCount item) async {
    if (_currentBookId == item.book.id) return;
    setState(() => _currentBookId = item.book.id);
    await SettingsService.instance.setCurrentWordBookId(item.book.id);
  }

  Future<void> _startStudy() async {
    final currentId = _currentBookId;
    if (currentId == null) return;

    WordBookWithCount? current;
    for (final b in _books) {
      if (b.book.id == currentId) {
        current = b;
        break;
      }
    }
    if (current == null) return;

    final words = await AppDatabase.instance.getWordsByBook(currentId);
    if (!mounted) return;
    if (words.isEmpty) {
      _iconToast(Icons.inbox_outlined);
      return;
    }

    final mode = await ModeSelectSheet.show(context);
    if (mode == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticePage(
          wordBookName: current!.book.name,
          mode: mode,
          words: words,
        ),
      ),
    );
  }

  Future<void> _onCreateTap() async {
    if (_loading) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateBookPage()),
    );
    if (!mounted) return;
    if (created == true) {
      await _load(silent: true);
    }
  }

  Future<void> _onManageTap(WordBookWithCount item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManageWordsPage(book: item.book),
      ),
    );
    if (!mounted) return;
    await _load(silent: true);
  }

  Future<void> _onDeleteTap(WordBookWithCount item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('确定删除「${item.book.name}」及其中所有词条吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Icon(Icons.close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AppDatabase.instance.deleteWordBook(item.book.id);

      if (_currentBookId == item.book.id) {
        await SettingsService.instance.clearCurrentWordBookId();
      }

      await _load(silent: true);
      _iconToast(Icons.check);
    } catch (e) {
      _iconToast(Icons.error_outline);
    }
  }

  Future<void> _onImportTap() async {
    if (_loading) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportPage()),
    );
    if (!mounted) return;
    await _load(silent: true);
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

  IconData _sourceIcon(WordBookSource source) => switch (source) {
    WordBookSource.builtin => Icons.verified_outlined,
    WordBookSource.csv => Icons.table_chart_outlined,
    WordBookSource.json => Icons.data_object,
    WordBookSource.txt => Icons.description_outlined,
    WordBookSource.manual => Icons.edit_note,
  };

  String _sourceTooltip(WordBookSource source) => switch (source) {
    WordBookSource.builtin => '内置词书',
    WordBookSource.csv => 'CSV 导入',
    WordBookSource.json => 'JSON 导入',
    WordBookSource.txt => 'TXT 导入',
    WordBookSource.manual => '手动创建',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.menu_book_outlined),
        actions: [
          IconButton(
            tooltip: '导入词库',
            // 换成了 file_open，表示从本地打开文件
            icon: const Icon(Icons.file_open_outlined),
            onPressed: _loading ? null : _onImportTap,
          ),
        ],
      ),
      body: _buildBody(),
      // FAB 只要不是加载中就一直显示，方便在空状态下快速创建
      floatingActionButton: _loading
          ? null
          : FloatingActionButton(
        onPressed: _onCreateTap,
        tooltip: '手动创建词书',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed:
            (_currentBookId != null && !_loading) ? _startStudy : null,
            child: const Icon(Icons.play_arrow),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
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
                  size: 48, color: theme.colorScheme.error),
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
    if (_books.isEmpty) {
      // 空状态下，居中显示图标提示即可，操作由 AppBar 和 FAB 承担
      return Center(
        child: Icon(Icons.library_books_outlined,
            size: 72, color: theme.colorScheme.outline),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildBookCard(_books[index]),
    );
  }

  Widget _buildBookCard(WordBookWithCount item) {
    final selected = item.book.id == _currentBookId;
    final theme = Theme.of(context);
    return Card(
      elevation: selected ? 2 : 0,
      color: selected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectBook(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? theme.colorScheme.primary : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.book.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.wordCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Tooltip(
                          message: _sourceTooltip(item.book.source),
                          child: Icon(
                            _sourceIcon(item.book.source),
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '管理词条',
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: theme.colorScheme.primary,
                visualDensity: VisualDensity.compact,
                onPressed: () => _onManageTap(item),
              ),
              IconButton(
                tooltip: '删除词书',
                icon: const Icon(Icons.delete_outline, size: 20),
                color: theme.colorScheme.error,
                visualDensity: VisualDensity.compact,
                onPressed: () => _onDeleteTap(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}