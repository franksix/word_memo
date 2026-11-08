import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../services/import_service.dart';
import '../theme/monet_theme.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportDoneResult {
  final String bookId;
  final String bookName;
  final int successCount;
  final int skippedCount;

  const _ImportDoneResult({
    required this.bookId,
    required this.bookName,
    required this.successCount,
    required this.skippedCount,
  });
}

class _ImportPageState extends State<ImportPage> {
  ImportParseResult? _parsed;
  _ImportDoneResult? _done;
  bool _busy = false;
  String? _error;

  Future<void> _pickFile() async {
    if (_busy) return;
    setState(() {
      _error = null;
      _done = null;
      _parsed = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'json', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _error = '无法读取文件内容');
        return;
      }

      setState(() => _busy = true);
      final parsed = ImportService.parse(fileName: file.name, bytes: bytes);

      if (!mounted) return;
      if (parsed.error != null) {
        setState(() {
          _busy = false;
          _error = parsed.error;
        });
        return;
      }
      setState(() {
        _busy = false;
        _parsed = parsed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '选择文件失败：$e';
      });
    }
  }

  Future<void> _confirmImport() async {
    final parsed = _parsed;
    if (parsed == null || _busy) return;
    if (parsed.words.isEmpty) {
      setState(() => _error = '没有可导入的有效词条');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final bookId = await AppDatabase.instance.insertImportedBook(
        name: parsed.bookName,
        source: parsed.source,
        words: parsed.words,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = _ImportDoneResult(
          bookId: bookId,
          bookName: parsed.bookName,
          successCount: parsed.words.length,
          skippedCount: parsed.skippedCount,
        );
        _parsed = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '导入失败：$e';
      });
    }
  }

  void _reset() {
    setState(() {
      _parsed = null;
      _done = null;
      _error = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 图标同步改为 file_open，成功页不显示
        title: _done == null ? const Icon(Icons.file_open_outlined) : null,
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_done != null) return _buildDone(_done!);
    if (_parsed != null) return _buildPreview(_parsed!);
    return _buildIdle();
  }

  Widget _statChip(IconData icon, String label, {Color? color}) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.file_open_outlined, size: 64),
        const SizedBox(height: 16),
        _buildFormatRow(Icons.table_chart_outlined,
            'CSV：首行表头 word,meaning，UTF-8'),
        _buildFormatRow(
            Icons.data_object, 'JSON：顶层数组，元素含 word 和 meaning'),
        _buildFormatRow(Icons.description_outlined,
            'TXT：每行 word,meaning，英文逗号分隔'),
        const SizedBox(height: 24),
        if (_error != null) _buildErrorCard(_error!),
        if (_error != null) const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _pickFile,
          child: const Icon(Icons.folder_open),
        ),
      ],
    );
  }

  Widget _buildFormatRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildPreview(ImportParseResult parsed) {
    final theme = Theme.of(context);
    final accents = theme.extension<MonetAccents>();
    final previewCount = parsed.words.length < 5 ? parsed.words.length : 5;
    final successColor = accents?.success ?? theme.colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parsed.fileName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statChip(
                      Icons.check_circle_outline,
                      '${parsed.words.length} 条',
                      color: successColor,
                    ),
                    if (parsed.skippedCount > 0)
                      _statChip(
                        Icons.remove_circle_outline,
                        '${parsed.skippedCount} 条',
                        color: theme.colorScheme.error,
                      ),
                    _statChip(
                      Icons.code,
                      parsed.source.dbValue.toUpperCase(),
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.book_outlined, parsed.bookName),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.visibility_outlined,
          '前 $previewCount 条',
          muted: true,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < previewCount; i++)
                ListTile(
                  dense: true,
                  leading: Text('${i + 1}'),
                  title: Text(parsed.words[i].word),
                  trailing: Text(parsed.words[i].meaning),
                ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildErrorCard(_error!),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _confirmImport,
          child: const Icon(Icons.check),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : _pickFile,
          child: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool muted = false}) {
    final theme = Theme.of(context);
    final color =
    muted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDone(_ImportDoneResult done) {
    final theme = Theme.of(context);
    final accents = theme.extension<MonetAccents>();
    final successColor = accents?.success ?? theme.colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 56,
              color: successColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            done.bookName,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _statChip(
              Icons.check_circle_outline,
              '${done.successCount} 条',
              color: successColor,
            ),
            if (done.skippedCount > 0)
              _statChip(
                Icons.remove_circle_outline,
                '${done.skippedCount} 条',
                color: theme.colorScheme.error,
              ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(Icons.home_outlined),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _reset,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}