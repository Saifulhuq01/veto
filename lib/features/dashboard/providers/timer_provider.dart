import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../bridge/veto_method_channel.dart';

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
}

/// Timer StateNotifier — ticks at 1Hz. NOT 60fps.
///
/// This notifier only updates state once per second.
/// The consuming widget is surgically scoped via `select()` to rebuild
/// only the timer Text, never the glass panels.
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier() : super(TimerState.initial());

  Timer? _timer;
  final _channel = VetoMethodChannel();

  void start() {
    if (state.isRunning && !state.isPaused) return;

    state = state.copyWith(isRunning: true, isPaused: false);
    _channel.setLockdownActive(true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 0) {
        _timer?.cancel();
        state = state.copyWith(
          isRunning: false,
          isPaused: false,
          remainingSeconds: 0,
        );
        _channel.setLockdownActive(false);
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
  }

  void resume() {
    if (!state.isPaused) return;
    start();
  }

  void reset() {
    _timer?.cancel();
    state = TimerState.initial();
    _channel.setLockdownActive(false);
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Global provider — isolated from everything else.
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>(
  (ref) => TimerNotifier(),
);
