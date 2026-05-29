import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../providers/timer_provider.dart';

class EmergencyBypassSheet extends ConsumerStatefulWidget {
  const EmergencyBypassSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const EmergencyBypassSheet(),
    );
  }

  @override
  ConsumerState<EmergencyBypassSheet> createState() => _EmergencyBypassSheetState();
}

class _EmergencyBypassSheetState extends ConsumerState<EmergencyBypassSheet> {
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _alreadyBypassedToday = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBypassLimit();
  }

  Future<void> _checkBypassLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(DateTime.now());
    final lastBypass = prefs.getString('veto_last_bypass_date') ?? '';

    setState(() {
      _alreadyBypassedToday = lastBypass == todayStr;
      _isLoading = false;
    });

    if (!_alreadyBypassedToday) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        setState(() {
          _remainingSeconds = 0;
        });
        _timer?.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  Future<void> _executeBypass() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(DateTime.now());
    await prefs.setString('veto_last_bypass_date', todayStr);

    // Reset lockdown timer
    ref.read(timerProvider.notifier).reset();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VetoColors.canvasBase.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
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

          // Title
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: VetoColors.error, size: 28),
              SizedBox(width: 12),
              Text(
                'Emergency Bypass',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: VetoColors.error)),
            )
          else if (_alreadyBypassedToday) ...[
            // Limit Exceeded State
            const Text(
              'Bypass Limit Reached',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: VetoColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can only use the emergency bypass once per day. To prevent self-sabotage, you cannot bypass this active focus session.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            GlassButton(
              label: 'Return to Focus',
              onPressed: () => Navigator.of(context).pop(),
              isExpanded: true,
            ),
          ] else ...[
            // Countdown State
            Text(
              'You are attempting to bypass your active focus lock. To discourage breaking your streak, a 60-second delay is enforced.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // Delay Display Circle
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VetoColors.error.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _remainingSeconds > 0
                        ? VetoColors.error.withValues(alpha: 0.3)
                        : VetoColors.error,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _remainingSeconds > 0 ? '${_remainingSeconds}s' : 'Ready',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds > 0
                          ? Colors.white.withValues(alpha: 0.9)
                          : VetoColors.error,
                    ),
                  ),
                ),
              ).animate(target: _remainingSeconds == 0 ? 1 : 0).shimmer(duration: 800.ms, color: Colors.white30).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.elasticOut, duration: 500.ms),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Cancel',
                    variant: GlassButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    label: _remainingSeconds > 0 ? 'Wait' : 'Confirm Bypass',
                    color: VetoColors.error,
                    onPressed: _remainingSeconds > 0 ? null : () => _executeBypass(),
                    isExpanded: true,
                  )
                  .animate(target: _remainingSeconds == 0 ? 1 : 0)
                  .shake(hz: 5, duration: 400.ms)
                  .then(delay: 5.seconds)
                  .shake(hz: 5, duration: 400.ms),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().slideY(begin: 0.25, end: 0, duration: 350.ms, curve: Curves.easeOutCubic).fadeIn(duration: 250.ms);
  }
}
