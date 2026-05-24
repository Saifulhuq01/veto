import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';

/// Dart↔Kotlin MethodChannel bridge for Veto.
///
/// Handles:
/// - Deep block rule sync (toggle from UI → Kotlin AccessibilityService)
/// - Accessibility service status queries
/// - Usage stats fetching from UsageStatsManager
class VetoMethodChannel {
  static const _channel = MethodChannel(AppConstants.methodChannelName);

  /// Set or remove a deep block rule.
  /// The Kotlin side writes to SharedPreferences and broadcasts to the
  /// AccessibilityService to reload rules immediately.
  Future<void> setDeepBlockRule(
    String packageName,
    List<String> targets,
    bool enabled,
  ) async {
    try {
      await _channel.invokeMethod('setDeepBlockRule', {
        'packageName': packageName,
        'targets': targets,
        'enabled': enabled,
      });
    } on PlatformException catch (e) {
      // Graceful degradation — log but don't crash
      // In production, this goes to a crash reporting service
      print('VetoMethodChannel.setDeepBlockRule failed: ${e.message}');
    } on MissingPluginException {
      // Expected on platforms where the native side isn't registered yet
      print('VetoMethodChannel: native side not registered (expected on non-Android)');
    }
  }

  /// Get all currently active deep block rules from SharedPreferences.
  Future<Map<String, List<String>>> getActiveRules() async {
    try {
      final result = await _channel.invokeMethod<String>('getActiveRules');
      if (result == null || result.isEmpty) return {};
      final decoded = jsonDecode(result) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).cast<String>(),
        ),
      );
    } on PlatformException {
      return {};
    } on MissingPluginException {
      return {};
    }
  }

  /// Check if the AccessibilityService is currently enabled.
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isAccessibilityServiceEnabled',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Open the system Accessibility Settings screen.
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print('VetoMethodChannel.openAccessibilitySettings failed: ${e.message}');
    } on MissingPluginException {
      // no-op
    }
  }

  /// Notify native side whether lockdown (timer) is active.
  Future<void> setLockdownActive(bool active) async {
    try {
      await _channel.invokeMethod('setLockdownActive', {'active': active});
    } on PlatformException catch (e) {
      print('VetoMethodChannel.setLockdownActive failed: ${e.message}');
    } on MissingPluginException {
      // expected on non-Android
    }
  }

  /// Get today's total screen usage in minutes from UsageStatsManager.
  Future<int> getTodayUsageMinutes() async {
    try {
      final result = await _channel.invokeMethod<int>('getTodayUsageMinutes');
      return result ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }
}
