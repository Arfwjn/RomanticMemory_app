import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final AudioRecorder _recorder = AudioRecorder();
  static String? _currentRecordingPath;

  // Recording methods
  static Future<bool> startRecording() async {
    try {
      // Cek permission
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentRecordingPath!,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path ?? _currentRecordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  static Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  // Playback methods
  static Future<void> playAudio(String path) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  static Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  static Future<void> seekAudio(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  // Stream getters
  static Stream<Duration> getDurationStream() {
    return _audioPlayer.onDurationChanged;
  }

  static Stream<Duration> getPositionStream() {
    return _audioPlayer.onPositionChanged;
  }

  static Stream<PlayerState> getPlayerStateStream() {
    return _audioPlayer.onPlayerStateChanged;
  }

  // Cleanup
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _recorder.dispose();
  }
}
