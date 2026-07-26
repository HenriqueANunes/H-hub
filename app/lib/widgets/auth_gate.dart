import 'package:flutter/material.dart';

import 'package:my_platform/main.dart';
import 'package:my_platform/pages/auth/login.dart';
import 'package:my_platform/pages/home.dart';
import 'package:my_platform/services/api_client.dart';
import 'package:my_platform/services/auth_service.dart';

/// Raiz do app: decide entre login e conteúdo, e é quem reage à sessão cair.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _restore;

  @override
  void initState() {
    super.initState();
    // Qualquer 401 em qualquer tela derruba a sessão por aqui.
    ApiClient.instance.onUnauthorized = AuthService.instance.logout;
    AuthService.instance.isLoggedIn.addListener(_onSessionChanged);
    _restore = AuthService.instance.restoreSession();
  }

  @override
  void dispose() {
    AuthService.instance.isLoggedIn.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Saiu com telas empilhadas por cima: esvazia a pilha antes do login aparecer.
  void _onSessionChanged() {
    if (!AuthService.instance.isLoggedIn.value) {
      appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _restore,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ValueListenableBuilder<bool>(
          valueListenable: AuthService.instance.isLoggedIn,
          builder: (context, isLoggedIn, _) =>
              isLoggedIn ? const HomePage() : const LoginPage(),
        );
      },
    );
  }
}
