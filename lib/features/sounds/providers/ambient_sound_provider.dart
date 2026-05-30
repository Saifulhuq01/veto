import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Individual ambient sound with volume control.
class AmbientSound {
  const AmbientSound({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.volume = 0.5,
    this.isPlaying = false,
  });

  final String id;
  final String name;
  final int iconCodePoint;
  final double volume;
  final bool isPlaying;

  AmbientSound copyWith({double? volume, bool? isPlaying}) {
    return AmbientSound(
      id: id,
      name: name,
      iconCodePoint: iconCodePoint,
      volume: volume ?? this.volume,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

/// Preset mix of sounds.
class SoundPreset {
  const SoundPreset({
    required this.name,
    required this.activeSoundIds,
  });

  final String name;
  final List<String> activeSoundIds;
}

class AmbientSoundState {
  const AmbientSoundState({
    required this.sounds,
    this.isGloballyPlaying = false,
    this.autoPlayOnLockdown = true,
  });

  final List<AmbientSound> sounds;
  final bool isGloballyPlaying;
  final bool autoPlayOnLockdown;

  AmbientSoundState copyWith({
    List<AmbientSound>? sounds,
    bool? isGloballyPlaying,
    bool? autoPlayOnLockdown,
  }) {
    return AmbientSoundState(
      sounds: sounds ?? this.sounds,
      isGloballyPlaying: isGloballyPlaying ?? this.isGloballyPlaying,
      autoPlayOnLockdown: autoPlayOnLockdown ?? this.autoPlayOnLockdown,
    );
  }

  int get activeSoundCount => sounds.where((s) => s.isPlaying).length;
}

class AmbientSoundNotifier extends StateNotifier<AmbientSoundState> {
  AmbientSoundNotifier() : super(_initialState) {
    _loadPrefs();
  }

  static const _prefsAutoPlayKey = 'veto_ambient_autoplay';

  static const _initialState = AmbientSoundState(
    sounds: [
      AmbientSound(id: 'rain', name: 'Rain', iconCodePoint: 0xe645), // water_drop
      AmbientSound(id: 'forest', name: 'Forest', iconCodePoint: 0xea3a), // forest
      AmbientSound(id: 'lofi', name: 'Lo-Fi', iconCodePoint: 0xe3a2), // headphones
      AmbientSound(id: 'whitenoise', name: 'White Noise', iconCodePoint: 0xe40a), // graphic_eq
      AmbientSound(id: 'cafe', name: 'Café', iconCodePoint: 0xe541), // coffee
      AmbientSound(id: 'ocean', name: 'Ocean', iconCodePoint: 0xf88a), // waves
    ],
  );

  static const presets = [
    SoundPreset(name: 'Deep Focus', activeSoundIds: ['rain', 'lofi']),
    SoundPreset(name: 'Nature', activeSoundIds: ['forest', 'rain']),
    SoundPreset(name: 'Café Study', activeSoundIds: ['cafe', 'lofi']),
    SoundPreset(name: 'Ocean Calm', activeSoundIds: ['ocean', 'whitenoise']),
  ];

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final autoPlay = prefs.getBool(_prefsAutoPlayKey) ?? true;
    state = state.copyWith(autoPlayOnLockdown: autoPlay);
  }

  void toggleSound(String id) {
    final updatedSounds = state.sounds.map((s) {
      if (s.id == id) {
        return s.copyWith(isPlaying: !s.isPlaying);
      }
      return s;
    }).toList();

    state = state.copyWith(
      sounds: updatedSounds,
      isGloballyPlaying: updatedSounds.any((s) => s.isPlaying),
    );
  }

  void setVolume(String id, double volume) {
    final updatedSounds = state.sounds.map((s) {
      if (s.id == id) {
        return s.copyWith(volume: volume.clamp(0.0, 1.0));
      }
      return s;
    }).toList();

    state = state.copyWith(sounds: updatedSounds);
  }

  void applyPreset(SoundPreset preset) {
    final updatedSounds = state.sounds.map((s) {
      final shouldPlay = preset.activeSoundIds.contains(s.id);
      return s.copyWith(isPlaying: shouldPlay);
    }).toList();

    state = state.copyWith(
      sounds: updatedSounds,
      isGloballyPlaying: true,
    );
  }

  void stopAll() {
    final updatedSounds = state.sounds
        .map((s) => s.copyWith(isPlaying: false))
        .toList();
    state = state.copyWith(sounds: updatedSounds, isGloballyPlaying: false);
  }

  void startAutoPlay() {
    if (!state.autoPlayOnLockdown) return;
    if (state.activeSoundCount == 0) {
      // Default: start rain + lofi
      applyPreset(presets.first);
    } else {
      state = state.copyWith(isGloballyPlaying: true);
    }
  }

  Future<void> setAutoPlay(bool enabled) async {
    state = state.copyWith(autoPlayOnLockdown: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsAutoPlayKey, enabled);
  }
}

final ambientSoundProvider =
    StateNotifierProvider<AmbientSoundNotifier, AmbientSoundState>(
  (ref) => AmbientSoundNotifier(),
);
