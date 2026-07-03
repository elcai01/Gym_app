import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class ApiClient {
  static Future<Map<String, String>> _getHeaders(Map<String, String>? extraHeaders) async {
    final session = await UserSession.loadFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (session != null && session.token != null)
        'Authorization': 'Bearer ${session.token}',
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final authHeaders = await _getHeaders(headers);
    return http.get(url, headers: authHeaders);
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await _getHeaders(headers);
    return http.post(url, headers: authHeaders, body: body, encoding: encoding);
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await _getHeaders(headers);
    return http.put(url, headers: authHeaders, body: body, encoding: encoding);
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await _getHeaders(headers);
    return http.delete(url, headers: authHeaders, body: body, encoding: encoding);
  }
}
