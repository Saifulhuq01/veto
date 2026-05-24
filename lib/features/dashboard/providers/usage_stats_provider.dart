import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Usage stats state — fetched from native UsageStatsManager via MethodChannel.
class UsageStatsState {
  const UsageStatsState({
    this.todayUsageMinutes = 0,
    this.focusMinutes = 0,
    this.blockedAppsCount = 8,
  });

  final int todayUsageMinutes;
  final int focusMinutes;
  final int blockedAppsCount;

  UsageStatsState copyWith({
    int? todayUsageMinutes,
    int? focusMinutes,
    int? blockedAppsCount,
  }) {
    return UsageStatsState(
      todayUsageMinutes: todayUsageMinutes ?? this.todayUsageMinutes,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      blockedAppsCount: blockedAppsCount ?? this.blockedAppsCount,
    );
  }

  /// Human-readable usage string.
  String get usageDisplay {
    final h = todayUsageMinutes ~/ 60;
    final m = todayUsageMinutes % 60;
    return '${h}h ${m}m';
  }

  /// Human-readable focus string.
  String get focusDisplay {
    if (focusMinutes == 0) return '0m';
    final h = focusMinutes ~/ 60;
    final m = focusMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class UsageStatsNotifier extends StateNotifier<UsageStatsState> {
  UsageStatsNotifier() : super(const UsageStatsState(todayUsageMinutes: 179));

  void updateUsage(int minutes) {
    state = state.copyWith(todayUsageMinutes: minutes);
  }

  void addFocusMinutes(int minutes) {
    state = state.copyWith(
      focusMinutes: state.focusMinutes + minutes,
    );
  }

  void setBlockedAppsCount(int count) {
    state = state.copyWith(blockedAppsCount: count);
  }
}

final usageStatsProvider =
    StateNotifierProvider<UsageStatsNotifier, UsageStatsState>(
  (ref) => UsageStatsNotifier(),
);
