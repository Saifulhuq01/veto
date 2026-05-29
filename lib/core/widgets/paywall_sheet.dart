import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/veto_colors.dart';
import 'glass_panel.dart';
import 'glass_button.dart';
import '../../features/dashboard/providers/subscription_provider.dart';

class PaywallSheet extends ConsumerWidget {
  const PaywallSheet({super.key, this.customMessage});

  final String? customMessage;

  static Future<void> show(BuildContext context, {String? customMessage}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => PaywallSheet(customMessage: customMessage),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFA05050A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: VetoColors.glassBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
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

          // Glowing Crown
          const Center(
            child: Icon(
              Icons.workspace_premium,
              color: VetoColors.secondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),

          // Header
          const Text(
            'VETO PRO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            customMessage ?? 'Unlock the ultimate focus and productivity toolkit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Features List
          const GlassPanel(
            borderRadius: 18,
            blurSigma: 32,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _FeatureRow(
                  icon: Icons.dashboard_customize,
                  title: 'Unlimited Focus Profiles',
                  subtitle: 'Create profiles for Deep Work, Gym, Sleep, etc.',
                ),
                SizedBox(height: 16),
                _FeatureRow(
                  icon: Icons.vpn_lock,
                  title: 'Local VPN Website Blocker',
                  subtitle: 'Filter distracting URLs safely with local DNS proxy.',
                ),
                SizedBox(height: 16),
                _FeatureRow(
                  icon: Icons.bar_chart,
                  title: 'Weekly Focus Report',
                  subtitle: 'Inspect consecutive streaks and screen time saved.',
                ),
                SizedBox(height: 16),
                _FeatureRow(
                  icon: Icons.calendar_month,
                  title: 'Planner Calendar Scheduling',
                  subtitle: 'Auto-engage focus timer via scheduled alarms.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Pricing
          const Column(
            children: [
              Text(
                '₹149 / month',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Cancel anytime. 7-day money-back guarantee.',
                style: TextStyle(
                  fontSize: 12,
                  color: VetoColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          GlassButton(
            label: 'Unlock Veto Pro',
            color: VetoColors.secondaryContainer,
            onPressed: () async {
              await ref.read(subscriptionProvider.notifier).buyPro();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Veto Pro Activated! Enjoy full access.'),
                    backgroundColor: VetoColors.emeraldActive,
                  ),
                );
              }
            },
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VetoColors.secondary.withValues(alpha: 0.15),
            border: Border.all(
              color: VetoColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            icon,
            color: VetoColors.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: VetoColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
