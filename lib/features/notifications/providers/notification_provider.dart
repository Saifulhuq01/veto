import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bridge/veto_method_channel.dart';

/// Notification preferences and scheduling.
class NotificationSettings {
  const NotificationSettings({
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 9,
    this.dailyReminderMinute = 0,
    this.streakWarningEnabled = true,
    this.usageNudgeEnabled = true,
    this.usageNudgeThresholdMinutes = 30,
    this.weeklySummaryEnabled = true,
  });

  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final bool streakWarningEnabled;
  final bool usageNudgeEnabled;
  final int usageNudgeThresholdMinutes;
  final bool weeklySummaryEnabled;

  Map<String, dynamic> toJson() => {
        'dailyReminderEnabled': dailyReminderEnabled,
        'dailyReminderHour': dailyReminderHour,
        'dailyReminderMinute': dailyReminderMinute,
        'streakWarningEnabled': streakWarningEnabled,
        'usageNudgeEnabled': usageNudgeEnabled,
        'usageNudgeThresholdMinutes': usageNudgeThresholdMinutes,
        'weeklySummaryEnabled': weeklySummaryEnabled,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? false,
        dailyReminderHour: json['dailyReminderHour'] as int? ?? 9,
        dailyReminderMinute: json['dailyReminderMinute'] as int? ?? 0,
        streakWarningEnabled: json['streakWarningEnabled'] as bool? ?? true,
        usageNudgeEnabled: json['usageNudgeEnabled'] as bool? ?? true,
        usageNudgeThresholdMinutes:
            json['usageNudgeThresholdMinutes'] as int? ?? 30,
        weeklySummaryEnabled: json['weeklySummaryEnabled'] as bool? ?? true,
      );

  NotificationSettings copyWith({
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? streakWarningEnabled,
    bool? usageNudgeEnabled,
    int? usageNudgeThresholdMinutes,
    bool? weeklySummaryEnabled,
  }) {
    return NotificationSettings(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      streakWarningEnabled: streakWarningEnabled ?? this.streakWarningEnabled,
      usageNudgeEnabled: usageNudgeEnabled ?? this.usageNudgeEnabled,
      usageNudgeThresholdMinutes:
          usageNudgeThresholdMinutes ?? this.usageNudgeThresholdMinutes,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
    );
  }

  String get reminderTimeDisplay {
    final h = dailyReminderHour.toString().padLeft(2, '0');
    final m = dailyReminderMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class NotificationNotifier extends StateNotifier<NotificationSettings> {
  NotificationNotifier()
      : super(const NotificationSettings()) {
    _load();
  }

  static const _prefsKey = 'veto_notification_settings';
  final _channel = VetoMethodChannel();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        state = NotificationSettings.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  Future<void> setDailyReminder(bool enabled,
      {int? hour, int? minute}) async {
    state = state.copyWith(
      dailyReminderEnabled: enabled,
      dailyReminderHour: hour,
      dailyReminderMinute: minute,
    );
    await _save();
    if (enabled) {
      await _channel.scheduleNotification(
        id: 1001,
        title: 'Time to Lock In 🔒',
        body: 'Start your focus session and protect your deep work.',
        hour: state.dailyReminderHour,
        minute: state.dailyReminderMinute,
        repeating: true,
      );
    } else {
      await _channel.cancelNotification(1001);
    }
  }

  Future<void> setStreakWarning(bool enabled) async {
    state = state.copyWith(streakWarningEnabled: enabled);
    await _save();
  }

  Future<void> setUsageNudge(bool enabled, {int? thresholdMinutes}) async {
    state = state.copyWith(
      usageNudgeEnabled: enabled,
      usageNudgeThresholdMinutes: thresholdMinutes,
    );
    await _save();
  }

  Future<void> setWeeklySummary(bool enabled) async {
    state = state.copyWith(weeklySummaryEnabled: enabled);
    await _save();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationSettings>(
  (ref) => NotificationNotifier(),
);
