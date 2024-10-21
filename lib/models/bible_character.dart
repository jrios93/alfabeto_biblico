class BibleCharacter {
  final String letter;
  final String letterAudio;
  final List<String> nameAudios;
  final String image;

  BibleCharacter({
    required this.letter,
    required this.letterAudio,
    required this.nameAudios,
    required this.image,
  });

  factory BibleCharacter.fromJson(String letters, Map<String, dynamic> json) {
    return BibleCharacter(
      letter: letters,
      letterAudio: json['audio']['letra'],
      nameAudios: List<String>.from(json['audio']['nombres']),
      image: json['imagen'],
    );
  }
}
