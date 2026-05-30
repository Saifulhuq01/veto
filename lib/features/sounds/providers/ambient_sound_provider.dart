import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

/// Individual ambient sound with volume control.
class AmbientSound {
  const AmbientSound({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.assetPath,
    this.volume = 0.5,
    this.isPlaying = false,
  });

  final String id;
  final String name;
  final int iconCodePoint;
  final String assetPath;
  final double volume;
  final bool isPlaying;

  AmbientSound copyWith({double? volume, bool? isPlaying}) {
    return AmbientSound(
      id: id,
      name: name,
      iconCodePoint: iconCodePoint,
      assetPath: assetPath,
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
    _initPlayers();
  }

  static const _prefsAutoPlayKey = 'veto_ambient_autoplay';

  /// Audio players per sound ID.
  final Map<String, AudioPlayer> _players = {};

  static const _initialState = AmbientSoundState(
    sounds: [
      AmbientSound(id: 'rain', name: 'Rain', iconCodePoint: 0xe645, assetPath: 'assets/sounds/rain.mp3'),
      AmbientSound(id: 'forest', name: 'Forest', iconCodePoint: 0xea3a, assetPath: 'assets/sounds/forest.mp3'),
      AmbientSound(id: 'lofi', name: 'Lo-Fi', iconCodePoint: 0xe3a2, assetPath: 'assets/sounds/lofi.mp3'),
      AmbientSound(id: 'whitenoise', name: 'White Noise', iconCodePoint: 0xe40a, assetPath: 'assets/sounds/whitenoise.mp3'),
      AmbientSound(id: 'cafe', name: 'Café', iconCodePoint: 0xe541, assetPath: 'assets/sounds/cafe.mp3'),
      AmbientSound(id: 'ocean', name: 'Ocean', iconCodePoint: 0xf88a, assetPath: 'assets/sounds/ocean.mp3'),
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

  /// Initialize audio players for each sound.
  Future<void> _initPlayers() async {
    for (final sound in state.sounds) {
      try {
        final player = AudioPlayer();
        await player.setLoopMode(LoopMode.one);
        await player.setVolume(sound.volume);
        // Try to load asset — will fail gracefully if asset doesn't exist yet
        try {
          await player.setAsset(sound.assetPath);
        } catch (_) {
          // Asset not bundled yet — player ready for when assets are added
        }
        _players[sound.id] = player;
      } catch (_) {
        // Graceful degradation — UI still works, just no audio
      }
    }
  }

  Future<void> toggleSound(String id) async {
    final updatedSounds = state.sounds.map((s) {
      if (s.id == id) return s.copyWith(isPlaying: !s.isPlaying);
      return s;
    }).toList();

    state = state.copyWith(
      sounds: updatedSounds,
      isGloballyPlaying: updatedSounds.any((s) => s.isPlaying),
    );

    final sound = updatedSounds.firstWhere((s) => s.id == id);
    final player = _players[id];
    if (player != null) {
      if (sound.isPlaying) {
        try {
          await player.seek(Duration.zero);
          await player.play();
        } catch (_) {}
      } else {
        await player.pause();
      }
    }
  }

  Future<void> setVolume(String id, double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    final updatedSounds = state.sounds.map((s) {
      if (s.id == id) return s.copyWith(volume: clamped);
      return s;
    }).toList();

    state = state.copyWith(sounds: updatedSounds);
    final player = _players[id];
    if (player != null) {
      await player.setVolume(clamped);
    }
  }

  Future<void> applyPreset(SoundPreset preset) async {
    final updatedSounds = state.sounds.map((s) {
      final shouldPlay = preset.activeSoundIds.contains(s.id);
      return s.copyWith(isPlaying: shouldPlay);
    }).toList();

    state = state.copyWith(sounds: updatedSounds, isGloballyPlaying: true);

    for (final sound in updatedSounds) {
      final player = _players[sound.id];
      if (player == null) continue;
      if (sound.isPlaying) {
        try {
          await player.seek(Duration.zero);
          await player.play();
        } catch (_) {}
      } else {
        await player.pause();
      }
    }
  }

  Future<void> stopAll() async {
    final updatedSounds = state.sounds
        .map((s) => s.copyWith(isPlaying: false))
        .toList();
    state = state.copyWith(sounds: updatedSounds, isGloballyPlaying: false);

    for (final player in _players.values) {
      await player.pause();
    }
  }

  Future<void> startAutoPlay() async {
    if (!state.autoPlayOnLockdown) return;
    if (state.activeSoundCount == 0) {
      await applyPreset(presets.first);
    } else {
      state = state.copyWith(isGloballyPlaying: true);
      for (final sound in state.sounds) {
        if (sound.isPlaying) {
          final player = _players[sound.id];
          if (player != null) {
            try { await player.play(); } catch (_) {}
          }
        }
      }
    }
  }

  Future<void> setAutoPlay(bool enabled) async {
    state = state.copyWith(autoPlayOnLockdown: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsAutoPlayKey, enabled);
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }
}

final ambientSoundProvider =
    StateNotifierProvider<AmbientSoundNotifier, AmbientSoundState>(
  (ref) => AmbientSoundNotifier(),
);
