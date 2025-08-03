import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class Playback extends StatefulWidget {
  final String audioAssetPath;
  final VoidCallback? onComplete;
  final Function(Duration)? onPositionChanged;

  const Playback({
    Key? key,
    required this.audioAssetPath,
    this.onComplete,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  State<Playback> createState() => _PlaybackState();
}

class _PlaybackState extends State<Playback> {
  late final AudioPlayer _player;

  Duration? duration;
  Duration position = Duration.zero;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();

    _player.durationStream.listen((d) {
      setState(() {
        duration = d;
      });
    });

    _player.positionStream.listen((pos) {
      setState(() {
        position = pos;
      });
      if (widget.onPositionChanged != null) {
        widget.onPositionChanged!(pos);
      }
    });

    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      setState(() {
        isPlaying = playing && processingState != ProcessingState.completed;
      });

      if (processingState == ProcessingState.completed) {
        widget.onComplete?.call();
      }
    });

    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setAsset(widget.audioAssetPath);
      await _player.play();
    } catch (e) {
      debugPrint('Error loading audio source: $e');
    }
  }


  @override
  void didUpdateWidget(covariant Playback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioAssetPath != oldWidget.audioAssetPath) {
      _init();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dur = duration ?? Duration.zero;
    final pos = duration != null && position > dur ? dur : position;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 64),
          onPressed: () {
            if (isPlaying) {
              _player.pause();
            } else {
              _player.play();
            }
          },
        ),
        Slider(
          min: 0.0,
          max: dur.inMilliseconds.toDouble() > 0 ? dur.inMilliseconds.toDouble() : 1,
          value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
          onChanged: (value) {
            _player.seek(Duration(milliseconds: value.round()));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "${_formatDuration(pos)} / ${_formatDuration(dur)}",
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
