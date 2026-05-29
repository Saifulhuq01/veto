import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../bridge/veto_method_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'streak_provider.dart';
import 'usage_stats_provider.dart';

/// Immutable timer state — strictly no mutable fields.
class TimerState {
  const TimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    this.isRunning = false,
    this.isPaused = false,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isPaused;

  /// Factory for default Pomodoro timer.
  factory TimerState.initial() => const TimerState(
        remainingSeconds: AppConstants.defaultTimerSeconds,
        totalSeconds: AppConstants.defaultTimerSeconds,
      );

  TimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isPaused,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  /// Formatted display string: "MM:SS"
  String get display {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Progress ratio 0.0 → 1.0
  double get progress {
    if (totalSeconds == 0) return 0;
    return 1.0 - (remainingSeconds / totalSeconds);
  }

  /// Gentle wind-down state: last 10% of session or last 5 minutes (300 seconds)
  bool get isWindDown {
    if (!isRunning || isPaused || remainingSeconds <= 0) return false;
    final tenPercent = totalSeconds * 0.1;
    return remainingSeconds <= tenPercent || remainingSeconds <= 300;
  }
}

/// Timer StateNotifier — ticks at 1Hz. NOT 60fps.
///
/// This notifier only updates state once per second.
/// The consuming widget is surgically scoped via `select()` to rebuild
/// only the timer Text, never the glass panels.
///
/// PROCESS DEATH RESILIENCE:
/// On start(), we persist both the absolute end-time and the total duration
/// to SharedPreferences. On app re-launch, restoreIfNeeded() computes the
/// remaining seconds from the persisted end timestamp, so the lockdown
/// survives Android killing the Flutter engine under memory pressure.
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier(this._ref) : super(TimerState.initial());

  final Ref _ref;
  Timer? _timer;
  final _channel = VetoMethodChannel();

  /// Persist the lockdown end timestamp and total duration so the timer
  /// can be restored after process death.
  Future<void> _saveLockdownEndTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final endEpoch = DateTime.now().millisecondsSinceEpoch + (state.remainingSeconds * 1000);
      await prefs.setInt('lockdown_end_time', endEpoch);
      await prefs.setInt('lockdown_total_seconds', state.totalSeconds);
    } catch (_) {}
  }

  Future<void> _clearLockdownEndTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lockdown_end_time');
      await prefs.remove('lockdown_total_seconds');
    } catch (_) {}
  }

  /// Restore timer state after process death.
  /// Reads the persisted end-time, computes remaining seconds, and
  /// resumes the countdown if the session hasn't expired.
  Future<void> restoreIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final endEpoch = prefs.getInt('lockdown_end_time') ?? 0;
      if (endEpoch <= 0) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final remainingMs = endEpoch - now;

      if (remainingMs <= 0) {
        // Session expired while process was dead — clean up
        _channel.setLockdownActive(false);
        await prefs.remove('lockdown_end_time');
        await prefs.remove('lockdown_total_seconds');
        return;
      }

      final remainingSec = (remainingMs / 1000).ceil();
      final totalSec = prefs.getInt('lockdown_total_seconds') ?? remainingSec;

      state = TimerState(
        remainingSeconds: remainingSec,
        totalSeconds: totalSec,
        isRunning: false, // will be set to true by start()
        isPaused: false,
      );

      // Resume the countdown
      start();
    } catch (_) {
      // If restore fails, leave in default state — user can restart manually
    }
  }

  void start() {
    if (state.isRunning && !state.isPaused) return;

    state = state.copyWith(isRunning: true, isPaused: false);
    _channel.setLockdownActive(true);
    _saveLockdownEndTime();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 0) {
        _timer?.cancel();
        
        final completedMinutes = (state.totalSeconds / 60).ceil();
        
        state = state.copyWith(
          isRunning: false,
          isPaused: false,
          remainingSeconds: 0,
        );
        _channel.setLockdownActive(false);
        _clearLockdownEndTime();

        // Record completed focus session and increment streak
        _ref.read(streakProvider.notifier).recordFocusSession(completedMinutes);
        _ref.read(usageStatsProvider.notifier).addFocusMinutes(completedMinutes);
        return;
      }
      state = state.copyWith(
        remainingSeconds: state.remainingSeconds - 1,
      );
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
    _channel.setLockdownActive(false);
    _clearLockdownEndTime();
  }

  void resume() {
    if (!state.isPaused) return;
    start();
  }

  void reset() {
    _timer?.cancel();
    state = TimerState.initial();
    _channel.setLockdownActive(false);
    _clearLockdownEndTime();
  }

  void setDuration(int minutes) {
    _timer?.cancel();
    final seconds = minutes * 60;
    state = TimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: false,
      isPaused: false,
    );
    _channel.setLockdownActive(false);
    _clearLockdownEndTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Global provider — isolated from everything else.
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>(
  (ref) => TimerNotifier(ref),
);
