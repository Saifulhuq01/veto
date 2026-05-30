import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusProfile {
  const FocusProfile({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.blockedPackages,
    required this.enableDnd,
    required this.iconCode,
    this.isDefault = false,
    this.allowedPackages = const [],
  });

  final String id;
  final String name;
  final int durationMinutes;
  final List<String> blockedPackages;
  final bool enableDnd;
  final int iconCode; // IconData codePoint
  final bool isDefault;
  final List<String> allowedPackages;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'durationMinutes': durationMinutes,
        'blockedPackages': blockedPackages,
        'enableDnd': enableDnd,
        'iconCode': iconCode,
        'isDefault': isDefault,
        'allowedPackages': allowedPackages,
      };

  factory FocusProfile.fromJson(Map<String, dynamic> json) => FocusProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        durationMinutes: json['durationMinutes'] as int,
        blockedPackages:
            (json['blockedPackages'] as List<dynamic>).cast<String>(),
        enableDnd: json['enableDnd'] as bool? ?? false,
        iconCode: json['iconCode'] as int,
        isDefault: json['isDefault'] as bool? ?? false,
        allowedPackages: json['allowedPackages'] != null
            ? (json['allowedPackages'] as List<dynamic>).cast<String>()
            : const [],
      );

  FocusProfile copyWith({
    String? name,
    int? durationMinutes,
    List<String>? blockedPackages,
    bool? enableDnd,
    int? iconCode,
    List<String>? allowedPackages,
  }) {
    return FocusProfile(
      id: id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      blockedPackages: blockedPackages ?? this.blockedPackages,
      enableDnd: enableDnd ?? this.enableDnd,
      iconCode: iconCode ?? this.iconCode,
      isDefault: isDefault,
      allowedPackages: allowedPackages ?? this.allowedPackages,
    );
  }
}

class FocusProfilesState {
  const FocusProfilesState({
    required this.profiles,
    required this.selectedProfileId,
  });

  final List<FocusProfile> profiles;
  final String selectedProfileId;

  FocusProfile get selectedProfile {
    return profiles.firstWhere(
      (p) => p.id == selectedProfileId,
      orElse: () => profiles.first,
    );
  }
}

class FocusProfilesNotifier extends StateNotifier<FocusProfilesState> {
  FocusProfilesNotifier() : super(_initialState) {
    _load();
  }

  static const _defaultPackages = [
    'com.google.android.youtube',
    'com.instagram.android',
  ];

  static const _builtInProfiles = [
    FocusProfile(
      id: 'deep_work',
      name: 'Deep Work',
      durationMinutes: 45,
      blockedPackages: _defaultPackages,
      enableDnd: true,
      iconCode: 0xe3ae, // laptop_mac
      isDefault: true,
    ),
    FocusProfile(
      id: 'gym',
      name: 'Gym Focus',
      durationMinutes: 60,
      blockedPackages: ['com.instagram.android'],
      enableDnd: false,
      iconCode: 0xe332, // fitness_center
      isDefault: true,
    ),
    FocusProfile(
      id: 'study',
      name: 'Study',
      durationMinutes: 30,
      blockedPackages: _defaultPackages,
      enableDnd: true,
      iconCode: 0xe431, // menu_book
      isDefault: true,
    ),
    FocusProfile(
      id: 'night',
      name: 'Night Wind-Down',
      durationMinutes: 20,
      blockedPackages: _defaultPackages,
      enableDnd: true,
      iconCode: 0xe51c, // nightlight_round
      isDefault: true,
    ),
  ];

  static const _initialState = FocusProfilesState(
    profiles: _builtInProfiles,
    selectedProfileId: 'deep_work',
  );

  static const _prefsKey = 'veto_custom_profiles';
  static const _selectedKey = 'veto_selected_profile';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    final selectedId = prefs.getString(_selectedKey) ?? 'deep_work';

    List<FocusProfile> allProfiles = List.from(_builtInProfiles);

    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final custom = decoded
            .map((item) =>
                FocusProfile.fromJson(item as Map<String, dynamic>))
            .toList();
        allProfiles.addAll(custom);
      } catch (_) {}
    }

    state = FocusProfilesState(
      profiles: allProfiles,
      selectedProfileId: selectedId,
    );
  }

  Future<void> _saveCustomProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = state.profiles.where((p) => !p.isDefault).toList();
    final jsonStr = jsonEncode(custom.map((p) => p.toJson()).toList());
    await prefs.setString(_prefsKey, jsonStr);
  }

  Future<void> _saveSelectedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, state.selectedProfileId);
  }

  void selectProfile(String id) {
    state = FocusProfilesState(
      profiles: state.profiles,
      selectedProfileId: id,
    );
    _saveSelectedProfile();
  }

  Future<void> addProfile(FocusProfile profile) async {
    final updated = [...state.profiles, profile];
    state = FocusProfilesState(
      profiles: updated,
      selectedProfileId: state.selectedProfileId,
    );
    await _saveCustomProfiles();
  }

  Future<void> updateProfile(FocusProfile updated) async {
    final profiles = state.profiles.map((p) {
      if (p.id == updated.id) return updated;
      return p;
    }).toList();
    state = FocusProfilesState(
      profiles: profiles,
      selectedProfileId: state.selectedProfileId,
    );
    await _saveCustomProfiles();
  }

  Future<void> deleteProfile(String id) async {
    final profiles = state.profiles.where((p) => p.id != id).toList();
    final selectedId = state.selectedProfileId == id
        ? profiles.first.id
        : state.selectedProfileId;
    state = FocusProfilesState(
      profiles: profiles,
      selectedProfileId: selectedId,
    );
    await _saveCustomProfiles();
    if (state.selectedProfileId != selectedId) {
      await _saveSelectedProfile();
    }
  }
}

final focusProfilesProvider =
    StateNotifierProvider<FocusProfilesNotifier, FocusProfilesState>(
  (ref) => FocusProfilesNotifier(),
);

