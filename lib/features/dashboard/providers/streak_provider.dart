import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakState {
  const StreakState({
    required this.streakCount,
    required this.lastFocusDate,
    required this.weeklyHistory, // Map of day -> minutes
  });

  final int streakCount;
  final String lastFocusDate; // yyyy-MM-dd
  final Map<String, int> weeklyHistory;

  factory StreakState.initial() => const StreakState(
        streakCount: 0,
        lastFocusDate: '',
        weeklyHistory: {
          'Mon': 0,
          'Tue': 0,
          'Wed': 0,
          'Thu': 0,
          'Fri': 0,
          'Sat': 0,
          'Sun': 0,
        },
      );

  StreakState copyWith({
    int? streakCount,
    String? lastFocusDate,
    Map<String, int>? weeklyHistory,
  }) {
    return StreakState(
      streakCount: streakCount ?? this.streakCount,
      lastFocusDate: lastFocusDate ?? this.lastFocusDate,
      weeklyHistory: weeklyHistory ?? this.weeklyHistory,
    );
  }
}

class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier() : super(StreakState.initial()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('veto_streak_count') ?? 0;
    final date = prefs.getString('veto_last_focus_date') ?? '';
    final historyStr = prefs.getString('veto_focus_history');
    
    Map<String, int> history = Map.from(state.weeklyHistory);
    if (historyStr != null) {
      try {
        final decoded = jsonDecode(historyStr) as Map<String, dynamic>;
        history = decoded.map((key, val) => MapEntry(key, val as int));
      } catch (_) {}
    } else {
      // Start with a clean history on first open
      history = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };
      await _saveHistory(history);
    }

    state = StreakState(
      streakCount: count,
      lastFocusDate: date,
      weeklyHistory: history,
    );
  }

  Future<void> recordFocusSession(int durationMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _formatDate(now);

    // 1. Calculate new streak count
    int newStreak = state.streakCount;
    if (state.lastFocusDate.isEmpty) {
      newStreak = 1;
    } else if (state.lastFocusDate == todayStr) {
      // Already focused today, streak remains same
    } else {
      final lastDate = DateTime.parse(state.lastFocusDate);
      final difference = now.difference(lastDate).inDays;
      if (difference == 1) {
        newStreak = state.streakCount + 1;
      } else if (difference > 1) {
        newStreak = 1; // Streak broken
      }
    }

    // 2. Log minutes into weekly history
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentDayName = weekdayNames[now.weekday - 1];
    
    final updatedHistory = Map<String, int>.from(state.weeklyHistory);
    updatedHistory[currentDayName] = (updatedHistory[currentDayName] ?? 0) + durationMinutes;

    state = StreakState(
      streakCount: newStreak,
      lastFocusDate: todayStr,
      weeklyHistory: updatedHistory,
    );

    // 3. Persist
    await prefs.setInt('veto_streak_count', newStreak);
    await prefs.setString('veto_last_focus_date', todayStr);
    await _saveHistory(updatedHistory);
  }

  Future<void> _saveHistory(Map<String, int> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('veto_focus_history', jsonEncode(history));
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier();
});
