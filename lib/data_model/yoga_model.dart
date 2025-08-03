import 'package:flutter/services.dart';
import 'dart:convert';

class ScriptItem {
  final String text;
  final int startSec;
  final int endSec;
  final String imageRef;

  ScriptItem({
    required this.text,
    required this.startSec,
    required this.endSec,
    required this.imageRef,
  });

  factory ScriptItem.fromJson(Map<String, dynamic> json) => ScriptItem(
        text: json['text'],
        startSec: json['startSec'],
        endSec: json['endSec'],
        imageRef: json['imageRef'],
      );
}

class SequenceItem {
  final String type;
  final String name;
  final String audioRef;
  final int durationSec;
  final int iterations;
  final bool loopable;
  final List<ScriptItem> script;

  SequenceItem({
    required this.type,
    required this.name,
    required this.audioRef,
    required this.durationSec,
    required this.iterations,
    required this.loopable,
    required this.script,
  });

  factory SequenceItem.fromJson(Map<String, dynamic> json, int defaultLoopCount) =>
      SequenceItem(
        type: json['type'],
        name: json['name'],
        audioRef: json['audioRef'],
        durationSec: json['durationSec'],
        iterations: json['type'] == 'loop'
            ? (json['iterations'] is String &&
                    json['iterations'].toString().contains('loopCount')
                ? defaultLoopCount
                : int.tryParse(json['iterations'].toString()) ?? 1)
            : 1,
        loopable: json['loopable'] ?? false,
        script:
            (json['script'] as List).map((e) => ScriptItem.fromJson(e)).toList(),
      );
}

class YogaSessionData {
  final List<SequenceItem> sequences;
  final Map<String, String> imageAssets;
  final Map<String, String> audioAssets;
  final String sessionTitle;

  YogaSessionData({
    required this.sequences,
    required this.imageAssets,
    required this.audioAssets,
    required this.sessionTitle,
  });
}

Future<YogaSessionData> loadYogaSessionData() async {
  final jsonStr = await rootBundle.loadString('assets/CatCowJson.json');
  final Map<String, dynamic> root = jsonDecode(jsonStr);

  final int loopCount = root['metadata']['defaultLoopCount'] ?? 4;
  final String title = root['metadata']['title'] ?? "Yoga Session";

  final List<dynamic> seqs = root['sequence'];
  final List<SequenceItem> sequences =
      seqs.map((e) => SequenceItem.fromJson(e, loopCount)).toList();

  final Map<String, String> imageAssets =
      Map<String, String>.from(root['assets']['images']);
  final Map<String, String> audioAssets =
      Map<String, String>.from(root['assets']['audio']);

  return YogaSessionData(
    sequences: sequences,
    imageAssets: imageAssets,
    audioAssets: audioAssets,
    sessionTitle: title,
  );
}
