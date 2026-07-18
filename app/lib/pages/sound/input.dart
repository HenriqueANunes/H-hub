import 'package:flutter/material.dart';
import 'package:win32audio/win32audio.dart';

import 'package:my_platform/services/sound.dart';

import 'package:my_platform/widgets/future_builder.dart';

class SoundInput extends StatefulWidget {
  const SoundInput({super.key});

  @override
  State<SoundInput> createState() => _SoundInputState();
}

class _SoundInputState extends State<SoundInput> {
  late Future<(List<AudioDevice>, String)> _audioDevices;
  String _defaultDevice = '';

  @override
  void initState() {
    super.initState();
    _audioDevices = Sound().getAudioDevices('input');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dispositivos de entrada'),
      ),
      body: CustomFutureBuilder(
        future: _audioDevices,
        dataBuilder: (context, data) {
          {
            var (deviceList, defaultDevice) = data;
            if (_defaultDevice == ''){
              _defaultDevice =  defaultDevice;
            }
            return Center(
              child: DropdownButton(
                items: deviceList.map((device) {
                  return DropdownMenuItem<String>(
                    value: device.id,
                    child: Text(device.name),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _defaultDevice = value!;
                  });
                  await Sound().setDefaultDevice(value!);
                },
                value: _defaultDevice,
              ),
            );
          }
        },
      ),
    );
  }
}
