import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';
import '../models/bible_character.dart';
import '../providers/bible_data_provider.dart';
import '../widgets/character_card.dart';
import '../services/audio_service.dart';
import 'dart:math';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  String currentLetter = '';
  int score = 0;
  int attempts = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  late ConfettiController _confettiController;
  List<String> availableLetters = [];
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _resetAvailableLetters();
  }

  void _resetAvailableLetters() {
    availableLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    availableLetters.shuffle();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _isAudioPlaying = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bibleDataAsyncValue = ref.watch(bibleDataProvider);
    final audioService = ref.watch(audioServiceProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[100]!, Colors.purple[100]!],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildGameControls(audioService),
                  Expanded(
                    child: bibleDataAsyncValue.when(
                      data: (characters) => _buildCharacterGrid(characters),
                      error: (error, stackTrace) => Center(
                        child: Text('Error: $error',
                            style: const TextStyle(color: Colors.red)),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, color: Colors.white, size: 30),
          SizedBox(width: 10),
          Text(
            'Alfabeto Bíblico',
            style: TextStyle(
              fontFamily: 'KidsFont',
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameControls(AudioService audioService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white),
                  label: Text(
                    isPlaying ? 'Detener Juego' : 'Jugar',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlaying ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => _toggleGame(audioService),
                ),
              ),
              if (isPlaying)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Puntuación: $score / $attempts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700]),
                    ),
                  ),
                ),
            ],
          ),
          if (isPlaying)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: AnimatedTextKit(
                key: ValueKey(currentLetter),
                animatedTexts: [
                  WavyAnimatedText(
                    'Busca la letra: ${currentLetter.toUpperCase()}',
                    textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700]),
                  ),
                ],
                isRepeatingAnimation: true,
                totalRepeatCount: 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacterGrid(List<BibleCharacter> characters) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait = orientation == Orientation.portrait;
            final crossAxisCount = isPortrait
                ? 4
                : _getLandscapeCrossAxisCount(constraints.maxWidth);

            // Filtrar las cards si el juego está en progreso
            final displayedCharacters = isPlaying
                ? characters
                    .where((c) => c.letter != 'Him' && c.letter != 'Song')
                    .toList()
                : characters;

            final childAspectRatio = _getChildAspectRatio(
              constraints.maxWidth,
              constraints.maxHeight,
              crossAxisCount,
              displayedCharacters.length,
              isPortrait,
            );

            return GridView.builder(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: displayedCharacters.length,
              itemBuilder: (context, index) {
                return CharacterCard(
                  character: displayedCharacters[index],
                  cardColor: _getCardColor(index),
                  onLetterSelected: (selectedLetter) {
                    if (isPlaying) {
                      checkAnswer(
                          selectedLetter, ref.read(audioServiceProvider));
                    } else {
                      ref.read(audioServiceProvider).playNextAudio(
                          displayedCharacters[index].letter, [
                        displayedCharacters[index].letterAudio,
                        ...displayedCharacters[index].nameAudios
                      ]);
                    }
                  },
                  isGameMode: isPlaying,
                  isHighlighted: isPlaying &&
                      displayedCharacters[index].letter.toUpperCase() ==
                          currentLetter.toUpperCase(),
                );
              },
            );
          },
        );
      },
    );
  }

  int _getLandscapeCrossAxisCount(double width) {
    if (width > 1200) return 8;
    if (width > 900) return 7;
    if (width > 600) return 6;
    return 5;
  }

  double _getChildAspectRatio(double width, double height, int crossAxisCount,
      int totalItems, bool isPortrait) {
    int rowCount = (totalItems / crossAxisCount).ceil();
    double aspectRatio = (width / crossAxisCount) / (height / rowCount);

    if (!isPortrait) {
      aspectRatio *=
          0.8; // Ajustado de 0.75 a 0.8 para un mejor aspecto en paisaje
    }

    return aspectRatio;
  }

  void _toggleGame(AudioService audioService) {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        score = 0;
        attempts = 0;
        _resetAvailableLetters();
        _controller.forward();
        startGame(audioService);
      } else {
        _isAudioPlaying = false;
        audioService.stopAllAudio();
        _controller.reverse();
        setState(() {
          currentLetter = '';
        });
      }
    });
  }

  void startGame(AudioService audioService) {
    if (availableLetters.isEmpty) {
      _resetAvailableLetters();
    }

    _playAudioSequence(audioService);
  }

  void _playAudioSequence(AudioService audioService) async {
    _isAudioPlaying = true;

    await audioService
        .playNextAudio('instruction', ['assets/audio/busca_letra.mp3']);
    await Future.delayed(const Duration(microseconds: 500));

    if (!_isAudioPlaying) return;

    final newLetter = availableLetters.removeAt(0);
    setState(() {
      currentLetter = newLetter;
    });

    await audioService.playNextAudio(newLetter, [
      'assets/audio/${newLetter.toLowerCase()}/letter_${newLetter.toLowerCase()}.mp3'
    ]);
    await Future.delayed(const Duration(microseconds: 300));

    if (!_isAudioPlaying) return;

    await audioService.playNextAudio(newLetter, [
      'assets/audio/${newLetter.toLowerCase()}/letter_${newLetter.toLowerCase()}_name.mp3'
    ]);
  }

  void checkAnswer(String selectedLetter, AudioService audioService) async {
    setState(() {
      attempts++;
    });

    _isAudioPlaying = false;
    await audioService.stopAllAudio();

    if (selectedLetter.toUpperCase() == currentLetter.toUpperCase()) {
      setState(() {
        score++;
      });

      await audioService.playNextAudio(selectedLetter, [
        'assets/audio/${selectedLetter.toLowerCase()}/letter_${selectedLetter.toLowerCase()}.mp3'
      ]);
      await Future.delayed(const Duration(microseconds: 500));

      await audioService
          .playNextAudio('correct', ['assets/audio/correcto.mp3']);
      await Future.delayed(const Duration(microseconds: 500));

      if (score % 10 == 0) {
        _showCongratulationsDialog();
      } else {
        _playAudioSequence(audioService);
      }
    } else {
      await audioService.playNextAudio(selectedLetter, [
        'assets/audio/${selectedLetter.toLowerCase()}/letter_${selectedLetter.toLowerCase()}.mp3'
      ]);
      await Future.delayed(const Duration(microseconds: 500));

      await audioService
          .playNextAudio('incorrect', ['assets/audio/incorrecto.mp3']);
      await Future.delayed(const Duration(microseconds: 500));
    }
  }

  void _showCongratulationsDialog() {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '¡Felicidades!',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.purple),
            textAlign: TextAlign.center,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 60, color: Colors.yellow),
              SizedBox(height: 16),
              Text(
                '¡Has acertado 10 letras!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '¡Sigue así, estás aprendiendo muy rápido!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  startGame(ref.read(audioServiceProvider));
                },
                child: const Text('¡Sigamos aprendiendo!',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getCardColor(int index) {
    final colors = [
      Colors.red[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
      Colors.pink[300]!,
      Colors.indigo[300]!,
      Colors.amber[300]!,
      Colors.cyan[300]!,
    ];
    return colors[index % colors.length];
  }
}
