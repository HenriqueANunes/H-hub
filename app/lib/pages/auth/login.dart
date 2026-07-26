import 'package:flutter/material.dart';

import 'package:my_platform/services/api_client.dart';
import 'package:my_platform/services/auth_service.dart';

/// Tela de entrada. Serve pra login e pra cadastro — o botão de baixo alterna.
/// Não navega em caso de sucesso: quem troca a tela é o `AuthGate`, que escuta
/// o `isLoggedIn` do [AuthService].
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isRegistering = false;
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      if (_isRegistering) {
        await AuthService.instance.register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      }
      // Cadastro não devolve token, então entra logo em seguida.
      await AuthService.instance.login(_email.text.trim(), _password.text);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16.0),
                  Text(
                    _isRegistering ? 'Criar conta' : 'Entrar',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32.0),
                  if (_isRegistering) ...[
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'É necessário preencher o nome'
                          : null,
                    ),
                    const SizedBox(height: 20.0),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || !value.contains('@')
                        ? 'E-mail inválido'
                        : null,
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    // A API exige 8; validar aqui evita uma ida ao servidor.
                    validator: (value) => value == null || value.length < 8
                        ? 'A senha precisa ter ao menos 8 caracteres'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 20.0),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 32.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _submit,
                      child: _isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegistering ? 'Cadastrar' : 'Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => setState(() {
                            _isRegistering = !_isRegistering;
                            _error = null;
                          }),
                    child: Text(
                      _isRegistering
                          ? 'Já tenho conta'
                          : 'Criar uma conta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
