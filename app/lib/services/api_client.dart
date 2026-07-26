import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Erro vindo da API. A mensagem é o corpo que o Go escreveu no `http.Error`,
/// então já vem pronta pra mostrar na tela.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Não deu nem pra falar com o servidor (fora do ar, URL errada, sem rede).
class ConnectionException extends ApiException {
  ConnectionException(String message) : super(0, message);
}

/// 401: token ausente, inválido ou expirado. Quem trata derruba a sessão.
class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(401, message);
}

/// Ponto único de conversa com a API Go: monta a URL, injeta o `Authorization`
/// e traduz status HTTP em exceção.
class ApiClient {
  /// Aponta pra outro servidor com:
  /// `flutter run --dart-define=API_BASE_URL=http://100.80.9.52:8090`
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    // Na web o nginx serve o front e faz proxy de /auth e /expenses pra API, então
    // ela mora na mesma origem da página — nada de CORS e nada de URL fixa no build.
    if (kIsWeb) return Uri.base.origin;
    return 'http://localhost:8080';
  }

  static const _timeout = Duration(seconds: 10);

  static final ApiClient instance = ApiClient._();

  ApiClient._();

  String? _token;

  /// Chamado sempre que a API responde 401 — quem registra é o `AuthGate`.
  Future<void> Function()? onUnauthorized;

  void setToken(String? token) => _token = token;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, Object body) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, Object body) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse(baseUrl).replace(path: path, queryParameters: query);
    final request = http.Request(method, uri);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed = await request.send().timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ConnectionException('O servidor demorou demais pra responder.');
    } on http.ClientException catch (e) {
      // Cobre também a falha de socket do desktop: o package:http embrulha a
      // SocketException num tipo que implementa ClientException. Tratar aqui evita
      // o `dart:io`, que não existe na web.
      throw ConnectionException('Não foi possível conectar em $baseUrl: ${e.message}');
    }

    return _decode(response);
  }

  Future<dynamic> _decode(http.Response response) async {
    if (response.statusCode == 401) {
      // A sessão morreu: avisa quem cuida disso antes de propagar o erro.
      await onUnauthorized?.call();
      throw UnauthorizedException('Sessão expirada. Entre de novo.');
    }
    if (response.statusCode >= 400) {
      final message = response.body.trim();
      throw ApiException(
        response.statusCode,
        message.isEmpty ? 'Erro ${response.statusCode}' : message,
      );
    }
    // 204 (delete) não tem corpo.
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
