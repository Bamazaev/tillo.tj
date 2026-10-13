import 'package:flutter/foundation.dart';

/// Суроғаи API.
/// * `--dart-define=API_URL=https://api.tillo.tj` — ҳар вақт аввалиндараҷа.
/// * Дар release-и веб — ҳамон домене, ки сайт аз он кушода шудааст.
/// * Дар debug — сервери маҳаллӣ дар порти 8000.
class AppConfig {
  static const _fromEnv = String.fromEnvironment('API_URL');

  /// Версияи намоишӣ бе сервер (GitHub Pages): `--dart-define=DEMO=true`.
  static const demo = bool.fromEnvironment('DEMO');

  /// Рақами версия (deploy). Ба URL-ҳо илова мешавад, то браузер файли кӯҳнаро аз кеш нагирад.
  static const buildId = String.fromEnvironment('BUILD_ID');

  static String _v(String url) => buildId.isEmpty ? url : '$url?v=$buildId';

  static String get apiBase {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (kIsWeb && kReleaseMode) return Uri.base.origin;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static String imageUrl(String path) {
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    // Демо: роҳи нисбӣ (demo/5.jpg) — нисбат ба base href-и сайт.
    if (!path.startsWith('/')) return _v(path);
    return '$apiBase$path';
  }
}
