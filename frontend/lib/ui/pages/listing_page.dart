import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/listing_cubits.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../shell.dart';
import '../widgets/gold.dart';
import '../widgets/gold_price.dart';
import '../widgets/listing_card.dart';

class ListingPage extends StatelessWidget {
  const ListingPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ListingCubit(context.read<TilloApi>(), id)..load(),
        child: BlocBuilder<ListingCubit, ListingState>(
          builder: (context, s) {
            if (s.error != null) {
              return EmptyState(
                icon: Icons.search_off,
                title: s.error!,
                action: GhostButton(label: t('item.catalog'), onPressed: () => context.go('/catalog')),
              );
            }
            if (s.listing == null) return const Center(child: CircularProgressIndicator());
            return isCompact(context) ? _MobileDetails(s.listing!) : _Details(s.listing!);
          },
        ),
      );
}

void _call(Listing l) => launchUrl(Uri.parse('tel:${l.phone}'));

void _whatsapp(Listing l) => launchUrl(
      Uri.parse('https://wa.me/${l.phone.replaceAll('+', '')}?text=${Uri.encodeComponent(t('item.wa_text', {'t': l.title}))}'),
      mode: LaunchMode.externalApplication,
    );

void _share(BuildContext context) {
  Clipboard.setData(ClipboardData(text: Uri.base.toString()));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('item.copied'))));
}

// ---------------- Десктоп ва планшет ----------------

class _Details extends StatelessWidget {
  const _Details(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return ListView(children: [
      const SizedBox(height: 20),
      Constrained(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Breadcrumbs(l),
          const SizedBox(height: 16),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 11, child: _Gallery(l, radius: 24)),
              const SizedBox(width: 40),
              Expanded(flex: 9, child: _Info(l)),
            ])
          else ...[
            _Gallery(l, radius: 24),
            const SizedBox(height: 24),
            _Info(l),
          ],
          if (l.similar.isNotEmpty) ...[
            const SizedBox(height: 56),
            SectionTitle(t('item.similar'), subtitle: t('item.similar.sub')),
            ListingGrid(l.similar),
          ],
        ]),
      ),
      const Footer(),
    ]);
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: Gold.muted, fontSize: 13);
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      InkWell(onTap: () => context.go('/'), child: Text(t('nav.home'), style: style)),
      Text('  /  ', style: style),
      InkWell(
        onTap: () => context.go('/catalog?category=${l.category}'),
        child: Text(categoryName(l.category), style: style.copyWith(color: Gold.accent)),
      ),
    ]);
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery(this.l, {this.radius = 0, this.overlay});
  final Listing l;
  final double radius;
  final Widget? overlay;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final count = l.images.isEmpty ? 1 : l.images.length;
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(fit: StackFit.expand, children: [
            PageView.builder(
              controller: _page,
              itemCount: count,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => i == 0
                  ? Hero(tag: 'img-${l.id}', child: ListingImage(l, index: i))
                  : ListingImage(l, index: i),
            ),
            if (l.featured)
              const Positioned(top: 16, left: 16, child: Pill('VIP', icon: Icons.workspace_premium, gold: true)),
            if (count > 1)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? Gold.gold : Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ]),
              ),
            ?widget.overlay,
          ]),
        ),
      ),
      if (count > 1 && !isCompact(context)) ...[
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _page.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              child: Container(
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: i == _index ? Gold.gold : Gold.line, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListingImage(l, index: i),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _Info extends StatefulWidget {
  const _Info(this.l);
  final Listing l;
  @override
  State<_Info> createState() => _InfoState();
}

class _InfoState extends State<_Info> {
  bool _showPhone = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final outlined = IconButton.styleFrom(
      side: BorderSide(color: Gold.line),
      backgroundColor: Gold.surface,
      padding: const EdgeInsets.all(14),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _TitleBlock(l),
      const SizedBox(height: 20),
      GoldText(money(l.price), style: Gold.display(52, weight: FontWeight.w700)),
      const SizedBox(height: 14),
      MetalValueBox(l),
      const SizedBox(height: 20),
      _Specs(l),
      const SizedBox(height: 20),
      _Seller(l),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: GoldButton(
            label: _showPhone ? prettyPhone(l.phone) : t('item.show_phone'),
            icon: Icons.call,
            expand: true,
            onPressed: () => _showPhone ? _call(l) : setState(() => _showPhone = true),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'WhatsApp',
          style: outlined,
          onPressed: () => _whatsapp(l),
          icon: Icon(Icons.chat_outlined, color: Gold.accent),
        ),
        const SizedBox(width: 10),
        FavButton(l.id, size: 50),
        const SizedBox(width: 10),
        IconButton(
          tooltip: t('item.share'),
          style: outlined,
          onPressed: () => _share(context),
          icon: Icon(Icons.share_outlined, color: Gold.accent),
        ),
      ]),
      _Description(l),
    ]);
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: Gold.muted, fontSize: 13);
    final compact = isCompact(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.title, style: Gold.display(compact ? 28 : (isWide(context) ? 40 : 34))),
      const SizedBox(height: 8),
      Wrap(spacing: 14, runSpacing: 4, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.schedule, size: 14, color: Gold.muted),
          const SizedBox(width: 4),
          Text(timeAgo(l.createdAt), style: style),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.visibility_outlined, size: 14, color: Gold.muted),
          const SizedBox(width: 4),
          Text('${l.views}', style: style),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.place_outlined, size: 14, color: Gold.muted),
          const SizedBox(width: 4),
          Text(cityName(l.city), style: style),
        ]),
        Text('№ ${l.id}', style: style),
      ]),
    ]);
  }
}

class _Specs extends StatelessWidget {
  const _Specs(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) {
    final specs = <(String, String)>[
      (t('f.category'), categoryName(l.category)),
      if (l.metal != 'none') (t('f.metal'), metalName(l.metal)),
      if (l.proba != null) (t('f.proba'), '${l.proba}'),
      if (l.weight != null) (t('f.weight'), grams(l.weight!)),
      if (l.stone != 'none') (t('f.stone'), stoneName(l.stone)),
      (t('f.condition'), conditionName(l.condition)),
      (t('f.city'), cityName(l.city)),
      if (l.pricePerGram != null && l.metal != 'none') (t('f.price_gram'), money(l.pricePerGram!)),
    ];
    return Container(
      decoration: cardDecoration(),
      child: Column(children: [
        for (var i = 0; i < specs.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              border: i == specs.length - 1 ? null : Border(bottom: BorderSide(color: Gold.line)),
            ),
            child: Row(children: [
              Text(specs[i].$1, style: TextStyle(color: Gold.muted)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(specs[i].$2, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (l.description.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(t('item.description'), style: Gold.display(26)),
          const SizedBox(height: 8),
          SelectableText(l.description, style: TextStyle(height: 1.65, color: Gold.text.withValues(alpha: .85))),
        ],
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Gold.gold.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Gold.gold.withValues(alpha: .3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.shield_outlined, color: Gold.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(t('item.safety'), style: TextStyle(fontSize: 13, color: Gold.muted, height: 1.5)),
            ),
          ]),
        ),
      ]);
}

class _Seller extends StatelessWidget {
  const _Seller(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(radius: 16),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: l.isShop ? Gold.gradient : null,
              color: l.isShop ? null : Gold.surface2,
            ),
            child: Icon(l.isShop ? Icons.storefront : Icons.person, color: l.isShop ? Gold.onGold : Gold.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.sellerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(l.isShop ? t('item.shop') : t('item.private'), style: TextStyle(color: Gold.muted, fontSize: 12)),
            ]),
          ),
          if (l.isShop) Pill(t('item.shop_badge'), icon: Icons.storefront_outlined),
        ]),
      );
}

// ---------------- Мобайл: сурат то канор, панели поёнии часпанда ----------------

class _MobileDetails extends StatelessWidget {
  const _MobileDetails(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            _Gallery(
              l,
              overlay: Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(children: [
                  if (context.canPop())
                    RoundIconButton(size: 40, icon: Icons.arrow_back, onPressed: context.pop),
                  const Spacer(),
                  RoundIconButton(size: 40, icon: Icons.share_outlined, onPressed: () => _share(context)),
                  const SizedBox(width: 8),
                  FavButton(l.id, size: 40),
                ]),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                decoration: BoxDecoration(
                  color: Gold.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _TitleBlock(l),
                  const SizedBox(height: 14),
                  GoldText(money(l.price), style: Gold.display(40, weight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  MetalValueBox(l),
                  const SizedBox(height: 16),
                  _Specs(l),
                  const SizedBox(height: 16),
                  _Seller(l),
                  _Description(l),
                  if (l.similar.isNotEmpty) ...[
                    const SizedBox(height: 36),
                    SectionTitle(t('item.similar'), subtitle: t('item.similar.sub')),
                    ListingCarousel(l.similar),
                  ],
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ]),
        ),
        _ContactBar(l),
      ]);
}

class _ContactBar extends StatelessWidget {
  const _ContactBar(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Gold.surface,
          border: Border(top: BorderSide(color: Gold.line)),
        ),
        child: Row(children: [
          SizedBox.square(
            dimension: 48,
            child: IconButton(
              tooltip: 'WhatsApp',
              onPressed: () => _whatsapp(l),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF25D366).withValues(alpha: .12),
                side: BorderSide(color: const Color(0xFF25D366).withValues(alpha: .4)),
              ),
              icon: const Icon(Icons.chat, color: Color(0xFF1FAF55)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: GoldButton(label: t('item.call'), icon: Icons.call, expand: true, onPressed: () => _call(l))),
        ]),
      );
}
