import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/app_cubits.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import 'gold.dart';

class ListingImage extends StatelessWidget {
  const ListingImage(this.listing, {super.key, this.index = 0, this.fit = BoxFit.cover, this.decodeWidth = 480});
  final Listing listing;
  final int index;
  final BoxFit fit;

  /// Паҳнои декод (px). Корт — 480, галерея — 1080.
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    final art = JewelArt(
      category: listing.category,
      stone: listing.stone,
      metal: listing.metal,
      seed: listing.id + index,
    );
    if (listing.images.length <= index) return art;
    final url = listing.images[index];
    if (url.startsWith('data:')) {
      return Image.memory(
        UriData.parse(url).contentAsBytes(),
        fit: fit,
        cacheWidth: decodeWidth,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => art,
      );
    }
    return Image.network(
      AppConfig.imageUrl(url),
      fit: fit,
      cacheWidth: decodeWidth,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => art,
      // Пайдошавии нарм ба ҷои «ҷаҳиш».
      frameBuilder: (_, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: frame == null ? ColoredBox(color: Gold.surface2) : child,
            ),
    );
  }
}

String specLine(Listing l) => [
  if (l.proba != null) '${l.proba}',
  if (l.weight != null) grams(l.weight!),
  if (l.stone != 'none') stoneName(l.stone),
].join(' · ');

class FavButton extends StatelessWidget {
  const FavButton(this.id, {super.key, this.size = 36});
  final int id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fav = context.select<FavoritesCubit, bool>((c) => c.state.contains(id));
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: fav ? t('fav.remove') : t('fav.add'),
        onPressed: () => context.read<FavoritesCubit>().toggle(id),
        style: IconButton.styleFrom(backgroundColor: Gold.surface.withValues(alpha: .85)),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Icon(
            fav ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(fav),
            size: size * .52,
            color: fav ? Gold.accent : Gold.text,
          ),
        ),
      ),
    );
  }
}

class ListingCard extends StatefulWidget {
  const ListingCard(this.listing, {super.key, this.trailing});
  final Listing listing;
  final Widget? trailing;

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final compact = isCompact(context);
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Gold.surface,
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(color: _hover ? Gold.gold.withValues(alpha: .7) : Gold.line),
            boxShadow: [
              if (_hover)
                BoxShadow(color: Gold.gold.withValues(alpha: .16), blurRadius: 30, offset: const Offset(0, 12))
              else
                ...Gold.softShadow,
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => context.push('/item/${l.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(tag: 'img-${l.id}', child: ListingImage(l)),
                        if (l.featured)
                          Positioned(
                            top: compact ? 8 : 10,
                            left: compact ? 8 : 10,
                            child: const Pill('VIP', icon: Icons.workspace_premium, gold: true),
                          ),
                        if (l.isShop && !compact)
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Pill(l.sellerName, icon: Icons.storefront_outlined),
                            ),
                          ),
                        Positioned(
                          top: compact ? 6 : 8,
                          right: compact ? 6 : 8,
                          child: FavButton(l.id, size: compact ? 32 : 36),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: compact
                        ? const EdgeInsets.fromLTRB(11, 9, 11, 11)
                        : const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoldText(
                          money(l.price),
                          maxLines: 1,
                          style: Gold.display(compact ? 21 : 24, weight: FontWeight.w700),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        Text(
                          l.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: compact ? 13 : 14, height: 1.3, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: compact ? 5 : 8),
                        Text(
                          specLine(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 11.5 : 12,
                            color: Gold.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 13, color: Gold.muted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${cityName(l.city)} · ${timeAgo(l.createdAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: compact ? 11 : 12, color: Gold.muted),
                              ),
                            ),
                            ?widget.trailing,
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Тӯри эълонҳо: [width] — паҳнои дастраси мундариҷа.
SliverGridDelegate listingGridDelegate(double width) {
  final cols = width >= 1080
      ? 4
      : width >= 740
      ? 3
      : 2;
  final compact = width < 560;
  final gap = compact ? 10.0 : 20.0;
  final tile = (width - gap * (cols - 1)) / cols;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: cols,
    mainAxisSpacing: compact ? 12 : gap,
    crossAxisSpacing: gap,
    mainAxisExtent: tile + (compact ? 126 : 148), // сурати мураббаъ + матн
  );
}

class ListingGrid extends StatelessWidget {
  const ListingGrid(this.items, {super.key, this.trailing});
  final List<Listing> items;
  final Widget Function(Listing)? trailing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: listingGridDelegate(c.maxWidth),
      itemCount: items.length,
      itemBuilder: (_, i) => ListingCard(items[i], trailing: trailing?.call(items[i])),
    ),
  );
}

/// Рӯйхати уфуқӣ (барои мобайл дар саҳифаи асосӣ).
class ListingCarousel extends StatelessWidget {
  const ListingCarousel(this.items, {super.key});
  final List<Listing> items;

  @override
  Widget build(BuildContext context) {
    const w = 190.0;
    return SizedBox(
      height: w + 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(width: w, child: ListingCard(items[i])),
      ),
    );
  }
}
