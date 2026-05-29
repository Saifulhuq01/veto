import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bridge/veto_method_channel.dart';

/// Deep block rule model.
class DeepBlockRule {
  const DeepBlockRule({
    required this.id,
    required this.featureName,
    required this.packageName,
    required this.nodeTexts,
    required this.iconData,
    this.isActive = false,
  });

  final String id;
  final String featureName;
  final String packageName;
  final List<String> nodeTexts;
  final int iconData; // IconData codePoint
  final bool isActive;

  DeepBlockRule copyWith({bool? isActive}) {
    return DeepBlockRule(
      id: id,
      featureName: featureName,
      packageName: packageName,
      nodeTexts: nodeTexts,
      iconData: iconData,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// App limit model.
class AppLimitRule {
  const AppLimitRule({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.dailyLimitMinutes,
    this.usedMinutes = 0,
    this.iconUrl,
    this.isActive = true,
  });

  final String id;
  final String appName;
  final String packageName;
  final int dailyLimitMinutes;
  final int usedMinutes;
  final String? iconUrl;
  final bool isActive;

  String get limitDisplay {
    final h = dailyLimitMinutes ~/ 60;
    final m = dailyLimitMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m daily limit';
    if (h > 0) return '${h}h daily limit';
    return '${m}m daily limit';
  }

  AppLimitRule copyWith({
    String? id,
    String? appName,
    String? packageName,
    int? dailyLimitMinutes,
    int? usedMinutes,
    String? iconUrl,
    bool? isActive,
  }) {
    return AppLimitRule(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'packageName': packageName,
      'dailyLimitMinutes': dailyLimitMinutes,
      'usedMinutes': usedMinutes,
      'iconUrl': iconUrl,
      'isActive': isActive,
    };
  }

  factory AppLimitRule.fromJson(Map<String, dynamic> json) {
    return AppLimitRule(
      id: json['id'] as String,
      appName: json['appName'] as String,
      packageName: json['packageName'] as String,
      dailyLimitMinutes: json['dailyLimitMinutes'] as int,
      usedMinutes: json['usedMinutes'] as int? ?? 0,
      iconUrl: json['iconUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Directives state — holds all limits and deep blocks.
class DirectivesState {
  const DirectivesState({
    this.appLimits = const [],
    this.deepBlocks = const [],
  });

  final List<AppLimitRule> appLimits;
  final List<DeepBlockRule> deepBlocks;

  DirectivesState copyWith({
    List<AppLimitRule>? appLimits,
    List<DeepBlockRule>? deepBlocks,
  }) {
    return DirectivesState(
      appLimits: appLimits ?? this.appLimits,
      deepBlocks: deepBlocks ?? this.deepBlocks,
    );
  }
}

class DirectivesNotifier extends StateNotifier<DirectivesState> {
  DirectivesNotifier(this._channel) : super(_initialState) {
    _init();
  }

  final VetoMethodChannel _channel;

  static const _initialState = DirectivesState(
    appLimits: [],
    deepBlocks: [
      DeepBlockRule(
        id: 'youtube_shorts',
        featureName: 'YouTube Shorts',
        packageName: 'com.google.android.youtube',
        nodeTexts: ['Shorts', 'shorts_pivot_header'],
        iconData: 0xe05d, // play_circle
        isActive: true,
      ),
      DeepBlockRule(
        id: 'instagram_reels',
        featureName: 'Instagram Reels',
        packageName: 'com.instagram.android',
        nodeTexts: ['Reels', 'reels_tab'],
        iconData: 0xe02c, // movie
        isActive: false,
      ),
    ],
  );

  /// Synchronize native deep blocks and load persistent limits on startup
  Future<void> _init() async {
    // 1. Load active deep block rules from native channel
    final activeNativeRules = await _channel.getActiveRules();

    final updatedDeepBlocks = state.deepBlocks.map((rule) {
      final nativeTargets = activeNativeRules[rule.packageName];
      // If rule exists in native rules, sync its UI status
      final isActive = nativeTargets != null && nativeTargets.isNotEmpty;
      return rule.copyWith(isActive: isActive);
    }).toList();

    // If native rules are empty (first install), seed default active ones
    if (activeNativeRules.isEmpty) {
      for (final rule in state.deepBlocks) {
        if (rule.isActive) {
          await _channel.setDeepBlockRule(rule.packageName, rule.nodeTexts, true);
        }
      }
    }

    // 2. Load app limits from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final limitsJson = prefs.getString('veto_app_limits');
    List<AppLimitRule> loadedLimits = state.appLimits;

    if (limitsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(limitsJson);
        loadedLimits = decoded.map((item) => AppLimitRule.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {
        // fallback
      }
    } else {
      await _saveLimitsToPrefs(state.appLimits);
    }

    state = DirectivesState(
      appLimits: loadedLimits,
      deepBlocks: updatedDeepBlocks,
    );

    // 3. Start services on initialization if enabled
    final systemDirectivesEnabled = prefs.getBool('veto_system_directives_enabled') ?? true;
    if (systemDirectivesEnabled) {
      await _channel.startForegroundService();
    }
    final blockWebsitesEnabled = prefs.getBool('veto_block_websites_enabled') ?? false;
    if (blockWebsitesEnabled) {
      final hasVpnPerm = await _channel.checkVpnPermission();
      if (hasVpnPerm) {
        await _channel.startVpnService();
      }
    }
  }

  /// Toggle a deep block rule and sync to native service.
  Future<void> toggleDeepBlock(String id) async {
    final updated = state.deepBlocks.map((rule) {
      if (rule.id == id) {
        return rule.copyWith(isActive: !rule.isActive);
      }
      return rule;
    }).toList();

    state = state.copyWith(deepBlocks: updated);

    // Sync to native Kotlin service via MethodChannel
    final activeRule = updated.firstWhere((r) => r.id == id);
    await _channel.setDeepBlockRule(
      activeRule.packageName,
      activeRule.nodeTexts,
      activeRule.isActive,
    );
  }

  /// Add a new app limit
  Future<void> addAppLimit(AppLimitRule limit) async {
    final updated = [...state.appLimits, limit];
    state = state.copyWith(appLimits: updated);
    await _saveLimitsToPrefs(updated);
    await _channel.triggerDirectivesReload();
  }

  /// Delete an existing app limit
  Future<void> deleteAppLimit(String id) async {
    final updated = state.appLimits.where((l) => l.id != id).toList();
    state = state.copyWith(appLimits: updated);
    await _saveLimitsToPrefs(updated);
    await _channel.triggerDirectivesReload();
  }

  /// Toggle an app limit rule active state
  Future<void> toggleAppLimit(String id) async {
    final updated = state.appLimits.map((limit) {
      if (limit.id == id) {
        return limit.copyWith(isActive: !limit.isActive);
      }
      return limit;
    }).toList();

    state = state.copyWith(appLimits: updated);
    await _saveLimitsToPrefs(updated);
    await _channel.triggerDirectivesReload();
  }

  Future<void> _saveLimitsToPrefs(List<AppLimitRule> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await prefs.setString('veto_app_limits', jsonStr);
  }
}

final directivesProvider =
    StateNotifierProvider<DirectivesNotifier, DirectivesState>(
  (ref) => DirectivesNotifier(VetoMethodChannel()),
);

/// StateProvider for Master System Directives Switch
final systemDirectivesEnabledProvider = StateNotifierProvider<SharedPreferencesBoolNotifier, bool>((ref) {
  return SharedPreferencesBoolNotifier('system_directives_enabled', true);
});

/// StateProvider for Website Blocking Enable/Disable Switch
final blockWebsitesEnabledProvider = StateNotifierProvider<SharedPreferencesBoolNotifier, bool>((ref) {
  return SharedPreferencesBoolNotifier('block_websites_enabled', false);
});

/// Strict Mode provider removed — anti-uninstall pattern violates Google Play policy.


/// StateProvider for Notification Blocking Enable/Disable Switch (DND Switch)
final blockNotificationsEnabledProvider = StateNotifierProvider<SharedPreferencesBoolNotifier, bool>((ref) {
  return SharedPreferencesBoolNotifier('block_notifications_enabled', false);
});

/// StateNotifier to save/load bools from SharedPreferences and notify native side
class SharedPreferencesBoolNotifier extends StateNotifier<bool> {
  SharedPreferencesBoolNotifier(this.prefKey, this.defaultValue) : super(defaultValue) {
    _load();
  }

  final String prefKey;
  final bool defaultValue;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('veto_$prefKey') ?? defaultValue;
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('veto_$prefKey', newValue);
    // Sync to SharedPreferences for access from Kotlin
    await prefs.setBool('flutter.$prefKey', newValue);
    
    // Handle services based on toggle type
    if (prefKey == 'system_directives_enabled') {
      if (newValue) {
        await VetoMethodChannel().startForegroundService();
      } else {
        await VetoMethodChannel().stopForegroundService();
      }
    } else if (prefKey == 'block_websites_enabled') {
      if (newValue) {
        final hasPerm = await VetoMethodChannel().checkVpnPermission();
        if (hasPerm) {
          await VetoMethodChannel().startVpnService();
        } else {
          final granted = await VetoMethodChannel().requestVpnPermission();
          if (granted) {
            await VetoMethodChannel().startVpnService();
          } else {
            // Permission denied: revert state
            state = false;
            await prefs.setBool('veto_$prefKey', false);
            await prefs.setBool('flutter.$prefKey', false);
            return;
          }
        }
      } else {
        await VetoMethodChannel().stopVpnService();
      }
    } else if (prefKey == 'block_notifications_enabled') {
      await VetoMethodChannel().setNotificationDND(newValue);
    }
    
    await VetoMethodChannel().triggerDirectivesReload();
  }
}

/// StateProvider for Blocked Websites List
final blockedWebsitesProvider = StateNotifierProvider<BlockedWebsitesNotifier, List<String>>((ref) {
  return BlockedWebsitesNotifier();
});

class BlockedWebsitesNotifier extends StateNotifier<List<String>> {
  BlockedWebsitesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('veto_blocked_websites');
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded.cast<String>();
      } catch (_) {}
    } else {
      // Seed default blocked websites
      state = ['facebook.com', 'tiktok.com', 'instagram.com', 'twitter.com', 'x.com'];
      await _save(state);
    }
  }

  Future<void> _save(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(list);
    await prefs.setString('veto_blocked_websites', jsonStr);
    await prefs.setString('flutter.blocked_websites', jsonStr);
  }

  Future<void> addWebsite(String domain) async {
    final clean = domain.trim().toLowerCase();
    if (clean.isEmpty || state.contains(clean)) return;
    final updated = [...state, clean];
    state = updated;
    await _save(updated);
    await VetoMethodChannel().triggerDirectivesReload();
  }

  Future<void> removeWebsite(String domain) async {
    final updated = state.where((d) => d != domain).toList();
    state = updated;
    await _save(updated);
    await VetoMethodChannel().triggerDirectivesReload();
  }
}
