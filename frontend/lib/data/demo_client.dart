import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';

/// «Сервери» дохилӣ барои версияи намоишӣ (GitHub Pages, бе Python).
///
/// Ҳамон API-и backend-ро такрор мекунад, бинобар ин BLoC-ҳо тағйир намеёбанд.
/// Эълонҳо ва ҳисобҳои нав дар localStorage-и браузер нигоҳ дошта мешаванд.
class DemoClient extends http.BaseClient {
  DemoClient(this._prefs);

  final SharedPreferences _prefs;
  static const _stateKey = 'demo_state_v1';
  static const _demoPassword = 'tillo123';

  late Map<String, dynamic> _meta;
  late Map<String, dynamic> _quote;
  late List<Map<String, dynamic>> _listings;
  late List<Map<String, dynamic>> _users;
  final Map<String, String> _passwords = {};
  final Map<String, int> _sessions = {};
  Future<void>? _quoteReady;

  Future<void>? _initFuture;

  Future<void> _init() => _initFuture ??= _load();

  Future<void> _load() async {
    final data = jsonDecode(await _loadData()) as Map<String, dynamic>;
    _meta = data['meta'] as Map<String, dynamic>;
    _quote = data['quote'] as Map<String, dynamic>;
    _users = (data['users'] as List).cast<Map<String, dynamic>>();
    _listings = (data['listings'] as List).cast<Map<String, dynamic>>();
    _shiftDates();
    for (final u in _users) {
      _passwords[u['phone'] as String] = _demoPassword;
    }
    _restore();
    _quoteReady = _refreshQuote();
  }

  /// Дар веб бо `?v=BUILD_ID` (бе кеши кӯҳна), дар тестҳо — аз rootBundle.
  Future<String> _loadData() async {
    if (kIsWeb && AppConfig.buildId.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse('assets/assets/demo/data.json?v=${AppConfig.buildId}')); // нисбат ба <base href>
        if (res.statusCode == 200) return utf8.decode(res.bodyBytes);
      } catch (_) {
        // ба rootBundle мегузарем
      }
    }
    return rootBundle.loadString('assets/demo/data.json');
  }

  /// Санаҳои намунаро ба «ҳозир» наздик мекунем, то «19 рӯз пеш» кӯҳна нашавад.
  void _shiftDates() {
    final dates = _listings.map((l) => _parse(l['created_at'] as String)).toList();
    final newest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final shift = DateTime.now().toUtc().difference(newest) - const Duration(minutes: 30);
    for (var i = 0; i < _listings.length; i++) {
      _listings[i]['created_at'] = _fmt(dates[i].add(shift));
    }
  }

  static DateTime _parse(String s) => DateTime.parse('${s.replaceFirst(' ', 'T')}Z');
  static String _fmt(DateTime d) => d.toIso8601String().substring(0, 19).replaceFirst('T', ' ');

  Future<Map<String, dynamic>> _liveQuote() async {
    await _quoteReady;
    return _quote;
  }

  /// Нархи зинда мустақиман аз браузер; агар нашавад — нархи захиравӣ.
  Future<void> _refreshQuote() async {
    try {
      final c = http.Client();
      Future<dynamic> get(String url) async =>
          jsonDecode((await c.get(Uri.parse(url)).timeout(const Duration(seconds: 4))).body);
      final res = await Future.wait([
        get('https://api.gold-api.com/price/XAU'),
        get('https://api.gold-api.com/price/XAG'),
        get('https://open.er-api.com/v6/latest/USD'),
      ]);
      final xau = res[0]['price'] as num, xag = res[1]['price'] as num, tjs = res[2]['rates']['TJS'] as num;
      const oz = 31.1034768;
      final g999 = xau / oz * tjs, s999 = xag / oz * tjs;
      double r(num v) => (v * 100).round() / 100;
      _quote = {
        'usd_per_oz': r(xau),
        'silver_usd_per_oz': r(xag),
        'tjs_per_usd': (tjs * 10000).round() / 10000,
        'gold_per_gram': {
          for (final p in [999, 958, 916, 875, 750, 585, 583, 500, 375]) '$p': r(g999 * p / 1000),
        },
        'silver_per_gram': {
          for (final p in [999, 925, 875]) '$p': r(s999 * p / 1000),
        },
        'live': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
    } catch (_) {
      // Нархи захиравӣ мемонад.
    }
  }

  // ---------- localStorage ----------

  void _restore() {
    final raw = _prefs.getString(_stateKey);
    if (raw == null) return;
    try {
      final s = jsonDecode(raw) as Map<String, dynamic>;
      _users.addAll((s['users'] as List).cast<Map<String, dynamic>>());
      _passwords.addAll((s['passwords'] as Map).cast<String, String>());
      _sessions.addAll((s['sessions'] as Map).cast<String, int>());
      final deleted = (s['deleted'] as List).cast<int>().toSet();
      _listings.removeWhere((l) => deleted.contains(l['id']));
      _listings.addAll((s['listings'] as List).cast<Map<String, dynamic>>());
      _deleted.addAll(deleted);
    } catch (_) {
      _prefs.remove(_stateKey);
    }
  }

  final Set<int> _deleted = {};
  static const _baseUserCount = 6;

  void _persist() {
    final mine = _listings.where((l) => (l['id'] as int) > 10000).toList();
    final state = {
      'users': _users.skip(_baseUserCount).toList(),
      'passwords': Map.fromEntries(_passwords.entries.where((e) => !_isBase(e.key))),
      'sessions': _sessions,
      'deleted': _deleted.toList(),
      'listings': mine,
    };
    try {
      _prefs.setString(_stateKey, jsonEncode(state));
    } catch (_) {
      // localStorage пур шуд (суратҳои калон) — танҳо дар хотира мемонад.
    }
  }

  bool _isBase(String phone) => _users.take(_baseUserCount).any((u) => u['phone'] == phone);

  // ---------- маршрутизатсия ----------

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await _init();
    final url = request.url;
    final path = url.path.replaceFirst(RegExp(r'^.*?/api'), '');
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    final user = token == null ? null : _users.where((u) => u['id'] == _sessions[token]).firstOrNull;
    Map<String, dynamic> body() => jsonDecode(utf8.decode((request as http.Request).bodyBytes)) as Map<String, dynamic>;

    try {
      final (status, json) = switch ((request.method, path)) {
        ('GET', '/meta') => (200, _metaWithCounts()),
        ('GET', '/gold-price') => (200, await _liveQuote()),
        ('GET', '/listings') => _list(url.queryParameters, user),
        ('GET', final p) when p.startsWith('/listings/') => _detail(int.parse(p.split('/').last)),
        ('POST', '/auth/login') => _login(body()),
        ('POST', '/auth/register') => _register(body()),
        ('GET', '/auth/me') => user == null ? _err(401) : (200, user),
        ('POST', '/listings') => user == null ? _err(401) : _create(body(), user),
        ('DELETE', final p) when p.startsWith('/listings/') =>
          user == null ? _err(401) : _delete(int.parse(p.split('/').last), user),
        ('POST', '/uploads') => user == null ? _err(401) : await _upload(request as http.MultipartRequest),
        _ => _err(404),
      };
      final bytes = json == null ? <int>[] : utf8.encode(jsonEncode(json));
      return http.StreamedResponse(
        Stream.value(bytes),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return http.StreamedResponse(Stream.value(utf8.encode('{"detail":"bad request"}')), 422);
    }
  }

  (int, Object?) _err(int status) => (status, {'detail': 'error'});

  Map<String, dynamic> _metaWithCounts() {
    final counts = <String, int>{};
    for (final l in _listings) {
      counts.update(l['category'] as String, (v) => v + 1, ifAbsent: () => 1);
    }
    return {
      ..._meta,
      'categories': [
        for (final c in (_meta['categories'] as List).cast<Map<String, dynamic>>())
          {...c, 'count': counts[c['slug']] ?? 0},
      ],
    };
  }

  (int, Object?) _list(Map<String, String> q, Map<String, dynamic>? user) {
    Iterable<Map<String, dynamic>> items = _listings;
    final text = q['q']?.trim().toLowerCase() ?? '';
    if (text.isNotEmpty) {
      items = items.where(
        (l) =>
            (l['title'] as String).toLowerCase().contains(text) ||
            (l['description'] as String).toLowerCase().contains(text),
      );
    }
    for (final key in ['category', 'metal', 'stone', 'city', 'condition']) {
      final v = q[key];
      if (v != null && v.isNotEmpty) items = items.where((l) => l[key] == v);
    }
    final proba = int.tryParse(q['proba'] ?? '');
    if (proba != null) items = items.where((l) => l['proba'] == proba);
    final minP = int.tryParse(q['min_price'] ?? '');
    if (minP != null) items = items.where((l) => (l['price'] as int) >= minP);
    final maxP = int.tryParse(q['max_price'] ?? '');
    if (maxP != null) items = items.where((l) => (l['price'] as int) <= maxP);
    if (q['featured'] != null) items = items.where((l) => l['featured'] == (q['featured'] == 'true'));
    if (q['mine'] == 'true') {
      if (user == null) return _err(401);
      items = items.where((l) => l['user_id'] == user['id']);
    }
    if (q['ids'] != null) {
      final ids = q['ids']!.split(',').map(int.tryParse).whereType<int>().toSet();
      items = items.where((l) => ids.contains(l['id']));
    }

    final list = items.toList();
    int byNew(Map<String, dynamic> a, Map<String, dynamic> b) {
      final f = (b['featured'] == true ? 1 : 0) - (a['featured'] == true ? 1 : 0);
      return f != 0 ? f : (b['created_at'] as String).compareTo(a['created_at'] as String);
    }

    list.sort(switch (q['sort']) {
      'price_asc' => (a, b) => (a['price'] as int).compareTo(b['price'] as int),
      'price_desc' => (a, b) => (b['price'] as int).compareTo(a['price'] as int),
      'popular' => (a, b) => (b['views'] as int).compareTo(a['views'] as int),
      _ => byNew,
    });
    final page = math.max(1, int.tryParse(q['page'] ?? '') ?? 1);
    final per = (int.tryParse(q['per_page'] ?? '') ?? 24).clamp(1, 60);
    final from = math.min((page - 1) * per, list.length);
    return (
      200,
      {
        'items': list.sublist(from, math.min(from + per, list.length)),
        'total': list.length,
        'page': page,
        'per_page': per,
      },
    );
  }

  (int, Object?) _detail(int id) {
    final l = _listings.where((l) => l['id'] == id).firstOrNull;
    if (l == null) return _err(404);
    l['views'] = (l['views'] as int) + 1;
    final similar = _listings.where((x) => x['category'] == l['category'] && x['id'] != id).toList()
      ..sort((a, b) {
        final f = (b['featured'] == true ? 1 : 0) - (a['featured'] == true ? 1 : 0);
        return f != 0 ? f : (b['views'] as int).compareTo(a['views'] as int);
      });
    return (200, {...l, 'metal_value': _metalValue(l), 'similar': similar.take(8).toList()});
  }

  double? _metalValue(Map<String, dynamic> l) {
    final proba = l['proba'] as int?;
    final weight = (l['weight'] as num?)?.toDouble();
    if (proba == null || weight == null) return null;
    final metal = l['metal'] as String;
    final table = metal == 'silver'
        ? _quote['silver_per_gram']
        : (metal.contains('gold') ? _quote['gold_per_gram'] : null);
    if (table == null) return null;
    return ((table['999'] as num) * proba / 1000 * weight * 100).round() / 100;
  }

  static String? _phone(String? raw) {
    var d = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length == 9) d = '992$d';
    return d.length == 12 && d.startsWith('992') ? '+$d' : null;
  }

  String _newSession(int userId) {
    final rnd = math.Random.secure();
    final token = List.generate(24, (_) => rnd.nextInt(16).toRadixString(16)).join();
    _sessions[token] = userId;
    _persist();
    return token;
  }

  (int, Object?) _login(Map<String, dynamic> b) {
    final phone = _phone(b['phone'] as String?);
    if (phone == null) return _err(422);
    final user = _users.where((u) => u['phone'] == phone).firstOrNull;
    if (user == null || _passwords[phone] != b['password']) return _err(401);
    return (200, {'token': _newSession(user['id'] as int), 'user': user});
  }

  (int, Object?) _register(Map<String, dynamic> b) {
    final phone = _phone(b['phone'] as String?);
    final name = (b['name'] as String? ?? '').trim();
    final password = b['password'] as String? ?? '';
    if (phone == null || name.length < 2 || password.length < 6) return _err(422);
    if (_users.any((u) => u['phone'] == phone)) return _err(409);
    final user = {
      'id': _users.map((u) => u['id'] as int).reduce(math.max) + 1,
      'name': name,
      'phone': phone,
      'is_shop': b['is_shop'] == true,
    };
    _users.add(user);
    _passwords[phone] = password;
    return (200, {'token': _newSession(user['id'] as int), 'user': user});
  }

  (int, Object?) _create(Map<String, dynamic> b, Map<String, dynamic> user) {
    final ids = _listings.map((l) => l['id'] as int);
    final listing = {
      'id': math.max(10000, ids.reduce(math.max)) + 1,
      'user_id': user['id'],
      'title': (b['title'] as String).trim(),
      'description': ((b['description'] as String?) ?? '').trim(),
      'category': b['category'],
      'metal': b['metal'],
      'proba': b['proba'],
      'weight': b['weight'],
      'stone': b['stone'] ?? 'none',
      'condition': b['condition'] ?? 'new',
      'price': b['price'],
      'city': b['city'],
      'phone': _phone(b['phone'] as String?) ?? user['phone'],
      'images': b['images'] ?? [],
      'featured': false,
      'views': 0,
      'created_at': _fmt(DateTime.now().toUtc()),
      'seller_name': user['name'],
      'is_shop': user['is_shop'],
    };
    _listings.add(listing);
    _persist();
    return (201, listing);
  }

  (int, Object?) _delete(int id, Map<String, dynamic> user) {
    final l = _listings.where((l) => l['id'] == id).firstOrNull;
    if (l == null) return _err(404);
    if (l['user_id'] != user['id']) return _err(403);
    _listings.remove(l);
    _deleted.add(id);
    _persist();
    return (204, null);
  }

  Future<(int, Object?)> _upload(http.MultipartRequest req) async {
    final file = req.files.first;
    final bytes = await file.finalize().toBytes();
    final type = file.contentType.mimeType;
    return (201, {'url': 'data:$type;base64,${base64Encode(bytes)}'});
  }
}
