import 'package:flutter/material.dart';
import 'data_model/yoga_model.dart';
import 'playback.dart';


class SessionPlaybackScreen extends StatefulWidget {
  const SessionPlaybackScreen({Key? key}) : super(key: key);

  @override
  State<SessionPlaybackScreen> createState() => _SessionPlaybackScreenState();
}

class _SessionPlaybackScreenState extends State<SessionPlaybackScreen> {
  late YogaSessionData sessionData;
  bool isLoading = true;

  int sequenceIndex = 0; 
  int loopIteration = 0; 
  late SequenceItem currentSequence;
  late ScriptItem currentScriptItem;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    sessionData = await loadYogaSessionData();
    currentSequence = sessionData.sequences[sequenceIndex];
    currentScriptItem = currentSequence.script.first;
    setState(() {
      isLoading = false;
    });
  }

  void _onAudioPositionChanged(Duration position) {
    final elapsedSeconds = position.inSeconds;

    final script = currentSequence.script;
    final scriptNow = script.firstWhere(
      (item) => elapsedSeconds >= item.startSec && elapsedSeconds < item.endSec,
      orElse: () => script.last,
    );

    if (scriptNow != currentScriptItem) {
      setState(() {
        currentScriptItem = scriptNow;
      });
    }
  }

  void _onAudioComplete() {
    if (currentSequence.type == 'loop' &&
        loopIteration < currentSequence.iterations - 1) {
      setState(() {
        loopIteration++;
      });
    } else {
      if (sequenceIndex < sessionData.sequences.length - 1) {
        setState(() {
          sequenceIndex++;
          loopIteration = 0;
          currentSequence = sessionData.sequences[sequenceIndex];
          currentScriptItem = currentSequence.script.first;
        });
      } else {
        _showSessionCompleteDialog();
      }
    }
  }

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Session Complete"),
            content: const Text("You have finished the yoga session!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _restartSession();
                },
                child: const Text("Restart"),
              ),
            ],
          ),
    );
  }

  void _restartSession() {
    setState(() {
      sequenceIndex = 0;
      loopIteration = 0;
      currentSequence = sessionData.sequences[sequenceIndex];
      currentScriptItem = currentSequence.script.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final imagePath =
        'assets/images/${sessionData.imageAssets[currentScriptItem.imageRef]}';
    final audioPath =
        'assets/audio/${sessionData.audioAssets[currentSequence.audioRef]}';

    return Scaffold(
      appBar: AppBar(title: Text(sessionData.sessionTitle), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Image not found'));
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentScriptItem.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Playback(
                key: ValueKey('audio_${sequenceIndex}_loop_$loopIteration'),
                audioAssetPath: audioPath,
                onComplete: _onAudioComplete,
                onPositionChanged: _onAudioPositionChanged,
              ),

              const SizedBox(height: 24),
              Text(
                "Segment ${sequenceIndex + 1} / ${sessionData.sequences.length}    Loop ${loopIteration + 1} / ${currentSequence.iterations}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
