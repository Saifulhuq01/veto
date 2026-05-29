import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bridge/veto_method_channel.dart';
import 'blocked_apps_provider.dart';

/// Usage stats state — fetched from native UsageStatsManager via MethodChannel.
class UsageStatsState {
  const UsageStatsState({
    this.todayUsageMinutes = 0,
    this.focusMinutes = 0,
    this.blockedAppsCount = 0,
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
  UsageStatsNotifier(this._ref) : super(const UsageStatsState()) {
    _load();
  }

  final Ref _ref;
  final _channel = VetoMethodChannel();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final focusMins = prefs.getInt('veto_focus_minutes') ?? 0;
    state = state.copyWith(focusMinutes: focusMins);
    
    // Fetch live usage stats
    await refreshUsage();
    
    // Listen dynamically to blockedAppsProvider to compute blockedAppsCount
    _ref.listen<BlockedAppsState>(blockedAppsProvider, (previous, next) {
      final count = next.apps.where((a) => a.isBlocked).length;
      state = state.copyWith(blockedAppsCount: count);
    }, fireImmediately: true);
  }

  Future<void> refreshUsage() async {
    final minutes = await _channel.getTodayUsageMinutes();
    state = state.copyWith(todayUsageMinutes: minutes);
  }

  void updateUsage(int minutes) {
    state = state.copyWith(todayUsageMinutes: minutes);
  }

  Future<void> addFocusMinutes(int minutes) async {
    final newMins = state.focusMinutes + minutes;
    state = state.copyWith(focusMinutes: newMins);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('veto_focus_minutes', newMins);
  }

  void setBlockedAppsCount(int count) {
    state = state.copyWith(blockedAppsCount: count);
  }
}

final usageStatsProvider =
    StateNotifierProvider<UsageStatsNotifier, UsageStatsState>(
  (ref) => UsageStatsNotifier(ref),
);

