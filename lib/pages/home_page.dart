import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/app_database.dart';
import '../models/import_word.dart';
import '../models/recommended_book.dart';
import '../models/word_book.dart';
import '../services/import_service.dart';
import '../services/recommended_book_service.dart';
import '../services/settings_service.dart';
import '../widgets/mode_select_sheet.dart';
import '../widgets/settings_sheet.dart';
import 'cloud_guide_page.dart';
import 'create_book_page.dart';
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

  // ===== 推荐词书相关 =====
  List<RecommendedBook>? _recommendedBooks; // null = 还没开始加载
  final Set<String> _addingBookUrls = {};
  Set<String> _addedUrls = {};

  // ===== 控制推荐展示 =====
  bool _hasEverAddedBook = false;
  bool _isRecommendedClosed = false;
  bool _useDaysOver7 = false;
  bool _manualShowRecommended = false;

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
      final cloudMap = await SettingsService.instance.getCloudBookMap();

      // 读取各类状态
      final hasEver = await SettingsService.instance.getHasEverAddedBook();
      final firstOpen = await SettingsService.instance.getFirstOpenTime();
      final isClosed = await SettingsService.instance.getRecommendedClosed();

      final now = DateTime.now();
      final days = now.difference(firstOpen).inDays;

      String? currentId;
      if (savedId != null && books.any((b) => b.book.id == savedId)) {
        currentId = savedId;
      } else if (books.isNotEmpty) {
        currentId = books.first.book.id;
        await SettingsService.instance.setCurrentWordBookId(currentId);
      } else {
        await SettingsService.instance.clearCurrentWordBookId();
      }

      // 只要列表里有词书，说明用户已经破冰了，标记为老手
      if (books.isNotEmpty && !hasEver) {
        await SettingsService.instance.setHasEverAddedBook();
        _hasEverAddedBook = true;
      } else {
        _hasEverAddedBook = hasEver;
      }

      if (!mounted) return;
      setState(() {
        _books = books;
        _currentBookId = currentId;
        _addedUrls = cloudMap.values.toSet();

        _isRecommendedClosed = isClosed;
        _useDaysOver7 = days >= 7;

        _loading = false;
        _error = null;
      });

      // 空状态且还没加载过推荐词书 → 去加载
      if (_books.isEmpty && _recommendedBooks == null) {
        _loadRecommendedBooks();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _loadRecommendedBooks() async {
    final cached = await RecommendedBookService.instance.getCached();
    if (!mounted) return;
    setState(() {
      _recommendedBooks = cached ?? RecommendedBookService.fallbackList;
    });

    final remote = await RecommendedBookService.instance.fetchRemote();
    if (!mounted) return;
    if (remote != null) {
      setState(() => _recommendedBooks = remote);
    }
  }

  // 用户主动关闭推荐
  Future<void> _closeRecommendations() async {
    await SettingsService.instance.setRecommendedClosed();
    if (!mounted) return;
    setState(() {
      _isRecommendedClosed = true;
      _manualShowRecommended = false; // 强制折叠
    });
  }

  Future<void> _onAddRecommendedBook(
      RecommendedBook book, {
        VoidCallback? onUpdate,
      }) async {
    if (_addingBookUrls.contains(book.url)) return;
    setState(() => _addingBookUrls.add(book.url));
    onUpdate?.call();

    try {
      final result = await ImportService.fetchFromUrl(book.url);
      if (result.error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败：${result.error}')),
        );
        return;
      }
      final words = result.words!;

      final newBookId = await AppDatabase.instance.insertImportedBook(
        name: book.name,
        source: WordBookSource.cloud,
        words: words,
      );
      await SettingsService.instance.setCloudUrlByBookId(newBookId, book.url);

      if (!mounted) return;
      await _load(silent: true);
      _iconToast(Icons.check);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _addingBookUrls.remove(book.url));
        onUpdate?.call();
      }
    }
  }

  // 展示推荐词书的底部面板
  void _showRecommendedSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (_recommendedBooks == null) {
              _loadRecommendedBooks().then((_) {
                if (sheetContext.mounted) setSheetState(() {});
              });
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final theme = Theme.of(context);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '为你推荐',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
                          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
                        ),
                      ),
                      child: Column(
                        children: _recommendedBooks!.map((book) {
                          return _buildRecommendedItem(
                            book,
                            onUpdate: () => setSheetState(() {}),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onBookTap(WordBookWithCount item) async {
    final words = await AppDatabase.instance.getWordsByBook(item.book.id);
    if (!mounted) return;

    if (words.isEmpty) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '词书为空',
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
          action: SnackBarAction(
            label: '去添加',
            textColor: theme.colorScheme.primary,
            onPressed: () => _onManageTap(item),
          ),
          width: 240,
        ),
      );
      return;
    }

    final mode = await ModeSelectSheet.show(context, sample: words.first);
    if (mode == null || !mounted) return;

    await SettingsService.instance.setCurrentWordBookId(item.book.id);
    setState(() => _currentBookId = item.book.id);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticePage(
          wordBookName: item.book.name,
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
                  '删除「${item.book.name}」？',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
      await AppDatabase.instance.deleteWordBook(item.book.id);

      if (_currentBookId == item.book.id) {
        await SettingsService.instance.clearCurrentWordBookId();
      }

      if (item.book.source == WordBookSource.cloud) {
        await SettingsService.instance.removeCloudUrlByBookId(item.book.id);
      }

      await _load(silent: true);
      _iconToast(Icons.check);
    } catch (e) {
      _iconToast(Icons.error_outline);
    }
  }

  Future<void> _onImportTap() async {
    if (_loading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _iconToast(Icons.error_outline);
        return;
      }

      final parsed = ImportService.parse(fileName: file.name, bytes: bytes);
      if (parsed.error != null || parsed.words.isEmpty) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(content: Text(parsed.error ?? '没有可导入的有效词条')),
        );
        return;
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            parsed.bookName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(
            '共 ${parsed.words.length} 条词条'
                '${parsed.skippedCount > 0 ? '，跳过 ${parsed.skippedCount} 条无效数据' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Icon(Icons.close),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Icon(Icons.check),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await AppDatabase.instance.insertImportedBook(
        name: parsed.bookName,
        source: parsed.source,
        words: parsed.words,
      );
      if (!mounted) return;
      await _load(silent: true);
      _iconToast(Icons.check);
    } catch (e) {
      _iconToast(Icons.error_outline);
    }
  }

  Future<void> _openCloudGuide() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CloudGuidePage()),
    );
    if (result == true && mounted) {
      await _load(silent: true);
      _iconToast(Icons.cloud_done_outlined);
    }
  }

  Future<void> _syncCloudBook(WordBookWithCount item) async {
    final url = await SettingsService.instance.getCloudUrlByBookId(item.book.id);
    if (url == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ImportService.fetchFromUrl(url);
      if (result.error != null) {
        throw Exception(result.error);
      }
      final words = result.words!;

      final newBookId = await AppDatabase.instance.replaceCloudBook(
        oldBookId: item.book.id,
        name: item.book.name,
        words: words,
      );

      await SettingsService.instance.removeCloudUrlByBookId(item.book.id);
      await SettingsService.instance.setCloudUrlByBookId(newBookId, url);

      if (!mounted) return;
      Navigator.pop(context);
      await _load(silent: true);
      _iconToast(Icons.check);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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
    return Listener(
      onPointerDown: (_) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => SettingsSheet.show(context),
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: '设置',
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: '添加词书',
              icon: const Icon(Icons.add_circle_outline),
              onSelected: (value) {
                if (value == 'local') {
                  _onImportTap();
                } else if (value == 'cloud') {
                  _openCloudGuide();
                } else if (value == 'manual') {
                  _onCreateTap();
                } else if (value == 'recommended') {
                  _showRecommendedSheet(); // 改为直接弹出面板
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'manual',
                  child: ListTile(
                    leading: Icon(Icons.edit_note),
                    title: Text('创建'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'cloud',
                  child: ListTile(
                    leading: Icon(Icons.cloud_download_outlined),
                    title: Text('云端'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'local',
                  child: ListTile(
                    leading: Icon(Icons.file_open_outlined),
                    title: Text('本地'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'recommended',
                  child: ListTile(
                    leading: Icon(Icons.auto_awesome_outlined),
                    title: Text('推荐'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildBody(),
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
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildBookCard(_books[index]),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final books = _recommendedBooks;

    // 展示推荐的条件：
    // 1. 没被用户手动关掉
    // 2. 且（没加过书 且 使用时间未满7天） 或者 用户主动点击了查看
    final isNewbie = !_hasEverAddedBook && !_useDaysOver7;
    final showRecommendations = !_isRecommendedClosed && (isNewbie || _manualShowRecommended);

    // ===== 1. 如果隐藏了推荐，让文字绝对居中 =====
    if (!showRecommendations) {
      return Center(
        child: Text(
          '还没有词书',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
      );
    }

    // ===== 2. 如果展示了推荐，保持原有顶部排版 =====
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '还没有词书',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 48),

          if (books == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '为你推荐',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                // 允许随时隐藏
                TextButton.icon(
                  onPressed: _closeRecommendations,
                  icon: Icon(
                    Icons.visibility_off_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  label: Text(
                    '隐藏',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: theme.colorScheme.outlineVariant, width: 0.5),
                  bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant, width: 0.5),
                ),
              ),
              child: Column(
                children: books.map((book) => _buildRecommendedItem(book)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendedItem(RecommendedBook book, {VoidCallback? onUpdate}) {
    final theme = Theme.of(context);
    final isAdded = _addedUrls.contains(book.url);
    final isAdding = _addingBookUrls.contains(book.url);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.name,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${book.description.replaceAll('英语四级考试词汇，', '')} · ${book.wordCount} 词',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildAddButton(
            book,
            isAdded: isAdded,
            isAdding: isAdding,
            onTap: onUpdate != null ? () => _onAddRecommendedBook(book, onUpdate: onUpdate) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(
      RecommendedBook book, {
        required bool isAdded,
        required bool isAdding,
        VoidCallback? onTap,
      }) {
    if (isAdded) {
      return TextButton(
        onPressed: null,
        child: const Text('已添加'),
      );
    }
    if (isAdding) {
      return const SizedBox(
        width: 56,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return FilledButton(
      onPressed: onTap ?? () => _onAddRecommendedBook(book),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      child: const Text('添加'),
    );
  }

  Widget _buildBookCard(WordBookWithCount item) {
    final theme = Theme.of(context);
    final isCloudBook = item.book.source == WordBookSource.cloud;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _onBookTap(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isCloudBook) ...[
                        Icon(Icons.cloud,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          item.book.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCloudBook)
                  IconButton(
                    tooltip: '从云端同步最新数据',
                    icon: const Icon(Icons.sync, size: 20),
                    color: theme.colorScheme.primary,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _syncCloudBook(item),
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
      ),
    );
  }
}