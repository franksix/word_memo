import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/word_book.dart';
import '../services/settings_service.dart'; // 确保引对路径
import '../widgets/mode_select_sheet.dart';
import '../widgets/settings_sheet.dart';     // 确保引对路径
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
    final hasBooks = _books.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: IconButton(
          onPressed: () => SettingsSheet.show(context),
          icon: const Icon(Icons.menu_book_outlined),
          tooltip: '设置',
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        actions: [
          IconButton(
            tooltip: '手动创建词书',
            icon: const Icon(Icons.add),
            onPressed: _loading ? null : _onCreateTap,
          ),
          IconButton(
            tooltip: '导入词库',
            icon: const Icon(Icons.file_open_outlined),
            onPressed: _loading ? null : _onImportTap,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _loading
          ? null
          : Padding(
        // 重点1：底部留出 24 的空白，让它远离底边；左右留出 24 让它不贴边
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: SizedBox(
          // 重点2：宽度拉满整个屏幕，高度增至 72
          width: double.infinity,
          height: 72,
          child: FloatingActionButton(
            // 重点3：大圆角矩形，取代正圆形
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onPressed: hasBooks ? _startStudy : _onCreateTap,
            tooltip: hasBooks ? '开始练习' : '新建词书',
            // 稍微加重阴影，增强悬浮感
            elevation: 8,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: Icon(
                hasBooks ? Icons.play_arrow : Icons.add,
                key: ValueKey<bool>(hasBooks),
                size: 36, // 图标放大
              ),
            ),
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
      return Center(
        child: Icon(Icons.library_books_outlined,
            size: 72, color: theme.colorScheme.outline),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
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