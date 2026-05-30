import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bridge/veto_method_channel.dart';

/// Analytics data model for a single day.
class DailyRecord {
  const DailyRecord({
    required this.date,
    this.usageMinutes = 0,
    this.focusMinutes = 0,
    this.sessionsCompleted = 0,
  });

  final String date; // yyyy-MM-dd
  final int usageMinutes;
  final int focusMinutes;
  final int sessionsCompleted;

  Map<String, dynamic> toJson() => {
        'date': date,
        'usageMinutes': usageMinutes,
        'focusMinutes': focusMinutes,
        'sessionsCompleted': sessionsCompleted,
      };

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
        date: json['date'] as String,
        usageMinutes: json['usageMinutes'] as int? ?? 0,
        focusMinutes: json['focusMinutes'] as int? ?? 0,
        sessionsCompleted: json['sessionsCompleted'] as int? ?? 0,
      );

  DailyRecord copyWith({
    int? usageMinutes,
    int? focusMinutes,
    int? sessionsCompleted,
  }) {
    return DailyRecord(
      date: date,
      usageMinutes: usageMinutes ?? this.usageMinutes,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
    );
  }
}

class AnalyticsState {
  const AnalyticsState({
    this.dailyRecords = const [],
    this.isLoading = true,
  });

  final List<DailyRecord> dailyRecords;
  final bool isLoading;

  /// Get records for the last N days.
  List<DailyRecord> lastNDays(int n) {
    final now = DateTime.now();
    final records = <DailyRecord>[];
    for (int i = n - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = _formatDate(date);
      final existing = dailyRecords.where((r) => r.date == dateStr).toList();
      records.add(existing.isNotEmpty
          ? existing.first
          : DailyRecord(date: dateStr));
    }
    return records;
  }

  /// Total focus minutes across all recorded days.
  int get totalFocusMinutes =>
      dailyRecords.fold(0, (sum, r) => sum + r.focusMinutes);

  /// Total sessions across all recorded days.
  int get totalSessions =>
      dailyRecords.fold(0, (sum, r) => sum + r.sessionsCompleted);

  /// Best focus day in last 7 days.
  DailyRecord? get bestDayThisWeek {
    final week = lastNDays(7);
    if (week.every((r) => r.focusMinutes == 0)) return null;
    return week.reduce(
        (a, b) => a.focusMinutes >= b.focusMinutes ? a : b);
  }

  /// Average daily focus minutes (last 7 days).
  double get avgDailyFocus {
    final week = lastNDays(7);
    final total = week.fold(0, (sum, r) => sum + r.focusMinutes);
    return total / 7.0;
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(const AnalyticsState()) {
    _load();
  }

  static const _prefsKey = 'veto_analytics_records';
  final _channel = VetoMethodChannel();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);

    List<DailyRecord> records = [];
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        records = decoded
            .map((item) =>
                DailyRecord.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Fetch today's usage from native
    final todayUsage = await _channel.getTodayUsageMinutes();
    final today = _todayStr();
    final existingIdx = records.indexWhere((r) => r.date == today);
    if (existingIdx >= 0) {
      records[existingIdx] = records[existingIdx].copyWith(
        usageMinutes: todayUsage,
      );
    } else {
      records.add(DailyRecord(date: today, usageMinutes: todayUsage));
    }

    state = AnalyticsState(dailyRecords: records, isLoading: false);
    await _save();
  }

  /// Record a focus session completing.
  Future<void> recordSession(int focusMinutes) async {
    final today = _todayStr();
    final records = List<DailyRecord>.from(state.dailyRecords);
    final idx = records.indexWhere((r) => r.date == today);

    if (idx >= 0) {
      records[idx] = records[idx].copyWith(
        focusMinutes: records[idx].focusMinutes + focusMinutes,
        sessionsCompleted: records[idx].sessionsCompleted + 1,
      );
    } else {
      records.add(DailyRecord(
        date: today,
        focusMinutes: focusMinutes,
        sessionsCompleted: 1,
      ));
    }

    state = AnalyticsState(dailyRecords: records, isLoading: false);
    await _save();
  }

  /// Update today's screen usage from native.
  Future<void> refreshTodayUsage() async {
    final todayUsage = await _channel.getTodayUsageMinutes();
    final today = _todayStr();
    final records = List<DailyRecord>.from(state.dailyRecords);
    final idx = records.indexWhere((r) => r.date == today);

    if (idx >= 0) {
      records[idx] = records[idx].copyWith(usageMinutes: todayUsage);
    } else {
      records.add(DailyRecord(date: today, usageMinutes: todayUsage));
    }

    state = AnalyticsState(dailyRecords: records, isLoading: false);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr =
        jsonEncode(state.dailyRecords.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, jsonStr);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(),
);
