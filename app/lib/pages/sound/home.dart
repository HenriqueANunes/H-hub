import 'package:flutter/material.dart';
import 'package:my_platform/widgets/animated_square.dart';

class SoundPage extends StatelessWidget {
  const SoundPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Dispositivos de som'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Define quantas colunas cabem na largura atual:
          double width = constraints.maxWidth;

          int crossAxisCount = 2; // padrão
          if (width > 1200) {
            crossAxisCount = 5;
          } else if (width > 900) {
            crossAxisCount = 4;
          } else if (width > 600) {
            crossAxisCount = 3;
          } else {
            crossAxisCount = 2;
          }

          return GridView.count(
            crossAxisCount: crossAxisCount,
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              AnimatedSquare(
                icon: Icons.mic,
                label: 'Dispositivos de entrada',
                onTap: () => Navigator.pushNamed(context, '/sound/input.dart'),
              ),
              AnimatedSquare(
                icon: Icons.speaker,
                label: 'Dispositivos de saida',
                onTap: () {},
              ),
              // pode adicionar mais cards aqui se quiser
            ],
          );
        },
      ),
    );
  }
}
