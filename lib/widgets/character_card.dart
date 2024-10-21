import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bible_character.dart';
import '../services/audio_service.dart';

class CharacterCard extends ConsumerWidget {
  final BibleCharacter character;
  final Color cardColor;

  const CharacterCard({
    super.key,
    required this.character,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    final audioState = ref.watch(audioPlaybackStateProvider);
    final isCurrentCharacter = audioState.characterId == character.letter;

    return GestureDetector(
      onTap: () => _playNextAudio(audioService),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: cardColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fontSize = constraints.maxWidth * 0.3;
            return Stack(
              children: [
                _buildLetterText(fontSize),
                _buildCharacterImage(constraints),
                _buildAudioControls(isCurrentCharacter, audioState, fontSize),
                _buildProgressIndicator(isCurrentCharacter, audioState),
              ],
            );
          },
        ),
      ),
    );
  }

  void _playNextAudio(AudioService audioService) {
    final allAudios = [character.letterAudio, ...character.nameAudios];
    audioService.playNextAudio(character.letter, allAudios);
  }

  String _removeAssetPrefix(String path) {
    return path.startsWith('assets/') ? path.substring(7) : path;
  }

  Widget _buildLetterText(double fontSize) {
    return Positioned(
      left: 10,
      top: 10,
      child: Text(
        character.letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              blurRadius: 2.0,
              color: Colors.black,
              offset: Offset(1.0, 1.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterImage(BoxConstraints constraints) {
    return Positioned(
      right: 10,
      bottom: 10,
      child: Image.asset(
        character.image,
        fit: BoxFit.contain,
        height: constraints.maxHeight * 0.6,
        semanticLabel: 'Image of ${character.letter}',
      ),
    );
  }

  Widget _buildAudioControls(
      bool isCurrentCharacter, AudioPlaybackState audioState, double fontSize) {
    return Positioned(
      right: 10,
      top: 10,
      child: Row(
        children: [
          if (isCurrentCharacter && audioState.isPlaying)
            Icon(
              Icons.volume_up,
              color: Colors.white,
              size: fontSize * 0.5,
              semanticLabel: 'Audio playing',
            )
          else
            Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: fontSize * 0.5,
              semanticLabel: 'Play audio',
            ),
          if (isCurrentCharacter)
            Text(
              ' ${audioState.audioIndex + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize * 0.3,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
      bool isCurrentCharacter, AudioPlaybackState audioState) {
    if (!isCurrentCharacter) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: LinearProgressIndicator(
        value: (audioState.audioIndex + 1) / (character.nameAudios.length + 1),
        backgroundColor: Colors.white.withOpacity(0.3),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}
