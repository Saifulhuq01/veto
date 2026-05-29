import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bridge/veto_method_channel.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/glass_toggle.dart';
import '../../../core/widgets/glass_button.dart';
import '../providers/directives_provider.dart';
import '../../dashboard/providers/subscription_provider.dart';
import '../../../core/widgets/paywall_sheet.dart';


/// System Directives screen — configure app limits and deep blocking rules.
class DirectivesScreen extends ConsumerWidget {
  const DirectivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directives = ref.watch(directivesProvider);
    final masterEnabled = ref.watch(systemDirectivesEnabledProvider);
    final websitesEnabled = ref.watch(blockWebsitesEnabledProvider);
    final blockedSitesCount = ref.watch(blockedWebsitesProvider).length;
    final notificationsEnabled = ref.watch(blockNotificationsEnabledProvider);

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
            const SizedBox(height: 24),

            // ── Master Switch ──
            GlassPanel(
              borderRadius: 16,
              blurSigma: 32,
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable System Directives',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enforce persistent limits and deep blocks in the background.',
                          style: TextStyle(
                            fontSize: 12,
                            color: VetoColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GlassToggle(
                    value: masterEnabled,
                    onChanged: (val) {
                      ref.read(systemDirectivesEnabledProvider.notifier).toggle();
                    },
                  ),
                ],
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
                  onPressed: () {
                    final isPro = ref.read(subscriptionProvider);
                    final count = directives.appLimits.length;
                    if (!isPro && count >= 3) {
                      PaywallSheet.show(context, customMessage: 'Adding more than 3 app limits is a Veto Pro feature.');
                    } else {
                      _showAddLimitBottomSheet(context, ref);
                    }
                  },
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
                    subtitle: websitesEnabled
                        ? '$blockedSitesCount domains blocked'
                        : 'Blocked domains: disabled',
                    onTap: () {
                      final isPro = ref.read(subscriptionProvider);
                      if (!isPro) {
                        PaywallSheet.show(context, customMessage: 'Website blocking is a Veto Pro feature.');
                      } else {
                        _showBlockWebsitesBottomSheet(context, ref);
                      }
                    },
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
                    subtitle: 'Mute incoming alerts using native DND',
                    onTap: () => _toggleNotificationsBlocking(context, ref),
                    trailing: GlassToggle(
                      value: notificationsEnabled,
                      onChanged: (_) => _toggleNotificationsBlocking(context, ref),
                    ),
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

  void _showBlockWebsitesBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const _BlockWebsitesSheet(),
    );
  }

  Future<void> _toggleNotificationsBlocking(BuildContext context, WidgetRef ref) async {
    final hasAccess = await VetoMethodChannel().checkNotificationPolicyAccess();
    if (!context.mounted) return;
    if (hasAccess) {
      await ref.read(blockNotificationsEnabledProvider.notifier).toggle();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VetoColors.surface,
          title: const Text('Permission Required', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Veto needs "Do Not Disturb Access" permission to mute alerts and block notifications during focus times.',
            style: TextStyle(color: VetoColors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white30)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await VetoMethodChannel().requestNotificationPolicyAccess();
              },
              child: const Text('Grant Permission', style: TextStyle(color: VetoColors.secondary)),
            ),
          ],
        ),
      );
    }
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: limit.isActive ? VetoColors.fuchsiaTag : VetoColors.glassWhite5,
              border: Border.all(
                color: limit.isActive ? VetoColors.secondary.withValues(alpha: 0.5) : VetoColors.glassBorder,
              ),
            ),
            child: Icon(
              Icons.apps,
              color: limit.isActive ? Colors.white : Colors.white24,
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
                        color: limit.isActive ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w500,
                        decoration: limit.isActive ? null : TextDecoration.lineThrough,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  limit.limitDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: limit.isActive ? Colors.white.withValues(alpha: 0.5) : Colors.white24,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          GlassToggle(
            value: limit.isActive,
            onChanged: (_) {
              ref.read(directivesProvider.notifier).toggleAppLimit(limit.id);
            },
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VetoColors.glassWhite10,
              border: Border.all(color: VetoColors.glassBorder),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: VetoColors.error, size: 18),
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
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
              ] else ...[
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddLimitSheet extends ConsumerStatefulWidget {
  const _AddLimitSheet();

  @override
  ConsumerState<_AddLimitSheet> createState() => _AddLimitSheetState();
}

class _AddLimitSheetState extends ConsumerState<_AddLimitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  final _searchController = TextEditingController();

  List<Map<String, String>> _allApps = [];
  List<Map<String, String>> _filteredApps = [];
  Map<String, String>? _selectedApp;
  bool _isLoadingApps = true;
  bool _hasUsagePermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadApps();
  }

  Future<void> _checkPermissionAndLoadApps() async {
    setState(() => _isLoadingApps = true);
    final hasPerm = await VetoMethodChannel().checkUsageStatsPermission();
    setState(() => _hasUsagePermission = hasPerm);
    
    if (hasPerm) {
      final apps = await VetoMethodChannel().getInstalledApps();
      setState(() {
        _allApps = apps;
        _filteredApps = apps;
        _isLoadingApps = false;
      });
    } else {
      setState(() => _isLoadingApps = false);
    }
  }

  void _filterApps(String query) {
    setState(() {
      _filteredApps = _allApps
          .where((app) =>
              (app['appName'] ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _limitController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        margin: const EdgeInsets.only(top: 80),
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
              const SizedBox(height: 20),

              if (!_hasUsagePermission) ...[
                GlassPanel(
                  borderRadius: 12,
                  blurSigma: 16,
                  fillOpacity: 0.1,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: VetoColors.secondary),
                          SizedBox(width: 8),
                          Text(
                            'Permission Required',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Veto needs Usage Access permission to track and enforce daily application limits.',
                        style: TextStyle(fontSize: 12, color: VetoColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GlassButton(
                          label: 'Grant Usage Access',
                          onPressed: () async {
                            await VetoMethodChannel().requestUsageStatsPermission();
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (_isLoadingApps) ...[
                const SizedBox(
                  height: 250,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search installed apps...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VetoColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  onChanged: _filterApps,
                ),
                const SizedBox(height: 12),

                if (_selectedApp != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: VetoColors.fuchsiaTag,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: VetoColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apps, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _selectedApp!['appName']!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedApp = null),
                          child: const Icon(Icons.close, color: Colors.white54, size: 16),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: VetoColors.glassWhite5,
                        border: Border.all(color: VetoColors.glassBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filteredApps.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final isSelected = _selectedApp != null && _selectedApp!['packageName'] == app['packageName'];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(
                              app['appName']!,
                              style: TextStyle(
                                color: isSelected ? VetoColors.secondary : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              app['packageName']!,
                              style: const TextStyle(color: Colors.white30, fontSize: 10),
                            ),
                            trailing: isSelected ? const Icon(Icons.check, color: VetoColors.secondary, size: 16) : null,
                            onTap: () {
                              setState(() => _selectedApp = app);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                    if (_selectedApp == null) return 'Please select an application first';
                    if (val == null || val.isEmpty) return 'Please enter limit';
                    final parsed = int.tryParse(val);
                    if (parsed == null || parsed <= 0) return 'Please enter a valid positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

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
                          if (_formKey.currentState!.validate() && _selectedApp != null) {
                            final newLimit = AppLimitRule(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              appName: _selectedApp!['appName']!,
                              packageName: _selectedApp!['packageName']!,
                              dailyLimitMinutes: int.parse(_limitController.text),
                              isActive: true,
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
            ],
          ),
         ),
        ),
      ),
    );
  }
}

class _BlockWebsitesSheet extends ConsumerStatefulWidget {
  const _BlockWebsitesSheet();

  @override
  ConsumerState<_BlockWebsitesSheet> createState() => _BlockWebsitesSheetState();
}

class _BlockWebsitesSheetState extends ConsumerState<_BlockWebsitesSheet> {
  final _domainController = TextEditingController();

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEnabled = ref.watch(blockWebsitesEnabledProvider);
    final blockedSites = ref.watch(blockedWebsitesProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        margin: const EdgeInsets.only(top: 100),
        decoration: const BoxDecoration(
          color: Color(0xD905050A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: VetoColors.glassBorder, width: 1),
          ),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Block Websites',
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
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enforce Website Blocker',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Redirect browser views for blocked domains.',
                      style: TextStyle(color: VetoColors.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
                GlassToggle(
                  value: isEnabled,
                  onChanged: (val) {
                    ref.read(blockWebsitesEnabledProvider.notifier).toggle();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: VetoColors.glassBorder, height: 1),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _domainController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. facebook.com',
                      hintStyle: const TextStyle(color: Colors.white30),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: VetoColors.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    color: VetoColors.glassWhite15,
                    child: InkWell(
                      onTap: () {
                        final val = _domainController.text;
                        if (val.isNotEmpty) {
                          ref.read(blockedWebsitesProvider.notifier).addWebsite(val);
                          _domainController.clear();
                        }
                      },
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'BLOCKED DOMAINS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: VetoColors.glassWhite5,
                    border: Border.all(color: VetoColors.glassBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: blockedSites.isEmpty
                      ? const Center(
                          child: Text(
                            'No websites blocked.',
                            style: TextStyle(color: Colors.white24, fontSize: 12),
                          ),
                        )
                      : ListView.separated(
                          itemCount: blockedSites.length,
                          separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                          itemBuilder: (context, index) {
                            final domain = blockedSites[index];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(domain, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: VetoColors.error, size: 16),
                                onPressed: () {
                                  ref.read(blockedWebsitesProvider.notifier).removeWebsite(domain);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
       ),
      ),
    );
  }
}
