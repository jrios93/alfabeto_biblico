import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bible_character.dart';

final bibleDataProvider = FutureProvider<List<BibleCharacter>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/data/data.json');
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  return jsonMap.entries
      .map((entry) => BibleCharacter.fromJson(entry.key, entry.value))
      .toList();
});
