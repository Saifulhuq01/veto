import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../bridge/veto_method_channel.dart';

/// Rule Builder sheet — create custom deep block rules (target specific UI elements in apps).
class RuleBuilderSheet extends ConsumerStatefulWidget {
  const RuleBuilderSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const RuleBuilderSheet(),
    );
  }

  @override
  ConsumerState<RuleBuilderSheet> createState() => _RuleBuilderSheetState();
}

class _RuleBuilderSheetState extends ConsumerState<RuleBuilderSheet> {
  final _packageController = TextEditingController();
  final _patternController = TextEditingController();
  final List<String> _patterns = [];
  bool _isTestMode = false;
  List<Map<String, String>> _installedApps = [];
  bool _loadingApps = true;
  String? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await VetoMethodChannel().getInstalledApps();
    if (mounted) {
      setState(() {
        _installedApps = apps;
        _loadingApps = false;
      });
    }
  }

  @override
  void dispose() {
    _packageController.dispose();
    _patternController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
                'CREATE DEEP BLOCK RULE',
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
                'Block specific sections within apps by matching UI text.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),

              // Step 1: Select target app
              const Text(
                'STEP 1: TARGET APP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: VetoColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingApps)
                const Center(
                  child: CircularProgressIndicator(
                      color: VetoColors.secondary),
                )
              else
                GlassPanel(
                  borderRadius: 14,
                  blurSigma: 16,
                  fillOpacity: 0.04,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: DropdownButton<String>(
                    value: _selectedPackage,
                    hint: Text(
                      'Select an app',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF131319),
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: _installedApps.map((app) {
                      return DropdownMenuItem<String>(
                        value: app['packageName'],
                        child: Text(
                          app['appName'] ?? app['packageName'] ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedPackage = val),
                  ),
                ),
              const SizedBox(height: 20),

              // Step 2: Add text patterns
              const Text(
                'STEP 2: TEXT PATTERNS TO BLOCK',
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
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _patternController,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. "Shorts", "Reels", "Stories"',
                          hintStyle: TextStyle(
                              color: Colors.white
                                  .withValues(alpha: 0.3)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final pattern =
                            _patternController.text.trim();
                        if (pattern.isNotEmpty) {
                          setState(() {
                            _patterns.add(pattern);
                            _patternController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle,
                          color: VetoColors.secondary, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_patterns.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _patterns.map((p) {
                    return Chip(
                      label: Text(p,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      deleteIconColor: Colors.white54,
                      onDeleted: () =>
                          setState(() => _patterns.remove(p)),
                      backgroundColor: VetoColors.glassWhite10,
                      side: const BorderSide(
                          color: VetoColors.glassBorder),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // Step 3: Test mode toggle
              GlassPanel(
                borderRadius: 14,
                blurSigma: 16,
                fillOpacity: 0.03,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Test Mode (temporary)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isTestMode,
                      activeColor: Colors.amber,
                      onChanged: (val) =>
                          setState(() => _isTestMode = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              GlassButton(
                label: 'Save Rule',
                icon: Icons.save,
                onPressed: (_selectedPackage == null ||
                        _patterns.isEmpty)
                    ? null
                    : () async {
                        await VetoMethodChannel().setDeepBlockRule(
                          _selectedPackage!,
                          _patterns,
                          true,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Deep block rule saved for $_selectedPackage'),
                              backgroundColor:
                                  VetoColors.emeraldActive,
                            ),
                          );
                        }
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
}
