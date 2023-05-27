
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audio_cache.dart';

class AudioPlay
{

  AudioPlayer audioPlugin = AudioPlayer();
  String uri;
  
  Future<Null> load(String fullpath,String file) async
  {
    final ByteData data = await rootBundle.load(fullpath);
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/'+file);
    await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    uri = tempFile.uri.toString();
  }

  void play() async
  {
    if (uri != null)
    {
      await audioPlugin.play(uri, isLocal: true);
    }
  }

 Future<AudioPlayer> playLocalAsset() async
 {
   AudioCache cache = new AudioCache();
   return await cache.play("myCustomSoundEffect.mp3");
 }
 
}