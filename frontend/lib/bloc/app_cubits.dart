import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/api.dart';
import '../data/models.dart';

// ---------------- Танзимот: ранг ва забон ----------------

class SettingsState extends Equatable {
  const SettingsState({this.dark = false, this.lang = Lang.ru});
  final bool dark;
  final Lang lang;
  @override
  List<Object?> get props => [dark, lang];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs)
      : super(SettingsState(
          dark: _prefs.getBool(_darkKey) ?? false,
          lang: Lang.values.asNameMap()[_prefs.getString(_langKey)] ?? Lang.ru,
        )) {
    _apply(state);
  }

  final SharedPreferences _prefs;
  static const _darkKey = 'dark';
  static const _langKey = 'lang';

  static void _apply(SettingsState s) {
    Gold.dark = s.dark;
    currentLang = s.lang;
  }

  void toggleTheme() => _set(SettingsState(dark: !state.dark, lang: state.lang));

  void setLang(Lang lang) => _set(SettingsState(dark: state.dark, lang: lang));

  void _set(SettingsState s) {
    _apply(s);
    _prefs.setBool(_darkKey, s.dark);
    _prefs.setString(_langKey, s.lang.name);
    emit(s);
  }
}

// ---------------- Meta (категорияҳо, шаҳрҳо ...) ----------------

class MetaState extends Equatable {
  const MetaState({this.meta, this.error});
  final Meta? meta;
  final String? error;
  @override
  List<Object?> get props => [meta, error];
}

class MetaCubit extends Cubit<MetaState> {
  MetaCubit(this._api) : super(const MetaState());
  final TilloApi _api;

  Future<void> load() async {
    try {
      emit(MetaState(meta: await _api.meta()));
    } on ApiException catch (e) {
      emit(MetaState(meta: state.meta, error: e.message));
    }
  }
}

// ---------------- Нархи тилло (худкор ҳар 5 дақиқа) ----------------

class GoldCubit extends Cubit<GoldQuote?> {
  GoldCubit(this._api) : super(null);
  final TilloApi _api;
  Timer? _timer;

  Future<void> start() async {
    await refresh();
    _timer ??= Timer.periodic(const Duration(minutes: 5), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      emit(await _api.goldPrice());
    } on ApiException {
      // Нархи охиринро нигоҳ медорем.
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

// ---------------- Аутентификатсия ----------------

class AuthState extends Equatable {
  const AuthState({this.user, this.loading = false, this.error});
  final User? user;
  final bool loading;
  final String? error;
  bool get isLoggedIn => user != null;
  @override
  List<Object?> get props => [user, loading, error];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._api, this._prefs) : super(const AuthState());
  final TilloApi _api;
  final SharedPreferences _prefs;
  static const _key = 'auth_token';

  Future<void> restore() async {
    final token = _prefs.getString(_key);
    if (token == null) return;
    _api.token = token;
    try {
      emit(AuthState(user: await _api.me()));
    } on ApiException catch (e) {
      if (e.status == 401) await logout();
    }
  }

  Future<bool> login(String phone, String password) =>
      _run(() => _api.login(phone, password));

  Future<bool> register(String name, String phone, String password, bool isShop) =>
      _run(() => _api.register(name, phone, password, isShop));

  Future<bool> _run(Future<(String, User)> Function() call) async {
    emit(const AuthState(loading: true));
    try {
      final (token, user) = await call();
      _api.token = token;
      await _prefs.setString(_key, token);
      emit(AuthState(user: user));
      return true;
    } on ApiException catch (e) {
      emit(AuthState(error: e.message));
      return false;
    }
  }

  Future<void> logout() async {
    _api.token = null;
    await _prefs.remove(_key);
    emit(const AuthState());
  }
}

// ---------------- Дӯстдоштаҳо (дар браузер нигоҳ дошта мешаванд) ----------------

class FavoritesCubit extends Cubit<Set<int>> {
  FavoritesCubit(this._prefs)
      : super((_prefs.getStringList(_key) ?? const []).map(int.parse).toSet());
  final SharedPreferences _prefs;
  static const _key = 'favorites';

  void toggle(int id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    _prefs.setStringList(_key, next.map((e) => '$e').toList());
    emit(next);
  }
}
