import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config.dart';
import '../core/i18n.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Ягона нуқтаи пайвастшавӣ ба backend-и Python.
class TilloApi {
  TilloApi({http.Client? client, String? base})
      : _http = client ?? http.Client(),
        _base = base ?? AppConfig.apiBase;

  final http.Client _http;
  final String _base;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_base/api$path').replace(queryParameters: query);

  Future<dynamic> _send(Future<http.Response> Function() call, {bool login = false}) async {
    final http.Response res;
    try {
      res = await call().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException(t('error.network'));
    }
    if (res.statusCode >= 400) {
      throw ApiException(_errorText(res.statusCode, login), res.statusCode);
    }
    return res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Матни хато ба забони интерфейс (на матни сервер).
  static String _errorText(int status, bool login) => switch (status) {
        401 => t(login ? 'error.login' : 'error.auth'),
        404 => t('error.notfound'),
        409 => t('error.exists'),
        413 || 415 || 422 => t('error.validation'),
        _ => t('error.generic'),
      };

  Future<dynamic> _get(String path, [Map<String, String>? q]) =>
      _send(() => _http.get(_uri(path, q), headers: _headers));

  Future<dynamic> _post(String path, Object body) => _send(
        () => _http.post(_uri(path), headers: _headers, body: jsonEncode(body)),
        login: path.startsWith('/auth/'),
      );

  Future<Meta> meta() async => Meta.fromJson(await _get('/meta'));

  Future<GoldQuote> goldPrice() async => GoldQuote.fromJson(await _get('/gold-price'));

  Future<ListingsPage> listings(Map<String, String> query, {int page = 1, int perPage = 24}) async {
    final j = await _get('/listings', {...query, 'page': '$page', 'per_page': '$perPage'});
    return ListingsPage(
      (j['items'] as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList(),
      j['total'] as int,
      j['page'] as int,
    );
  }

  Future<Listing> listing(int id) async => Listing.fromJson(await _get('/listings/$id'));

  Future<Listing> createListing(Map<String, dynamic> body) async =>
      Listing.fromJson(await _post('/listings', body));

  Future<void> deleteListing(int id) =>
      _send(() => _http.delete(_uri('/listings/$id'), headers: _headers));

  Future<(String, User)> login(String phone, String password) async {
    final j = await _post('/auth/login', {'phone': phone, 'password': password});
    return (j['token'] as String, User.fromJson(j['user']));
  }

  Future<(String, User)> register(String name, String phone, String password, bool isShop) async {
    final j = await _post('/auth/register',
        {'name': name, 'phone': phone, 'password': password, 'is_shop': isShop});
    return (j['token'] as String, User.fromJson(j['user']));
  }

  Future<User> me() async => User.fromJson(await _get('/auth/me'));

  Future<String> upload(List<int> bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final type = switch (ext) { 'png' => 'png', 'webp' => 'webp', _ => 'jpeg' };
    final req = http.MultipartRequest('POST', _uri('/uploads'))
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename, contentType: MediaType('image', type)));
    final j = await _send(() async => http.Response.fromStream(await _http.send(req)));
    return j['url'] as String;
  }
}
