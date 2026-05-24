import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/glass_toggle.dart';
import '../../../core/widgets/glass_button.dart';
import '../providers/directives_provider.dart';

/// System Directives screen — configure app limits and deep blocking rules.
class DirectivesScreen extends ConsumerWidget {
  const DirectivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directives = ref.watch(directivesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 104, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'System Directives',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure application limits and deep blocking rules.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 40),

            // ── Limits Section Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel(label: 'LIMITS'),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Add App Limit',
                  onPressed: () => _showAddLimitBottomSheet(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── App Limits List ──
            if (directives.appLimits.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                  borderRadius: 16,
                  blurSigma: 24,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No application limits configured.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              )
            else
              ...directives.appLimits.map((limit) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AppLimitCard(limit: limit),
                  )),

            const SizedBox(height: 32),

            // ── Deep Blocks Section ──
            const _SectionLabel(label: 'DEEP BLOCKS'),
            const SizedBox(height: 16),
            GlassPanel(
              borderRadius: 16,
              blurSigma: 48,
              child: Column(
                children: List.generate(directives.deepBlocks.length, (i) {
                  final rule = directives.deepBlocks[i];
                  final isLast = i == directives.deepBlocks.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                           children: [
                            // Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: VetoColors.glassWhite5,
                                border: Border.all(
                                  color: VetoColors.glassBorder,
                                ),
                              ),
                              child: Icon(
                                IconData(rule.iconData,
                                    fontFamily: 'MaterialIcons'),
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Label
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rule.featureName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rule.packageName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Toggle
                            GlassToggle(
                              value: rule.isActive,
                              onChanged: (_) {
                                ref
                                    .read(directivesProvider.notifier)
                                    .toggleDeepBlock(rule.id);
                              },
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 32),

            // ── Controls Section ──
            const _SectionLabel(label: 'CONTROLS'),
            const SizedBox(height: 16),
            GlassPanel(
              borderRadius: 16,
              blurSigma: 48,
              child: Column(
                children: [
                  _ControlRow(
                    icon: Icons.public,
                    label: 'Block Websites',
                    onTap: () {},
                  ),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.05),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _ControlRow(
                    icon: Icons.notifications_off,
                    label: 'Block Notifications',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLimitBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const _AddLimitSheet(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.7),
          letterSpacing: 2.0,
          height: 20 / 14,
        ),
      ),
    );
  }
}

class _AppLimitCard extends ConsumerWidget {
  const _AppLimitCard({required this.limit});
  final AppLimitRule limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassPanel(
      borderRadius: 16,
      blurSigma: 48,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // App icon placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VetoColors.glassWhite10,
              border: Border.all(color: VetoColors.glassBorder),
            ),
            child: const Icon(
              Icons.apps,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  limit.appName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  limit.limitDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          // Delete button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VetoColors.glassWhite10,
              border: Border.all(color: VetoColors.glassBorder),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: VetoColors.error, size: 20),
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(directivesProvider.notifier).deleteAppLimit(limit.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: VetoColors.glassWhite5,
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet to add a new app limit
class _AddLimitSheet extends ConsumerStatefulWidget {
  const _AddLimitSheet();

  @override
  ConsumerState<_AddLimitSheet> createState() => _AddLimitSheetState();
}

class _AddLimitSheetState extends ConsumerState<_AddLimitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _packageController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        margin: const EdgeInsets.only(top: 120),
        decoration: const BoxDecoration(
          color: Color(0xD905050A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: VetoColors.glassBorder, width: 1),
          ),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Limit Application',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // App Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'App Name',
                    labelStyle: const TextStyle(color: Colors.white60),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VetoColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter app name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Package Name
                TextFormField(
                  controller: _packageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Package Name',
                    labelStyle: const TextStyle(color: Colors.white60),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VetoColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter package name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Limit Minutes
                TextFormField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Daily Limit (minutes)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VetoColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter limit';
                    final parsed = int.tryParse(val);
                    if (parsed == null || parsed <= 0) return 'Please enter a valid positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Cancel',
                        variant: GlassButtonVariant.secondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        label: 'Apply Limit',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final newLimit = AppLimitRule(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              appName: _nameController.text,
                              packageName: _packageController.text,
                              dailyLimitMinutes: int.parse(_limitController.text),
                            );

                            ref.read(directivesProvider.notifier).addAppLimit(newLimit);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
