import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/demo_client.dart';
import 'bloc/app_cubits.dart';
import 'data/api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final api = TilloApi(client: AppConfig.demo ? DemoClient(prefs) : null);
  final settings = SettingsCubit(prefs);
  final auth = AuthCubit(api, prefs);
  await auth.restore().timeout(const Duration(seconds: 3), onTimeout: () {});

  runApp(
    RepositoryProvider.value(
      value: api,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider.value(value: auth),
          BlocProvider(create: (_) => MetaCubit(api)..load()),
          BlocProvider(create: (_) => GoldCubit(api)..start()),
          BlocProvider(create: (_) => FavoritesCubit(prefs)),
        ],
        child: const TilloApp(),
      ),
    ),
  );
}
