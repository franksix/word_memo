import 'package:flutter/material.dart';

import 'help/help_concept_page.dart';
import 'help/help_create_page.dart';
import 'help/help_cloud_page.dart';
import 'help/help_local_import_page.dart';
import 'help/help_practice_page.dart';

// ==========================================
// 目录页（从设置面板进入）
// ==========================================
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor =
    theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: 2,
    );

    return Scaffold(
      // 无 AppBar，整页延伸到屏幕上下边缘
      body: Column(
        children: [
          // 上半段：创建 | 云端（竖线从屏幕顶边下来）
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildCell(
                    context,
                    label: '创建',
                    style: labelStyle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpCreatePage(),
                      ),
                    ),
                  ),
                ),
                _vLine(lineColor),
                Expanded(
                  child: _buildCell(
                    context,
                    label: '云端',
                    style: labelStyle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpCloudPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _hLine(lineColor),

          // 理念：独占整行，无竖线，整行可点
          SizedBox(
            height: 120,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HelpConceptPage(),
                ),
              ),
              child: Center(
                child: Text('理念', style: labelStyle),
              ),
            ),
          ),

          _hLine(lineColor),

          // 下半段：本地 | 练习（竖线延伸到屏幕底边）
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildCell(
                    context,
                    label: '本地',
                    style: labelStyle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpLocalImportPage(),
                      ),
                    ),
                  ),
                ),
                _vLine(lineColor),
                Expanded(
                  child: _buildCell(
                    context,
                    label: '练习',
                    style: labelStyle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpPracticePage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 横线：左右贴屏留 12，两端渐隐
  Widget _hLine(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              color.withValues(alpha: 0),
              color,
              color,
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.12, 0.88, 1.0],
          ),
        ),
      ),
    );
  }

  // 竖线：上下两端贴近屏幕边缘时渐隐
  Widget _vLine(Color color) {
    return Container(
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0),
            color,
            color,
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.08, 0.92, 1.0],
        ),
      ),
    );
  }

  Widget _buildCell(
      BuildContext context, {
        required String label,
        required TextStyle? style,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(label, style: style),
      ),
    );
  }
}