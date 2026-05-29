import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bridge/veto_method_channel.dart';

class BlockedApp {
  const BlockedApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.category, // 'education', 'entertainment', or 'other'
    required this.icon,
    this.isBlocked = false,
  });

  final String id;
  final String name;
  final String packageName;
  final String category;
  final IconData icon;
  final bool isBlocked;

  BlockedApp copyWith({bool? isBlocked}) {
    return BlockedApp(
      id: id,
      name: name,
      packageName: packageName,
      category: category,
      icon: icon,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

class BlockedAppsState {
  const BlockedAppsState({
    this.apps = const [],
    this.isLoading = true,
  });

  final List<BlockedApp> apps;
  final bool isLoading;

  BlockedAppsState copyWith({
    List<BlockedApp>? apps,
    bool? isLoading,
  }) {
    return BlockedAppsState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BlockedAppsNotifier extends StateNotifier<BlockedAppsState> {
  BlockedAppsNotifier(this._channel) : super(const BlockedAppsState()) {
    _initCatalog();
  }

  final VetoMethodChannel _channel;

  static const _defaultCatalog = [
    // Education / Productivity
    BlockedApp(
      id: 'classroom',
      name: 'Google Classroom',
      packageName: 'com.google.android.apps.classroom',
      category: 'education',
      icon: Icons.school,
    ),
    BlockedApp(
      id: 'duolingo',
      name: 'Duolingo',
      packageName: 'com.duolingo',
      category: 'education',
      icon: Icons.translate,
    ),
    BlockedApp(
      id: 'notion',
      name: 'Notion',
      packageName: 'com.mumentum.notion',
      category: 'education',
      icon: Icons.edit_note,
    ),
    BlockedApp(
      id: 'zoom',
      name: 'Zoom',
      packageName: 'us.zoom.videomeetings',
      category: 'education',
      icon: Icons.video_call,
    ),

    // Entertainment
    BlockedApp(
      id: 'youtube',
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      category: 'entertainment',
      icon: Icons.play_circle_filled,
    ),
    BlockedApp(
      id: 'netflix',
      name: 'Netflix',
      packageName: 'com.netflix.mediaclient',
      category: 'entertainment',
      icon: Icons.movie_creation_outlined,
    ),
    BlockedApp(
      id: 'spotify',
      name: 'Spotify',
      packageName: 'com.spotify.music',
      category: 'entertainment',
      icon: Icons.music_note,
    ),
    BlockedApp(
      id: 'tiktok',
      name: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      category: 'entertainment',
      icon: Icons.music_video,
    ),

    // Social / Other
    BlockedApp(
      id: 'instagram',
      name: 'Instagram',
      packageName: 'com.instagram.android',
      category: 'other',
      icon: Icons.camera_alt,
    ),
    BlockedApp(
      id: 'facebook',
      name: 'Facebook',
      packageName: 'com.facebook.katana',
      category: 'other',
      icon: Icons.facebook,
    ),
    BlockedApp(
      id: 'whatsapp',
      name: 'WhatsApp',
      packageName: 'com.whatsapp',
      category: 'other',
      icon: Icons.chat,
    ),
    BlockedApp(
      id: 'x_twitter',
      name: 'X (Twitter)',
      packageName: 'com.twitter.android',
      category: 'other',
      icon: Icons.alternate_email,
    ),
    BlockedApp(
      id: 'reddit',
      name: 'Reddit',
      packageName: 'com.reddit.frontpage',
      category: 'other',
      icon: Icons.reddit,
    ),
  ];

  /// Initialize the catalog and sync block states with native SharedPreferences
  Future<void> _initCatalog() async {
    final activeRules = await _channel.getActiveRules();

    final syncedApps = _defaultCatalog.map((app) {
      final nativeTargets = activeRules[app.packageName];
      // An app is blocked if there's a wildcard "*" in its rules
      final isBlocked = nativeTargets != null && nativeTargets.contains('*');
      return app.copyWith(isBlocked: isBlocked);
    }).toList();

    state = BlockedAppsState(apps: syncedApps, isLoading: false);
  }

  /// Toggle blocking for a specific app
  Future<void> toggleAppBlock(String id) async {
    final updated = state.apps.map((app) {
      if (app.id == id) {
        final newBlockState = !app.isBlocked;
        // Sync with native accessibility service rules
        _channel.setDeepBlockRule(
          app.packageName,
          ['*'], // Wildcard rules block the entire application
          newBlockState,
        );
        return app.copyWith(isBlocked: newBlockState);
      }
      return app;
    }).toList();

    state = state.copyWith(apps: updated);
  }

  /// Bulk update blocking state for a list of package names (e.g. from focus profiles)
  Future<void> applyProfileBlockedPackages(List<String> packages) async {
    final updated = state.apps.map((app) {
      final shouldBlock = packages.contains(app.packageName);
      if (app.isBlocked != shouldBlock) {
        _channel.setDeepBlockRule(
          app.packageName,
          ['*'],
          shouldBlock,
        );
        return app.copyWith(isBlocked: shouldBlock);
      }
      return app;
    }).toList();
    state = state.copyWith(apps: updated);
  }
}

final blockedAppsProvider =
    StateNotifierProvider<BlockedAppsNotifier, BlockedAppsState>(
  (ref) => BlockedAppsNotifier(VetoMethodChannel()),
);
