import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/app_cubits.dart';
import '../../bloc/listing_cubits.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../shell.dart';
import '../widgets/gold.dart';
import '../widgets/gold_price.dart';
import '../widgets/listing_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<TilloApi>();
    final gap = SizedBox(height: isCompact(context) ? 40 : 64);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ListCubit(api, () => {'featured': 'true', 'sort': 'popular'}, perPage: 8)..load(),
        ),
        BlocProvider(create: (_) => _NewCubit(api)..load()),
      ],
      child: ListView(
        children: [
          const _Hero(),
          gap,
          const Constrained(child: _Categories()),
          gap,
          const Constrained(child: _FeaturedSection()),
          gap,
          const Constrained(child: _NewSection()),
          gap,
          const Constrained(child: _Trust()),
          const Footer(),
        ],
      ),
    );
  }
}

class _NewCubit extends ListCubit {
  _NewCubit(TilloApi api) : super(api, () => {'sort': 'new'}, perPage: 12);
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final compact = isCompact(context);
    final meta = context.watch<MetaCubit>().state.meta;
    final total = meta?.categories.fold<int>(0, (s, c) => s + c.count);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pill(t('hero.badge'), icon: Icons.verified_outlined),
        SizedBox(height: compact ? 16 : 22),
        ShimmerGoldText(
          t('hero.title'),
          style: Gold.display(wide ? 84 : (compact ? 50 : 64), weight: FontWeight.w700).copyWith(height: .98),
        ),
        SizedBox(height: compact ? 14 : 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Text(
            t('hero.text'),
            style: TextStyle(color: Gold.muted, fontSize: compact ? 14.5 : 16, height: 1.6),
          ),
        ),
        SizedBox(height: compact ? 20 : 28),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: const HeaderSearch(large: true)),
        const SizedBox(height: 16),
        if (compact)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GoldButton(
              label: t('hero.catalog'),
              icon: Icons.diamond_outlined,
              expand: true,
              onPressed: () => context.go('/catalog'),
            ),
            const SizedBox(height: 10),
            GhostButton(
              label: t('hero.sell'),
              icon: Icons.sell_outlined,
              expand: true,
              onPressed: () => context.go('/post'),
            ),
          ])
        else
          Wrap(spacing: 12, runSpacing: 12, children: [
            GoldButton(label: t('hero.catalog'), icon: Icons.diamond_outlined, onPressed: () => context.go('/catalog')),
            GhostButton(label: t('hero.sell'), icon: Icons.sell_outlined, onPressed: () => context.go('/post')),
          ]),
        if (total != null) ...[
          SizedBox(height: compact ? 22 : 32),
          Wrap(spacing: compact ? 22 : 36, runSpacing: 12, children: [
            _Stat('$total', t('stat.listings')),
            _Stat('${meta!.cities.length}', t('stat.cities')),
            const _Stat('24/7', 'online'),
          ]),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: Gold.dark
            ? const RadialGradient(
                center: Alignment(.75, -.7),
                radius: 1.1,
                colors: [Color(0x24D4AF37), Color(0x08D4AF37), Color(0x00D4AF37)],
                stops: [0, .5, .95],
              )
            : const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFFF6EBD2), Color(0xFFFBF6EC), Color(0xFFFAF7F1)],
                stops: [0, .45, 1],
              ),
      ),
      padding: EdgeInsets.symmetric(vertical: wide ? 72 : (compact ? 28 : 44)),
      child: Constrained(
        child: wide
            ? Row(children: [
                Expanded(flex: 6, child: text),
                const SizedBox(width: 48),
                const Expanded(flex: 4, child: GoldCalculator()),
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [text, SizedBox(height: compact ? 28 : 36), const GoldCalculator()],
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GoldText(value, style: Gold.display(isCompact(context) ? 28 : 34, weight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Gold.muted, fontSize: 12, letterSpacing: .4)),
      ]);
}

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<MetaCubit>().state.meta;
    final width = MediaQuery.sizeOf(context).width;
    final compact = isCompact(context);
    final cols = width >= 1100 ? 6 : (width >= 700 ? 4 : 4);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(t('home.categories'), subtitle: t('home.categories.sub')),
      if (meta == null)
        const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
      else
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: compact ? 14 : 12,
          crossAxisSpacing: compact ? 8 : 12,
          childAspectRatio: compact ? .78 : 1.15,
          children: [
            for (final c in meta.categories)
              compact ? _CategoryBubble(c.slug, c.count) : _CategoryTile(c.slug, c.count),
          ],
        ),
    ]);
  }
}

/// Мобайл: доираи тиллоӣ + ном.
class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble(this.slug, this.count);
  final String slug;
  final int count;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/catalog?category=$slug'),
        child: Column(children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Gold.surface,
                border: Border.all(color: Gold.gold.withValues(alpha: .35)),
                boxShadow: Gold.softShadow,
                gradient: RadialGradient(
                  colors: [Gold.gold.withValues(alpha: Gold.dark ? .14 : .12), Gold.surface],
                ),
              ),
              child: Center(child: GoldIcon(categoryIcon(slug), size: 26)),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            categoryName(slug),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2),
          ),
        ]),
      );
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile(this.slug, this.count);
  final String slug;
  final int count;
  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _hover ? Gold.gold : Gold.line),
            boxShadow: Gold.softShadow,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _hover ? Gold.gold.withValues(alpha: .14) : (Gold.dark ? Gold.surface2 : Gold.surface),
                Gold.surface,
              ],
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.go('/catalog?category=${widget.slug}'),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedScale(
                    scale: _hover ? 1.12 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: GoldIcon(categoryIcon(widget.slug), size: 34),
                  ),
                  const SizedBox(height: 10),
                  Text(categoryName(widget.slug),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(t('n.listings', {'n': widget.count}), style: TextStyle(color: Gold.muted, fontSize: 11)),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context) =>
      _ListSection<ListCubit>(title: t('home.vip'), subtitle: t('home.vip.sub'), carouselOnMobile: true);
}

class _NewSection extends StatelessWidget {
  const _NewSection();

  @override
  Widget build(BuildContext context) => _ListSection<_NewCubit>(title: t('home.new'), subtitle: t('home.new.sub'));
}

class _ListSection<C extends ListCubit> extends StatelessWidget {
  const _ListSection({super.key, required this.title, required this.subtitle, this.carouselOnMobile = false});
  final String title;
  final String subtitle;
  final bool carouselOnMobile;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<C>().state;
    final compact = isCompact(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(
        title,
        subtitle: subtitle,
        action: TextButton(
          onPressed: () => context.go('/catalog'),
          child: Text(compact ? '${t('all')} →' : '${t('see_all')} →'),
        ),
      ),
      if (state.items == null && state.error == null)
        const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
      else if (state.items == null)
        EmptyState(
          icon: Icons.cloud_off,
          title: t('server.down'),
          text: state.error,
          action: GhostButton(label: t('retry'), onPressed: () => context.read<C>().load()),
        )
      else if (compact && carouselOnMobile)
        ListingCarousel(state.items!)
      else
        ListingGrid(state.items!),
    ]);
  }
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.verified_user_outlined, 'trust.1'),
      (Icons.trending_up, 'trust.2'),
      (Icons.storefront_outlined, 'trust.3'),
      (Icons.bolt_outlined, 'trust.4'),
    ];
    final compact = isCompact(context);
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 4 : 2;
      final gap = compact ? 10.0 : 16.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final (icon, key) in items)
          Container(
            width: w,
            padding: EdgeInsets.all(compact ? 16 : 22),
            decoration: cardDecoration(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Gold.gold.withValues(alpha: .12), shape: BoxShape.circle),
                child: Icon(icon, color: Gold.accent, size: compact ? 20 : 24),
              ),
              SizedBox(height: compact ? 10 : 14),
              Text(t('$key.t'), style: Gold.display(compact ? 19 : 22)),
              const SizedBox(height: 6),
              Text(t('$key.d'), style: TextStyle(color: Gold.muted, fontSize: compact ? 12 : 13, height: 1.5)),
            ]),
          ),
      ]);
    });
  }
}
