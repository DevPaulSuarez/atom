import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const _base = 'https://apiatom.devpess.com';
  static const _kAccess = 'atom_access_token';
  static const _kRefresh = 'atom_refresh_token';
  static const _kName = 'atom_user_name';
  static const _kTester = 'atom_is_tester';

  String? _accessToken;
  String? _refreshToken;
  String? _userName;
  bool _isTester = false;

  bool get hasSession => _accessToken != null;
  String get userName => _userName ?? '';
  bool get isTester => _isTester;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_kAccess);
    _refreshToken = prefs.getString(_kRefresh);
    _userName = prefs.getString(_kName);
    _isTester = prefs.getBool(_kTester) ?? false;
  }

  Future<void> saveSession(
      String access, String refresh, String name, {bool isTester = false}) async {
    _accessToken = access;
    _refreshToken = refresh;
    _userName = name;
    _isTester = isTester;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
    await prefs.setString(_kName, name);
    await prefs.setBool(_kTester, isTester);
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _userName = null;
    _isTester = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kName);
    await prefs.remove(_kTester);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);
  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _request('PATCH', path, body: body);
  Future<void> delete(String path) => _request('DELETE', path);

  Future<dynamic> _request(String method, String path,
      {Map<String, dynamic>? body, bool isRetry = false}) async {
    final uri = Uri.parse('$_base$path');
    final encoded = body != null ? jsonEncode(body) : null;

    final response = await _send(method, uri, encoded);

    if (response.statusCode == 401 && !isRetry && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) return _request(method, path, body: body, isRetry: true);
      await clearSession();
      throw ApiException(401, 'Sesión expirada');
    }

    return _parse(response);
  }

  Future<http.Response> _send(String method, Uri uri, String? body) {
    switch (method) {
      case 'GET':
        return http.get(uri, headers: _headers);
      case 'POST':
        return http.post(uri, headers: _headers, body: body);
      case 'PATCH':
        return http.patch(uri, headers: _headers, body: body);
      case 'DELETE':
        return http.delete(uri, headers: _headers);
      default:
        throw UnsupportedError('Method $method');
    }
  }

  Future<bool> _tryRefresh() async {
    try {
      final response = await http.post(
        Uri.parse('$_base/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['accessToken'] as String;
      _refreshToken = data['refreshToken'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccess, _accessToken!);
      await prefs.setString(_kRefresh, _refreshToken!);
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _parse(http.Response response) {
    if (response.statusCode == 204) return null;

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 400) {
      String msg = 'Error desconocido';
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        msg = json['error'] as String? ?? msg;
      } catch (_) {}
      throw ApiException(response.statusCode, msg);
    }

    if (body.isEmpty) return null;
    return jsonDecode(body);
  }
}
