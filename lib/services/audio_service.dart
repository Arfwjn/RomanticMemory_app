import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'dart:io';

class AudioService {
  static final AudioPlayer audioPlayer = AudioPlayer();
  static final AudioRecorder audioRecorder = AudioRecorder();
  static String? _recordingPath;

  // Recording
  static Future<bool> startRecording() async {
    try {
      if (await audioRecorder.hasPermission()) {
        final dir = Directory.systemTemp;
        final file = File('${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
        _recordingPath = file.path;

        await audioRecorder.start(RecordConfig(), path: file.path);
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
      await audioRecorder.stop();
      return _recordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  static Future<void> cancelRecording() async {
    _recordingPath = null;
    await audioRecorder.cancel();
  }

  // Playback
  static Future<void> playAudio(String filePath) async {
    try {
      await audioPlayer.play(UrlSource(filePath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  static Future<void> pauseAudio() async {
    await audioPlayer.pause();
  }

  static Future<void> resumeAudio() async {
    await audioPlayer.resume();
  }

  static Future<void> stopAudio() async {
    await audioPlayer.stop();
  }

  static Stream<Duration> getDurationStream() {
    return audioPlayer.onDurationChanged;
  }

  static Stream<Duration> getPositionStream() {
    return audioPlayer.onPositionChanged;
  }
}
