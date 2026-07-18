import 'package:win32audio/win32audio.dart';

class Sound {
  // double _volume = 0;
  // late AudioDevice _defaultDevice;

  // Future<void> init() async{
  //   _volume = await Audio.getVolume(audioDeviceTypeInput);
  //   _defaultDevice = (await Audio.getDefaultDevice(audioDeviceTypeInput))!;
  // }

  Future<(List<AudioDevice>, String)> getAudioDevices(String type) async {
    final AudioDeviceType audioDeviceType;
    if (type == 'input') {
      audioDeviceType = AudioDeviceType.input;
    } else {
      audioDeviceType = AudioDeviceType.output;
    }

    List<AudioDevice> audioDevices = await Audio.enumDevices(audioDeviceType) ?? <AudioDevice>[];
    AudioDevice defaultDevice = (await Audio.getDefaultDevice(audioDeviceType))!;

    return (audioDevices, defaultDevice.id);
  }

  Future<AudioDevice> getDefaultDevice(String type) async {
    final AudioDeviceType audioDeviceType;
    if (type == 'input') {
      audioDeviceType = AudioDeviceType.input;
    } else {
      audioDeviceType = AudioDeviceType.output;
    }
    return (await Audio.getDefaultDevice(audioDeviceType))!;
  }

  Future<int> setDefaultDevice(String id) async{
    return await Audio.setDefaultDevice(id, communications: true);
  }

}
