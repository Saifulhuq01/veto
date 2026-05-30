import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/glass_button.dart';
import '../providers/coins_provider.dart';

/// Rewards sheet — shows coin balance, daily challenge, streak multiplier, and shop preview.
class RewardsSheet extends ConsumerWidget {
  const RewardsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const RewardsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider);

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

            // Coin balance
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.monetization_on,
                        color: Colors.white, size: 36),
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(
                    '${coins.totalCoins}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms),
                  const Text(
                    'FOCUS COINS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: VetoColors.onSurfaceVariant,
                      letterSpacing: 2.0,
                    ),
                  ),
                  if (coins.todayEarned > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${coins.todayEarned} today',
                        style: const TextStyle(
                          fontSize: 12,
                          color: VetoColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Streak multiplier
            GlassPanel(
              borderRadius: 14,
              blurSigma: 16,
              fillOpacity: 0.06,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VetoColors.orbFuchsia
                          .withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.bolt,
                        color: VetoColors.orbFuchsia, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Streak Multiplier',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${coins.streakMultiplier}x coins per focus minute',
                          style: TextStyle(
                              color: Colors.white
                                  .withValues(alpha: 0.5),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${coins.streakMultiplier}x',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: VetoColors.orbFuchsia,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            const SizedBox(height: 12),

            // Daily challenge
            if (coins.dailyChallenge != null) ...[
              GlassPanel(
                borderRadius: 14,
                blurSigma: 16,
                fillOpacity: coins.dailyChallenge!.isCompleted ? 0.1 : 0.04,
                borderColor: coins.dailyChallenge!.isCompleted
                    ? VetoColors.secondary.withValues(alpha: 0.5)
                    : VetoColors.glassBorder,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: coins.dailyChallenge!.isCompleted
                            ? VetoColors.secondary
                                .withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        coins.dailyChallenge!.isCompleted
                            ? Icons.check_circle
                            : Icons.emoji_events,
                        color: coins.dailyChallenge!.isCompleted
                            ? VetoColors.secondary
                            : Colors.amber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'DAILY CHALLENGE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: VetoColors.onSurfaceVariant,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              if (coins.dailyChallenge!.isCompleted)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    '✓ DONE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: VetoColors.secondary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coins.dailyChallenge!.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            coins.dailyChallenge!.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '+${coins.dailyChallenge!.rewardCoins}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        const Text(
                          'coins',
                          style: TextStyle(
                            fontSize: 9,
                            color: VetoColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
            ],
            const SizedBox(height: 24),

            // Multiplier tiers info
            const Text(
              'MULTIPLIER TIERS',
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
              fillOpacity: 0.03,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _MultiplierTier(days: '3', multiplier: '1.5x', isActive: coins.streakMultiplier >= 1.5),
                  const SizedBox(height: 8),
                  _MultiplierTier(days: '7', multiplier: '2x', isActive: coins.streakMultiplier >= 2.0),
                  const SizedBox(height: 8),
                  _MultiplierTier(days: '14', multiplier: '3x', isActive: coins.streakMultiplier >= 3.0),
                  const SizedBox(height: 8),
                  _MultiplierTier(days: '30', multiplier: '5x', isActive: coins.streakMultiplier >= 5.0),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
            const SizedBox(height: 24),

            GlassButton(
              label: 'Close',
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

class _MultiplierTier extends StatelessWidget {
  const _MultiplierTier({
    required this.days,
    required this.multiplier,
    required this.isActive,
  });

  final String days;
  final String multiplier;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive ? VetoColors.secondary : Colors.white24,
          size: 16,
        ),
        const SizedBox(width: 10),
        Text(
          '$days day streak',
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
        const Spacer(),
        Text(
          multiplier,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? VetoColors.orbFuchsia : Colors.white38,
          ),
        ),
      ],
    );
  }
}
