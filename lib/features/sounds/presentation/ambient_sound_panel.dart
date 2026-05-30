import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/glass_button.dart';
import '../providers/ambient_sound_provider.dart';

/// Ambient sound mixer panel — floating bottom sheet for mixing sounds during focus.
class AmbientSoundPanel extends ConsumerWidget {
  const AmbientSoundPanel({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const AmbientSoundPanel(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundState = ref.watch(ambientSoundProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
            // Drag handle
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
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AMBIENT SOUNDS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                if (soundState.isGloballyPlaying)
                  GestureDetector(
                    onTap: () =>
                        ref.read(ambientSoundProvider.notifier).stopAll(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: VetoColors.error.withValues(alpha: 0.15),
                        border: Border.all(
                            color: VetoColors.error.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Stop All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: VetoColors.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Preset buttons
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AmbientSoundNotifier.presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final preset = AmbientSoundNotifier.presets[i];
                  return GestureDetector(
                    onTap: () => ref
                        .read(ambientSoundProvider.notifier)
                        .applyPreset(preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: VetoColors.glassWhite5,
                        border: Border.all(
                            color: VetoColors.glassBorder),
                      ),
                      child: Text(
                        preset.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Sound list
            ...soundState.sounds.asMap().entries.map((entry) {
              final i = entry.key;
              final sound = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                  borderRadius: 14,
                  blurSigma: 16,
                  fillOpacity: sound.isPlaying ? 0.08 : 0.03,
                  borderColor: sound.isPlaying
                      ? VetoColors.secondary.withValues(alpha: 0.4)
                      : VetoColors.glassBorder,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref
                            .read(ambientSoundProvider.notifier)
                            .toggleSound(sound.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sound.isPlaying
                                ? VetoColors.secondary
                                    .withValues(alpha: 0.2)
                                : VetoColors.glassWhite5,
                          ),
                          child: Icon(
                            IconData(sound.iconCodePoint,
                                fontFamily: 'MaterialIcons'),
                            color: sound.isPlaying
                                ? VetoColors.secondary
                                : Colors.white38,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        sound.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: sound.isPlaying
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                      const Spacer(),
                      if (sound.isPlaying)
                        SizedBox(
                          width: 100,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5),
                              overlayShape:
                                  SliderComponentShape.noOverlay,
                              activeTrackColor: VetoColors.secondary,
                              inactiveTrackColor: VetoColors.secondary
                                  .withValues(alpha: 0.15),
                              thumbColor: VetoColors.secondary,
                            ),
                            child: Slider(
                              value: sound.volume,
                              onChanged: (val) => ref
                                  .read(ambientSoundProvider.notifier)
                                  .setVolume(sound.id, val),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: (50 * i).ms, duration: 200.ms),
              );
            }),
            const SizedBox(height: 8),

            // Auto-play toggle
            GlassPanel(
              borderRadius: 14,
              blurSigma: 16,
              fillOpacity: 0.03,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.white38, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Auto-play on lockdown',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Switch(
                    value: soundState.autoPlayOnLockdown,
                    activeColor: VetoColors.secondary,
                    onChanged: (val) => ref
                        .read(ambientSoundProvider.notifier)
                        .setAutoPlay(val),
                  ),
                ],
              ),
            ),
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
