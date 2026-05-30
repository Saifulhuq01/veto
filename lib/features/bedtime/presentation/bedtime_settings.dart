import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_toggle.dart';
import '../providers/bedtime_provider.dart';

/// Bedtime settings panel — configure scheduled screen blocking for sleep.
class BedtimeSettingsPanel extends ConsumerWidget {
  const BedtimeSettingsPanel({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const BedtimeSettingsPanel(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bedtime = ref.watch(bedtimeProvider);

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

            // Header
            const Center(
              child: Icon(Icons.bedtime, color: VetoColors.orbIndigo, size: 40),
            ),
            const SizedBox(height: 12),
            const Text(
              'BEDTIME MODE',
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
              'Block all apps during sleep hours.\nOnly essential apps remain accessible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Enable toggle
            GlassPanel(
              borderRadius: 14,
              blurSigma: 16,
              fillOpacity: bedtime.isEnabled ? 0.08 : 0.04,
              borderColor: bedtime.isEnabled
                  ? VetoColors.orbIndigo.withValues(alpha: 0.4)
                  : VetoColors.glassBorder,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.power_settings_new,
                      color: VetoColors.orbIndigo, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Enable Bedtime Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GlassToggle(
                    value: bedtime.isEnabled,
                    onChanged: (val) =>
                        ref.read(bedtimeProvider.notifier).setEnabled(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time window
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'START',
                    time: bedtime.startTimeDisplay,
                    icon: Icons.nightlight_round,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                            hour: bedtime.startHour,
                            minute: bedtime.startMinute),
                      );
                      if (picked != null) {
                        ref.read(bedtimeProvider.notifier).setStartTime(
                            picked.hour, picked.minute);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerTile(
                    label: 'END',
                    time: bedtime.endTimeDisplay,
                    icon: Icons.wb_sunny,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                            hour: bedtime.endHour,
                            minute: bedtime.endMinute),
                      );
                      if (picked != null) {
                        ref.read(bedtimeProvider.notifier).setEndTime(
                            picked.hour, picked.minute);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // DND toggle
            GlassPanel(
              borderRadius: 14,
              blurSigma: 16,
              fillOpacity: 0.04,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.do_not_disturb_on,
                      color: Colors.white54, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Enable DND during bedtime',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  GlassToggle(
                    value: bedtime.enableDnd,
                    onChanged: (val) =>
                        ref.read(bedtimeProvider.notifier).setDnd(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status indicator
            if (bedtime.isEnabled)
              GlassPanel(
                borderRadius: 14,
                blurSigma: 16,
                fillOpacity: bedtime.isCurrentlyActive ? 0.1 : 0.04,
                borderColor: bedtime.isCurrentlyActive
                    ? VetoColors.orbIndigo.withValues(alpha: 0.5)
                    : VetoColors.glassBorder,
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      bedtime.isCurrentlyActive
                          ? Icons.check_circle
                          : Icons.schedule,
                      color: bedtime.isCurrentlyActive
                          ? VetoColors.orbIndigo
                          : Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bedtime.isCurrentlyActive
                          ? 'Bedtime mode is active'
                          : 'Bedtime starts at ${bedtime.startTimeDisplay}',
                      style: TextStyle(
                        fontSize: 13,
                        color: bedtime.isCurrentlyActive
                            ? VetoColors.orbIndigo
                            : Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

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

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String time;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        borderRadius: 14,
        blurSigma: 16,
        fillOpacity: 0.04,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: VetoColors.orbIndigo, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: VetoColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
