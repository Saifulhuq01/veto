import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daily challenge model.
class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetMinutes,
    required this.rewardCoins,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String description;
  final int targetMinutes;
  final int rewardCoins;
  final bool isCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'targetMinutes': targetMinutes,
        'rewardCoins': rewardCoins,
        'isCompleted': isCompleted,
      };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        targetMinutes: json['targetMinutes'] as int,
        rewardCoins: json['rewardCoins'] as int,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class CoinsState {
  const CoinsState({
    this.totalCoins = 0,
    this.todayEarned = 0,
    this.dailyChallenge,
    this.streakMultiplier = 1.0,
    this.isLoading = true,
  });

  final int totalCoins;
  final int todayEarned;
  final DailyChallenge? dailyChallenge;
  final double streakMultiplier;
  final bool isLoading;

  CoinsState copyWith({
    int? totalCoins,
    int? todayEarned,
    DailyChallenge? dailyChallenge,
    double? streakMultiplier,
    bool? isLoading,
  }) {
    return CoinsState(
      totalCoins: totalCoins ?? this.totalCoins,
      todayEarned: todayEarned ?? this.todayEarned,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      streakMultiplier: streakMultiplier ?? this.streakMultiplier,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CoinsNotifier extends StateNotifier<CoinsState> {
  CoinsNotifier() : super(const CoinsState()) {
    _load();
  }

  static const _prefsCoinsKey = 'veto_total_coins';
  static const _prefsTodayKey = 'veto_coins_today';
  static const _prefsTodayDateKey = 'veto_coins_today_date';
  static const _prefsChallengeKey = 'veto_daily_challenge';
  static const _prefsChallengeDateKey = 'veto_challenge_date';

  static const _challengePool = [
    DailyChallenge(
      id: 'focus_30', title: 'Quick Focus',
      description: 'Focus for 30 minutes today', targetMinutes: 30, rewardCoins: 30,
    ),
    DailyChallenge(
      id: 'focus_60', title: 'Deep Work Session',
      description: 'Focus for 60 minutes today', targetMinutes: 60, rewardCoins: 75,
    ),
    DailyChallenge(
      id: 'focus_90', title: 'Marathon Focus',
      description: 'Focus for 90 minutes today', targetMinutes: 90, rewardCoins: 120,
    ),
    DailyChallenge(
      id: 'focus_120', title: 'Legendary Focus',
      description: 'Focus for 2 hours today', targetMinutes: 120, rewardCoins: 200,
    ),
    DailyChallenge(
      id: 'focus_45', title: 'Pomodoro Pro',
      description: 'Focus for 45 minutes today', targetMinutes: 45, rewardCoins: 50,
    ),
  ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt(_prefsCoinsKey) ?? 0;
    final today = _todayStr();

    // Reset daily counter if it's a new day
    final savedDate = prefs.getString(_prefsTodayDateKey) ?? '';
    int todayEarned = 0;
    if (savedDate == today) {
      todayEarned = prefs.getInt(_prefsTodayKey) ?? 0;
    } else {
      await prefs.setString(_prefsTodayDateKey, today);
      await prefs.setInt(_prefsTodayKey, 0);
    }

    // Load or generate daily challenge
    DailyChallenge? challenge;
    final challengeDate = prefs.getString(_prefsChallengeDateKey) ?? '';
    if (challengeDate == today) {
      final challengeJson = prefs.getString(_prefsChallengeKey);
      if (challengeJson != null) {
        try {
          challenge = DailyChallenge.fromJson(
              jsonDecode(challengeJson) as Map<String, dynamic>);
        } catch (_) {}
      }
    }

    if (challenge == null) {
      // Generate new daily challenge
      challenge = _challengePool[Random().nextInt(_challengePool.length)];
      await prefs.setString(_prefsChallengeDateKey, today);
      await prefs.setString(_prefsChallengeKey, jsonEncode(challenge.toJson()));
    }

    state = CoinsState(
      totalCoins: coins,
      todayEarned: todayEarned,
      dailyChallenge: challenge,
      isLoading: false,
    );
  }

  /// Calculate streak multiplier based on current streak count.
  double getMultiplier(int streakCount) {
    if (streakCount >= 30) return 5.0;
    if (streakCount >= 14) return 3.0;
    if (streakCount >= 7) return 2.0;
    if (streakCount >= 3) return 1.5;
    return 1.0;
  }

  /// Award coins for a completed focus session.
  Future<void> awardCoins(int focusMinutes, int streakCount) async {
    final multiplier = getMultiplier(streakCount);
    final earned = (focusMinutes * multiplier).round();

    final newTotal = state.totalCoins + earned;
    final newTodayEarned = state.todayEarned + earned;

    // Check daily challenge completion
    DailyChallenge? updatedChallenge = state.dailyChallenge;
    int challengeBonus = 0;
    if (updatedChallenge != null && !updatedChallenge.isCompleted) {
      final totalFocusToday = state.todayEarned + focusMinutes;
      if (totalFocusToday >= updatedChallenge.targetMinutes) {
        challengeBonus = updatedChallenge.rewardCoins;
        updatedChallenge = DailyChallenge(
          id: updatedChallenge.id,
          title: updatedChallenge.title,
          description: updatedChallenge.description,
          targetMinutes: updatedChallenge.targetMinutes,
          rewardCoins: updatedChallenge.rewardCoins,
          isCompleted: true,
        );
      }
    }

    state = state.copyWith(
      totalCoins: newTotal + challengeBonus,
      todayEarned: newTodayEarned,
      dailyChallenge: updatedChallenge,
      streakMultiplier: multiplier,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsCoinsKey, state.totalCoins);
    await prefs.setInt(_prefsTodayKey, state.todayEarned);
    if (updatedChallenge != null) {
      await prefs.setString(
          _prefsChallengeKey, jsonEncode(updatedChallenge.toJson()));
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final coinsProvider = StateNotifierProvider<CoinsNotifier, CoinsState>(
  (ref) => CoinsNotifier(),
);
