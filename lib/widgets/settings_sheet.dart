import 'package:flutter/material.dart';
import '../main.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/app_themes.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _notifyEnabled = false;
  TimeOfDay _notifyTime = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await SettingsService.instance.getNotificationEnabled();
    final hour = await SettingsService.instance.getNotificationHour();
    final minute = await SettingsService.instance.getNotificationMinute();
    if (!mounted) return;
    setState(() {
      _notifyEnabled = enabled;
      _notifyTime = TimeOfDay(hour: hour, minute: minute);
      _loading = false;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要通知权限才能使用提醒功能')),
        );
        return;
      }
      final success = await NotificationService.instance.scheduleDailyReminder(
        hour: _notifyTime.hour,
        minute: _notifyTime.minute,
      );
      if (success) {
        await SettingsService.instance.setNotificationEnabled(true);
        await SettingsService.instance.setNotificationHour(_notifyTime.hour);
        await SettingsService.instance.setNotificationMinute(_notifyTime.minute);
        setState(() => _notifyEnabled = true);
      }
    } else {
      await NotificationService.instance.cancelDailyReminder();
      await SettingsService.instance.setNotificationEnabled(false);
      setState(() => _notifyEnabled = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifyTime,
    );
    if (picked != null && picked != _notifyTime) {
      setState(() => _notifyTime = picked);
      if (_notifyEnabled) {
        await NotificationService.instance.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
        await SettingsService.instance.setNotificationHour(picked.hour);
        await SettingsService.instance.setNotificationMinute(picked.minute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 主题模式（深浅） ---
            Row(
              children: [
                Icon(Icons.brightness_6_outlined,
                    size: 24, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('显示模式', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, currentMode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto)),
                    ButtonSegment(
                        value: ThemeMode.light, icon: Icon(Icons.light_mode)),
                    ButtonSegment(
                        value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {currentMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<ThemeMode> newSelection) async {
                    final mode = newSelection.first;
                    themeModeNotifier.value = mode;
                    final modeStr = switch (mode) {
                      ThemeMode.light => 'light',
                      ThemeMode.dark => 'dark',
                      _ => 'system',
                    };
                    await SettingsService.instance.setThemeMode(modeStr);
                  },
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- 配色风格 ---
            Row(
              children: [
                Icon(Icons.palette_outlined,
                    size: 24, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('主题配色', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<AppThemeStyle>(
              valueListenable: themeStyleNotifier,
              builder: (context, currentStyle, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorDot(AppThemeStyle.monet, const Color(0xFF4A7A73)),
                    _buildColorDot(AppThemeStyle.paper, const Color(0xFF8B6D50)),
                    _buildColorDot(
                        AppThemeStyle.glacier, const Color(0xFF45526B)),
                    _buildColorDot(AppThemeStyle.peach, const Color(0xFF8C6A6A)),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- 提醒设置 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active_outlined,
                        size: 24, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('每日提醒', style: theme.textTheme.titleMedium),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_notifyEnabled)
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          child: Text(
                            _notifyTime.format(context),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Switch(
                      value: _notifyEnabled,
                      onChanged: _toggleNotification,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 删除了 label 参数和底部的 Text 组件
  Widget _buildColorDot(AppThemeStyle style, Color color) {
    return ValueListenableBuilder<AppThemeStyle>(
      valueListenable: themeStyleNotifier,
      builder: (context, currentStyle, _) {
        final isSelected = currentStyle == style;
        return GestureDetector(
          onTap: () async {
            themeStyleNotifier.value = style;
            final styleStr = style.name;
            await SettingsService.instance.setThemeStyle(styleStr);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      },
    );
  }
}