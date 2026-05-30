import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glass_button.dart';

/// Block screen theme options.
enum BlockScreenTheme {
  motivational('Motivational Quote', 'Inspirational quotes to keep you focused'),
  breathing('Breathing Exercise', 'Guided 3-breath exercise before redirect'),
  streakReminder('Streak Reminder', 'Shows your current streak count'),
  minimal('Minimal', 'Clean, distraction-free block message');

  const BlockScreenTheme(this.label, this.description);
  final String label;
  final String description;
}

/// Settings for the block overlay screen.
class BlockScreenSettings {
  const BlockScreenSettings({
    this.theme = BlockScreenTheme.motivational,
    this.customMessages = const {},
  });

  final BlockScreenTheme theme;
  final Map<String, String> customMessages; // packageName → custom message

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'customMessages': customMessages,
      };

  factory BlockScreenSettings.fromJson(Map<String, dynamic> json) {
    return BlockScreenSettings(
      theme: BlockScreenTheme.values.firstWhere(
        (t) => t.name == json['theme'],
        orElse: () => BlockScreenTheme.motivational,
      ),
      customMessages: json['customMessages'] != null
          ? Map<String, String>.from(json['customMessages'] as Map)
          : const {},
    );
  }
}

class BlockScreenNotifier extends StateNotifier<BlockScreenSettings> {
  BlockScreenNotifier() : super(const BlockScreenSettings()) {
    _load();
  }

  static const _prefsKey = 'veto_block_screen_settings';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        state = BlockScreenSettings.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  Future<void> setTheme(BlockScreenTheme theme) async {
    state = BlockScreenSettings(
      theme: theme,
      customMessages: state.customMessages,
    );
    await _save();
  }

  Future<void> setCustomMessage(
      String packageName, String message) async {
    final updated = Map<String, String>.from(state.customMessages);
    if (message.isEmpty) {
      updated.remove(packageName);
    } else {
      updated[packageName] = message;
    }
    state = BlockScreenSettings(
      theme: state.theme,
      customMessages: updated,
    );
    await _save();
  }
}

final blockScreenProvider =
    StateNotifierProvider<BlockScreenNotifier, BlockScreenSettings>(
  (ref) => BlockScreenNotifier(),
);

/// Block screen customizer UI — shown in settings/directives.
class BlockScreenCustomizer extends ConsumerWidget {
  const BlockScreenCustomizer({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const BlockScreenCustomizer(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(blockScreenProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFA05050A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: VetoColors.glassBorder, width: 1.5),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BLOCK SCREEN STYLE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customize what appears when a blocked app is opened.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            ...BlockScreenTheme.values.map((theme) {
              final isSelected = settings.theme == theme;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => ref
                      .read(blockScreenProvider.notifier)
                      .setTheme(theme),
                  child: GlassPanel(
                    borderRadius: 14,
                    blurSigma: 16,
                    fillOpacity: isSelected ? 0.1 : 0.04,
                    borderColor: isSelected
                        ? VetoColors.secondary
                            .withValues(alpha: 0.5)
                        : VetoColors.glassBorder,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? VetoColors.secondary
                              : Colors.white30,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                theme.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                theme.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.4),
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
            }),
            const SizedBox(height: 16),
            GlassButton(
              label: 'Done',
              variant: GlassButtonVariant.secondary,
              onPressed: () => Navigator.pop(context),
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }
}
