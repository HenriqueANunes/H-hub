import 'package:flutter/material.dart';
class AppFooter extends StatelessWidget {
  final Widget child;

  const AppFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 80,
      child: Container(
        width: double.infinity, // ocupa largura total da tela
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.bottomAppBarTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
