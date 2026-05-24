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
  });

  final String id;
  final String appName;
  final String packageName;
  final int dailyLimitMinutes;
  final int usedMinutes;
  final String? iconUrl;

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
  }) {
    return AppLimitRule(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      iconUrl: iconUrl ?? this.iconUrl,
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
    appLimits: [
      AppLimitRule(
        id: 'instagram_limit',
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        dailyLimitMinutes: 90,
      ),
    ],
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
  }

  /// Delete an existing app limit
  Future<void> deleteAppLimit(String id) async {
    final updated = state.appLimits.where((l) => l.id != id).toList();
    state = state.copyWith(appLimits: updated);
    await _saveLimitsToPrefs(updated);
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
