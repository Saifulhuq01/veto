import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bridge/veto_method_channel.dart';

/// Bedtime mode settings.
class BedtimeSettings {
  const BedtimeSettings({
    this.isEnabled = false,
    this.startHour = 22,
    this.startMinute = 0,
    this.endHour = 7,
    this.endMinute = 0,
    this.allowedPackages = const [
      'com.google.android.dialer',
      'com.google.android.deskclock',
    ],
    this.enableDnd = true,
    this.showWindDownReminder = true,
    this.windDownMinutesBefore = 30,
  });

  final bool isEnabled;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<String> allowedPackages;
  final bool enableDnd;
  final bool showWindDownReminder;
  final int windDownMinutesBefore;

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'allowedPackages': allowedPackages,
        'enableDnd': enableDnd,
        'showWindDownReminder': showWindDownReminder,
        'windDownMinutesBefore': windDownMinutesBefore,
      };

  factory BedtimeSettings.fromJson(Map<String, dynamic> json) =>
      BedtimeSettings(
        isEnabled: json['isEnabled'] as bool? ?? false,
        startHour: json['startHour'] as int? ?? 22,
        startMinute: json['startMinute'] as int? ?? 0,
        endHour: json['endHour'] as int? ?? 7,
        endMinute: json['endMinute'] as int? ?? 0,
        allowedPackages: json['allowedPackages'] != null
            ? (json['allowedPackages'] as List<dynamic>).cast<String>()
            : const ['com.google.android.dialer', 'com.google.android.deskclock'],
        enableDnd: json['enableDnd'] as bool? ?? true,
        showWindDownReminder: json['showWindDownReminder'] as bool? ?? true,
        windDownMinutesBefore: json['windDownMinutesBefore'] as int? ?? 30,
      );

  BedtimeSettings copyWith({
    bool? isEnabled,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<String>? allowedPackages,
    bool? enableDnd,
    bool? showWindDownReminder,
    int? windDownMinutesBefore,
  }) {
    return BedtimeSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      allowedPackages: allowedPackages ?? this.allowedPackages,
      enableDnd: enableDnd ?? this.enableDnd,
      showWindDownReminder: showWindDownReminder ?? this.showWindDownReminder,
      windDownMinutesBefore: windDownMinutesBefore ?? this.windDownMinutesBefore,
    );
  }

  String get startTimeDisplay =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endTimeDisplay =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  /// Check if the current time falls within the bedtime window.
  bool get isCurrentlyActive {
    if (!isEnabled) return false;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes > endMinutes) {
      // Crosses midnight (e.g., 22:00 – 07:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }
}

class BedtimeNotifier extends StateNotifier<BedtimeSettings> {
  BedtimeNotifier() : super(const BedtimeSettings()) {
    _load();
  }

  static const _prefsKey = 'veto_bedtime_settings';
  final _channel = VetoMethodChannel();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        state = BedtimeSettings.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    await _save();
    if (enabled && state.showWindDownReminder) {
      // Schedule wind-down reminder
      final reminderHour = state.startHour;
      final reminderMinute = state.startMinute - state.windDownMinutesBefore;
      await _channel.scheduleNotification(
        id: 2001,
        title: 'Bedtime in ${state.windDownMinutesBefore} minutes 🌙',
        body: 'Time to start winding down. Put your phone away soon.',
        hour: reminderMinute < 0 ? reminderHour - 1 : reminderHour,
        minute: reminderMinute < 0 ? 60 + reminderMinute : reminderMinute,
        repeating: true,
      );
    } else {
      await _channel.cancelNotification(2001);
    }
  }

  Future<void> setStartTime(int hour, int minute) async {
    state = state.copyWith(startHour: hour, startMinute: minute);
    await _save();
  }

  Future<void> setEndTime(int hour, int minute) async {
    state = state.copyWith(endHour: hour, endMinute: minute);
    await _save();
  }

  Future<void> setDnd(bool enabled) async {
    state = state.copyWith(enableDnd: enabled);
    await _save();
  }

  Future<void> toggleAllowedPackage(String pkg) async {
    final current = List<String>.from(state.allowedPackages);
    if (current.contains(pkg)) {
      current.remove(pkg);
    } else {
      current.add(pkg);
    }
    state = state.copyWith(allowedPackages: current);
    await _save();
  }
}

final bedtimeProvider =
    StateNotifierProvider<BedtimeNotifier, BedtimeSettings>(
  (ref) => BedtimeNotifier(),
);
