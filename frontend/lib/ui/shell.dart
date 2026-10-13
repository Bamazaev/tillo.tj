import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/app_cubits.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import 'widgets/gold.dart';
import 'widgets/gold_price.dart';

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.go('/'),
        borderRadius: BorderRadius.circular(8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          GoldIcon(Icons.diamond, size: size * .9),
          const SizedBox(width: 8),
          GoldText('TILLO', style: Gold.display(size, weight: FontWeight.w700).copyWith(letterSpacing: 3)),
          Text('.tj', style: Gold.display(size * .7, color: Gold.muted)),
        ]),
      );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  int get _tab => switch (location) {
        '/' => 0,
        final l when l.startsWith('/catalog') => 1,
        '/post' => 2,
        '/favorites' => 3,
        '/profile' || '/login' => 4,
        _ => -1,
      };

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Scaffold(
      body: Column(children: [
        const GoldTicker(),
        _Header(wide: wide),
        Expanded(child: child),
      ]),
      // Дар саҳифаи эълон панели тамос ҷои менюро мегирад.
      bottomNavigationBar: wide || location.startsWith('/item')
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Gold.line)),
                boxShadow: Gold.dark
                    ? const []
                    : [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: NavigationBar(
                height: 66,
                selectedIndex: _tab < 0 ? 0 : _tab,
                indicatorColor: _tab < 0 ? Colors.transparent : null,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (i) =>
                    context.go(const ['/', '/catalog', '/post', '/favorites', '/profile'][i]),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: t('nav.home'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.grid_view_outlined),
                    selectedIcon: const Icon(Icons.grid_view_rounded),
                    label: t('nav.catalog'),
                  ),
                  NavigationDestination(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: Gold.gradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Gold.gold.withValues(alpha: .4), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.add, color: Gold.onGold, size: 20),
                    ),
                    label: t('nav.post'),
                  ),
                  NavigationDestination(
                    icon: const _FavIcon(),
                    selectedIcon: const _FavIcon(selected: true),
                    label: t('nav.favorites'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person),
                    label: t('nav.profile'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FavIcon extends StatelessWidget {
  const _FavIcon({this.selected = false});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final n = context.watch<FavoritesCubit>().state.length;
    return Badge(
      isLabelVisible: n > 0,
      label: Text('$n'),
      backgroundColor: Gold.gold,
      textColor: Gold.onGold,
      child: Icon(selected ? Icons.favorite : Icons.favorite_border),
    );
  }
}

/// Интихоби забон: RU · TJ · EN.
class LangButton extends StatelessWidget {
  const LangButton({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsCubit>().state.lang;
    return PopupMenuButton<Lang>(
      tooltip: t('language'),
      initialValue: lang,
      position: PopupMenuPosition.under,
      onSelected: context.read<SettingsCubit>().setLang,
      itemBuilder: (_) => [
        for (final l in Lang.values)
          PopupMenuItem(
            value: l,
            child: Row(children: [
              SizedBox(
                width: 30,
                child: Text(l.code, style: TextStyle(fontWeight: FontWeight.w800, color: Gold.accent, fontSize: 12)),
              ),
              Text(l.label),
              if (l == lang) ...[const Spacer(), Icon(Icons.check, size: 18, color: Gold.accent)],
            ]),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Gold.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Gold.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.translate, size: 16, color: Gold.accent),
          const SizedBox(width: 6),
          Text(lang.code, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Gold.text)),
        ]),
      ),
    );
  }
}

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<SettingsCubit>().state.dark;
    return RoundIconButton(
      size: size,
      tooltip: dark ? t('theme.light') : t('theme.dark'),
      icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      color: Gold.accent,
      onPressed: context.read<SettingsCubit>().toggleTheme,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    return Container(
      decoration: BoxDecoration(
        color: Gold.dark ? Gold.bg : Gold.surface,
        border: Border(bottom: BorderSide(color: Gold.line)),
      ),
      child: Constrained(
        child: SizedBox(
          height: wide ? 76 : 60,
          child: Row(children: [
            Logo(size: wide ? 30 : 23),
            if (wide) ...[
              const SizedBox(width: 28),
              const Expanded(child: HeaderSearch()),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => context.go('/catalog'),
                icon: const Icon(Icons.grid_view_outlined, size: 18),
                label: Text(t('nav.catalog')),
                style: TextButton.styleFrom(foregroundColor: Gold.text),
              ),
              IconButton(
                tooltip: t('nav.favorites'),
                onPressed: () => context.go('/favorites'),
                icon: const _FavIcon(),
                color: Gold.text,
              ),
              IconButton(
                tooltip: auth.isLoggedIn ? auth.user!.name : t('nav.login'),
                onPressed: () => context.go(auth.isLoggedIn ? '/profile' : '/login'),
                icon: Icon(auth.isLoggedIn ? Icons.person : Icons.person_outline),
                color: Gold.text,
              ),
              const SizedBox(width: 6),
              const LangButton(),
              const SizedBox(width: 8),
              const ThemeButton(),
              const SizedBox(width: 12),
              GoldButton(label: t('post.cta'), icon: Icons.add, onPressed: () => context.go('/post')),
            ] else ...[
              const Spacer(),
              const LangButton(),
              const SizedBox(width: 8),
              const ThemeButton(size: 40),
              const SizedBox(width: 8),
              RoundIconButton(
                size: 40,
                tooltip: t('search'),
                icon: Icons.search,
                onPressed: () => context.go('/catalog?focus=1'),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class HeaderSearch extends StatefulWidget {
  const HeaderSearch({super.key, this.large = false});
  final bool large;
  @override
  State<HeaderSearch> createState() => _HeaderSearchState();
}

class _HeaderSearchState extends State<HeaderSearch> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    final q = _ctrl.text.trim();
    context.go(q.isEmpty ? '/catalog' : '/catalog?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.large ? Gold.softShadow : const [],
        ),
        child: TextField(
          controller: _ctrl,
          onSubmitted: (_) => _go(),
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: widget.large ? 15 : 14),
          decoration: InputDecoration(
            hintText: t('search.hint'),
            fillColor: Gold.dark ? Gold.surface2 : (widget.large ? Gold.surface : Gold.surface2),
            prefixIcon: Icon(Icons.search, color: Gold.muted),
            isDense: !widget.large,
            contentPadding: widget.large ? const EdgeInsets.symmetric(vertical: 18) : null,
            suffixIcon: Padding(
              padding: const EdgeInsets.all(5),
              child: IconButton.filled(
                onPressed: _go,
                style: IconButton.styleFrom(backgroundColor: Gold.gold, foregroundColor: Gold.onGold),
                icon: const Icon(Icons.arrow_forward, size: 18),
              ),
            ),
          ),
        ),
      );
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 56),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Gold.dark ? null : Gold.surface,
          border: Border(top: BorderSide(color: Gold.line)),
        ),
        child: Constrained(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 24,
            children: [
              const Logo(size: 22),
              Text('© ${DateTime.now().year} ${t('footer.copy')}', style: TextStyle(color: Gold.muted, fontSize: 12)),
              Text(t('footer.note'), style: TextStyle(color: Gold.muted, fontSize: 12)),
              if (AppConfig.demo) Text(t('demo.banner'), style: TextStyle(color: Gold.accent, fontSize: 12)),
            ],
          ),
        ),
      );
}
