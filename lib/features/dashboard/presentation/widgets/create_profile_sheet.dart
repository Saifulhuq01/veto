import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../providers/profiles_provider.dart';

/// Bottom sheet for creating a new custom focus profile.
class CreateProfileSheet extends ConsumerStatefulWidget {
  const CreateProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const CreateProfileSheet(),
    );
  }

  @override
  ConsumerState<CreateProfileSheet> createState() => _CreateProfileSheetState();
}

class _CreateProfileSheetState extends ConsumerState<CreateProfileSheet> {
  final _nameController = TextEditingController();
  int _selectedIconCode = 0xe3ae; // laptop_mac
  int _durationMinutes = 25;
  bool _enableDnd = false;

  static const _iconOptions = [
    _IconChoice(0xe3ae, 'Laptop', Icons.laptop_mac),
    _IconChoice(0xe332, 'Gym', Icons.fitness_center),
    _IconChoice(0xe431, 'Book', Icons.menu_book),
    _IconChoice(0xe51c, 'Night', Icons.nightlight_round),
    _IconChoice(0xe87c, 'Star', Icons.star),
    _IconChoice(0xe0cc, 'Music', Icons.music_note),
    _IconChoice(0xe3c9, 'Brush', Icons.brush),
    _IconChoice(0xe80e, 'Code', Icons.code),
    _IconChoice(0xef3d, 'Self', Icons.self_improvement),
    _IconChoice(0xe14f, 'Edit', Icons.edit),
    _IconChoice(0xe574, 'School', Icons.school),
    _IconChoice(0xe531, 'Coffee', Icons.coffee),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),
              const Text(
                'CREATE PROFILE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),

              // Name input
              GlassPanel(
                borderRadius: 14,
                blurSigma: 16,
                fillOpacity: 0.06,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Profile name',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.label_outline,
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon picker
              const Text(
                'ICON',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: VetoColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _iconOptions.map((opt) {
                  final isSelected = opt.code == _selectedIconCode;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIconCode = opt.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? VetoColors.secondary
                                .withValues(alpha: 0.2)
                            : VetoColors.glassWhite5,
                        border: Border.all(
                          color: isSelected
                              ? VetoColors.secondary
                              : VetoColors.glassBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        opt.icon,
                        color: isSelected
                            ? VetoColors.secondary
                            : Colors.white54,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Duration slider
              const Text(
                'DURATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: VetoColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              GlassPanel(
                borderRadius: 14,
                blurSigma: 16,
                fillOpacity: 0.04,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_durationMinutes minutes',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _formatDuration(_durationMinutes),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _durationMinutes.toDouble(),
                      min: 5,
                      max: 180,
                      divisions: 35,
                      activeColor: VetoColors.secondary,
                      inactiveColor:
                          VetoColors.secondary.withValues(alpha: 0.15),
                      onChanged: (val) =>
                          setState(() => _durationMinutes = val.round()),
                    ),
                  ],
                ),
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
                        color: Colors.white54, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Enable Do Not Disturb',
                        style: TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: _enableDnd,
                      activeColor: VetoColors.secondary,
                      onChanged: (val) =>
                          setState(() => _enableDnd = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save button
              GlassButton(
                label: 'Create Profile',
                icon: Icons.add,
                onPressed: _nameController.text.trim().isEmpty
                    ? null
                    : () {
                        final profile = FocusProfile(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: _nameController.text.trim(),
                          durationMinutes: _durationMinutes,
                          blockedPackages: const [],
                          enableDnd: _enableDnd,
                          iconCode: _selectedIconCode,
                        );
                        ref
                            .read(focusProfilesProvider.notifier)
                            .addProfile(profile);
                        Navigator.pop(context);
                      },
                isExpanded: true,
              ),
              const SizedBox(height: 12),
              GlassButton(
                label: 'Cancel',
                variant: GlassButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}

class _IconChoice {
  const _IconChoice(this.code, this.label, this.icon);
  final int code;
  final String label;
  final IconData icon;
}
