import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_platform/models/user_model.dart';
import 'package:my_platform/services/api_client.dart';

/// Dono da sessão: guarda o token entre execuções e avisa a árvore de widgets
/// quando o usuário entra ou sai.
class AuthService {
  static const _tokenKey = 'auth_token';
  static const _expiresAtKey = 'auth_expires_at';

  static final AuthService instance = AuthService._();

  AuthService._();

  /// O `AuthGate` escuta isso pra decidir entre login e app.
  final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

  /// Recupera o token salvo no disco. Token vencido é o mesmo que token nenhum
  /// — a data de expiração vem do próprio login, então dá pra checar sem rede.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiresAt = DateTime.tryParse(prefs.getString(_expiresAtKey) ?? '');

    if (token == null || expiresAt == null || expiresAt.isBefore(DateTime.now())) {
      await logout();
      return;
    }

    ApiClient.instance.setToken(token);
    isLoggedIn.value = true;
  }

  Future<void> login(String email, String password) async {
    final data = await ApiClient.instance.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final token = data['token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_expiresAtKey, data['expires_at'] as String);

    ApiClient.instance.setToken(token);
    isLoggedIn.value = true;
  }

  /// Cadastra o usuário. Não devolve token — quem chama emenda um `login`.
  Future<UserModel> register(String name, String email, String password) async {
    final data = await ApiClient.instance.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> me() async {
    final data = await ApiClient.instance.get('/auth/me');
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresAtKey);

    ApiClient.instance.setToken(null);
    isLoggedIn.value = false;
  }
}
