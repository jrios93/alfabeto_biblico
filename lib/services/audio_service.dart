import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

class AudioPlaybackState {
  final String characterId;
  final int audioIndex;
  final bool isPlaying;

  AudioPlaybackState({
    required this.characterId,
    required this.audioIndex,
    required this.isPlaying,
  });
}

final audioPlaybackStateProvider =
    StateNotifierProvider<AudioPlaybackNotifier, AudioPlaybackState>((ref) {
  return AudioPlaybackNotifier();
});

class AudioPlaybackNotifier extends StateNotifier<AudioPlaybackState> {
  AudioPlaybackNotifier()
      : super(AudioPlaybackState(
            characterId: '', audioIndex: 0, isPlaying: false));

  void updateState(String characterId, int audioIndex, bool isPlaying) {
    state = AudioPlaybackState(
        characterId: characterId, audioIndex: audioIndex, isPlaying: isPlaying);
  }
}

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Ref _ref;

  AudioService(this._ref) {
    _audioPlayer.onPlayerComplete.listen((_) {
      _ref.read(audioPlaybackStateProvider.notifier).updateState(
          _ref.read(audioPlaybackStateProvider).characterId,
          _ref.read(audioPlaybackStateProvider).audioIndex,
          false);
    });
  }

  Future<void> playNextAudio(
      String characterId, List<String> audioFiles) async {
    final currentState = _ref.read(audioPlaybackStateProvider);

    if (currentState.characterId != characterId) {
      await _audioPlayer.stop();
      _ref
          .read(audioPlaybackStateProvider.notifier)
          .updateState(characterId, 0, false);
    }

    int nextIndex = (currentState.characterId == characterId)
        ? (currentState.audioIndex + 1) % audioFiles.length
        : 0;

    try {
      final String audioPath = audioFiles[nextIndex];
      print('Attempting to play audio: $audioPath');

      // Verificar si el asset existe
      try {
        final byteData = await rootBundle.load(audioPath);
        print('Asset found. Size: ${byteData.lengthInBytes} bytes');
      } catch (e) {
        print('Error loading asset: $e');
        throw Exception('Asset not found or invalid: $audioPath');
      }

      // Intentar establecer la fuente de audio
      try {
        // Eliminar el prefijo "assets/" para AssetSource
        String assetAudioPath = audioPath.startsWith('assets/')
            ? audioPath.substring(7)
            : audioPath;
        await _audioPlayer.setSource(AssetSource(assetAudioPath));
        print('Audio source set successfully');
      } catch (e) {
        print('Error setting audio source: $e');
        throw Exception('Failed to set audio source: $audioPath');
      }

      // Intentar reproducir el audio
      try {
        await _audioPlayer.resume();
        print('Audio playback started');
      } catch (e) {
        print('Error starting playback: $e');
        throw Exception('Failed to start audio playback: $audioPath');
      }

      _ref
          .read(audioPlaybackStateProvider.notifier)
          .updateState(characterId, nextIndex, true);
    } catch (e) {
      print('Error in playNextAudio: $e');
      _ref
          .read(audioPlaybackStateProvider.notifier)
          .updateState(characterId, nextIndex, false);
    }
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _ref.read(audioPlaybackStateProvider.notifier).updateState('', 0, false);
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    _ref.read(audioPlaybackStateProvider.notifier).updateState(
        _ref.read(audioPlaybackStateProvider).characterId,
        _ref.read(audioPlaybackStateProvider).audioIndex,
        false);
  }

  Future<void> resumeAudio() async {
    await _audioPlayer.resume();
    _ref.read(audioPlaybackStateProvider.notifier).updateState(
        _ref.read(audioPlaybackStateProvider).characterId,
        _ref.read(audioPlaybackStateProvider).audioIndex,
        true);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

final audioServiceProvider = Provider((ref) => AudioService(ref));
