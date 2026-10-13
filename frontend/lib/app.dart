import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bloc/app_cubits.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
import 'data/models.dart';
import 'ui/pages/account_pages.dart';
import 'ui/pages/catalog_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/listing_page.dart';
import 'ui/pages/post_page.dart';
import 'ui/shell.dart';

GoRouter buildRouter(AuthCubit auth) => GoRouter(
      refreshListenable: _StreamListenable(auth.stream),
      redirect: (context, state) {
        const private = {'/post', '/profile'};
        if (private.contains(state.matchedLocation) && !auth.state.isLoggedIn) {
          return '/login?next=${Uri.encodeQueryComponent(state.matchedLocation)}';
        }
        if (state.matchedLocation == '/login' && auth.state.isLoggedIn) {
          return state.uri.queryParameters['next'] ?? '/profile';
        }
        return null;
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
          routes: [
            GoRoute(path: '/', pageBuilder: (_, s) => _fade(s, const HomePage())),
            GoRoute(
              path: '/catalog',
              pageBuilder: (_, s) {
                final q = s.uri.queryParameters;
                return _fade(
                  s,
                  CatalogPage(
                    key: ValueKey(s.uri.toString()),
                    initial: ListingFilter(q: q['q'] ?? '', category: q['category']),
                    focusSearch: q['focus'] == '1',
                  ),
                );
              },
            ),
            GoRoute(
              path: '/item/:id',
              pageBuilder: (_, s) {
                final id = int.tryParse(s.pathParameters['id']!) ?? 0;
                return _fade(s, ListingPage(key: ValueKey(id), id: id));
              },
            ),
            GoRoute(path: '/post', pageBuilder: (_, s) => _fade(s, const PostPage())),
            GoRoute(path: '/favorites', pageBuilder: (_, s) => _fade(s, const FavoritesPage())),
            GoRoute(path: '/profile', pageBuilder: (_, s) => _fade(s, const ProfilePage())),
            GoRoute(
              path: '/login',
              pageBuilder: (_, s) => _fade(s, LoginPage(next: s.uri.queryParameters['next'])),
            ),
          ],
        ),
      ],
    );

CustomTransitionPage<void> _fade(GoRouterState s, Widget child) => CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .015), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class TilloApp extends StatefulWidget {
  const TilloApp({super.key});
  @override
  State<TilloApp> createState() => _TilloAppState();
}

class _TilloAppState extends State<TilloApp> {
  late final _router = buildRouter(context.read<AuthCubit>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SettingsCubit, SettingsState>(
        // Ранг ва забон дар getter-ҳои глобалӣ — бо key ҳамаи дарахт аз нав сохта мешавад.
        builder: (context, s) => MaterialApp.router(
          key: ValueKey('${s.dark}-${s.lang.name}'),
          title: t('app.title'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          routerConfig: _router,
        ),
      );
}
