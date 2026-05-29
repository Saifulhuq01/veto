import 'package:flutter_riverpod/flutter_riverpod.dart';

class FocusProfile {
  const FocusProfile({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.blockedPackages,
    required this.enableDnd,
    required this.iconCode,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final List<String> blockedPackages;
  final bool enableDnd;
  final int iconCode; // IconData codePoint
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
  FocusProfilesNotifier() : super(_initialState);

  static const _defaultPackages = [
    'com.google.android.youtube',
    'com.instagram.android',
  ];

  static const _initialState = FocusProfilesState(
    profiles: [
      FocusProfile(
        id: 'deep_work',
        name: 'Deep Work',
        durationMinutes: 45,
        blockedPackages: _defaultPackages,
        enableDnd: true,
        iconCode: 0xe3ae, // laptop_mac
      ),
      FocusProfile(
        id: 'gym',
        name: 'Gym Focus',
        durationMinutes: 60,
        blockedPackages: ['com.instagram.android'],
        enableDnd: true,
        iconCode: 0xe244, // fitness_center
      ),
      FocusProfile(
        id: 'sleep',
        name: 'Gentle Sleep',
        durationMinutes: 30,
        blockedPackages: _defaultPackages,
        enableDnd: true,
        iconCode: 0xe0ed, // bed
      ),
      FocusProfile(
        id: 'quick_focus',
        name: 'Quick Focus',
        durationMinutes: 15,
        blockedPackages: _defaultPackages,
        enableDnd: false,
        iconCode: 0xe26f, // flash_on
      ),
    ],
    selectedProfileId: 'deep_work',
  );

  void selectProfile(String id) {
    state = FocusProfilesState(
      profiles: state.profiles,
      selectedProfileId: id,
    );
  }
}

final focusProfilesProvider =
    StateNotifierProvider<FocusProfilesNotifier, FocusProfilesState>((ref) {
  return FocusProfilesNotifier();
});
