import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/app_cubits.dart';
import '../../bloc/catalog_bloc.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../shell.dart';
import '../widgets/gold.dart';
import '../widgets/gold_price.dart';
import '../widgets/listing_card.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key, required this.initial, this.focusSearch = false});
  final ListingFilter initial;
  final bool focusSearch;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CatalogBloc(context.read<TilloApi>(), initial)..add(CatalogFilterChanged(initial)),
        child: _CatalogView(focusSearch: focusSearch),
      );
}

const _sorts = ['new', 'price_asc', 'price_desc', 'popular'];

class _CatalogView extends StatefulWidget {
  const _CatalogView({required this.focusSearch});
  final bool focusSearch;
  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  final _scroll = ScrollController();
  late final _search = TextEditingController(text: context.read<CatalogBloc>().state.filter.q);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 900) context.read<CatalogBloc>().add(const CatalogNextPage());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _update(ListingFilter f) => context.read<CatalogBloc>().add(CatalogFilterChanged(f));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogBloc>().state;
    final wide = isWide(context);
    final compact = isCompact(context);
    final f = state.filter;
    final title = f.category != null ? categoryName(f.category!) : t('catalog.all');

    final grid = switch (state.status) {
      CatalogStatus.loading => const SliverFillRemaining(
          hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
      CatalogStatus.failure => SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.cloud_off,
            title: t('error'),
            text: state.error,
            action: GhostButton(label: t('retry'), onPressed: () => _update(f)),
          )),
      _ when state.items.isEmpty => SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: t('catalog.empty'),
            text: t('catalog.empty.d'),
            action: GhostButton(label: t('catalog.reset'), onPressed: () => _update(const ListingFilter())),
          )),
      _ => SliverLayoutBuilder(
          builder: (context, c) => SliverGrid.builder(
            gridDelegate: listingGridDelegate(c.crossAxisExtent),
            itemCount: state.items.length,
            itemBuilder: (_, i) => ListingCard(state.items[i]),
          ),
        ),
    };

    final toolbarBox = BoxDecoration(
      color: Gold.dark ? Gold.surface2 : Gold.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Gold.line),
    );

    final content = CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: compact ? 18 : 24),
            Text(title, style: Gold.display(wide ? 44 : (compact ? 30 : 36))),
            const SizedBox(height: 2),
            Text(
              state.status == CatalogStatus.loading ? t('catalog.searching') : t('catalog.found', {'n': state.total}),
              style: TextStyle(color: Gold.muted, fontSize: 13),
            ),
            SizedBox(height: compact ? 14 : 18),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  autofocus: widget.focusSearch,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) => _update(f.copyWith(q: v)),
                  decoration: InputDecoration(
                    hintText: t('catalog.search'),
                    prefixIcon: Icon(Icons.search, color: Gold.muted),
                    isDense: true,
                    suffixIcon: f.q.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _search.clear();
                              _update(f.copyWith(q: ''));
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: t('sort'),
                initialValue: f.sort,
                position: PopupMenuPosition.under,
                onSelected: (s) => _update(f.copyWith(sort: s)),
                itemBuilder: (_) => [for (final s in _sorts) PopupMenuItem(value: s, child: Text(t('sort.$s')))],
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: toolbarBox,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.swap_vert, size: 20, color: Gold.accent),
                    if (wide) ...[const SizedBox(width: 8), Text(t('sort.${f.sort}'))],
                  ]),
                ),
              ),
              if (!wide) ...[
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openFilters(context),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: toolbarBox.copyWith(
                      border: Border.all(color: f.activeCount > 0 ? Gold.gold : Gold.line),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.tune, size: 20, color: Gold.accent),
                      if (f.activeCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(gradient: Gold.gradient, borderRadius: BorderRadius.circular(10)),
                          child: Text('${f.activeCount}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Gold.onGold)),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _CatChip(t('all'), f.category == null, () => _update(f.copyWith(category: () => null))),
                for (final slug in context.watch<MetaCubit>().state.meta?.categories.map((c) => c.slug) ?? <String>[])
                  _CatChip(categoryName(slug), f.category == slug, () => _update(f.copyWith(category: () => slug)),
                      icon: categoryIcon(slug)),
              ]),
            ),
            SizedBox(height: compact ? 14 : 20),
          ]),
        ),
        grid,
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: state.loadingMore
                  ? const CircularProgressIndicator()
                  : (state.status == CatalogStatus.ready && !state.hasMore && state.items.isNotEmpty)
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const Diamond(),
                          const SizedBox(width: 10),
                          Text(t('catalog.end'), style: TextStyle(color: Gold.muted, fontSize: 12)),
                          const SizedBox(width: 10),
                          const Diamond(),
                        ])
                      : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );

    return Constrained(
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 270,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 24, bottom: 24, right: 24),
                  child: FilterPanel(filter: f, onChanged: _update),
                ),
              ),
              Expanded(child: content),
            ])
          : content,
    );
  }

  void _openFilters(BuildContext context) {
    final bloc = context.read<CatalogBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .88,
          maxChildSize: .95,
          builder: (ctx, scroll) => BlocBuilder<CatalogBloc, CatalogState>(
            builder: (ctx, s) => Column(children: [
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [FilterPanel(filter: s.filter, onChanged: _update)],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Gold.line))),
                child: GoldButton(
                  label: t('catalog.show', {'n': s.total}),
                  expand: true,
                  loading: s.status == CatalogStatus.loading,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip(this.label, this.selected, this.onTap, {this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          avatar: icon == null ? null : Icon(icon, size: 16, color: Gold.accent),
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          side: BorderSide(color: selected ? Gold.gold : Gold.line),
        ),
      );
}

/// Панели филтрҳо (десктоп — паҳлӯ, мобайл — bottom sheet).
class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key, required this.filter, required this.onChanged});
  final ListingFilter filter;
  final ValueChanged<ListingFilter> onChanged;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late final _min = TextEditingController(text: widget.filter.minPrice?.toString() ?? '');
  late final _max = TextEditingController(text: widget.filter.maxPrice?.toString() ?? '');

  @override
  void didUpdateWidget(FilterPanel old) {
    super.didUpdateWidget(old);
    if (widget.filter.minPrice == null && _min.text.isNotEmpty) _min.clear();
    if (widget.filter.maxPrice == null && _max.text.isNotEmpty) _max.clear();
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _applyPrice() => widget.onChanged(widget.filter.copyWith(
        minPrice: () => int.tryParse(_min.text.replaceAll(' ', '')),
        maxPrice: () => int.tryParse(_max.text.replaceAll(' ', '')),
      ));

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<MetaCubit>().state.meta;
    if (meta == null) return const SizedBox.shrink();
    final f = widget.filter;
    final on = widget.onChanged;

    Widget group(String title, List<Widget> chips) => Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(),
                style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: Gold.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ]),
        );

    Widget chip<T>(String label, T value, T? current, ValueChanged<T?> set) => FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: current == value,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: current == value ? Gold.gold : Gold.line),
          onSelected: (sel) => set(sel ? value : null),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(t('filters'), style: Gold.display(26)),
        const Spacer(),
        if (f.activeCount > 0) TextButton(onPressed: () => on(f.clearExtras()), child: Text(t('filters.clear'))),
      ]),
      const SizedBox(height: 14),
      group(t('f.price'), [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _min,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: t('f.from'), isDense: true),
              onSubmitted: (_) => _applyPrice(),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('—')),
          Expanded(
            child: TextField(
              controller: _max,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: t('f.to'), isDense: true),
              onSubmitted: (_) => _applyPrice(),
            ),
          ),
          IconButton(onPressed: _applyPrice, icon: Icon(Icons.check, color: Gold.accent)),
        ]),
      ]),
      group(t('f.metal'), [
        for (final m in meta.metals.where((m) => m.slug != 'none'))
          chip(metalName(m.slug), m.slug, f.metal, (v) => on(f.copyWith(metal: () => v))),
      ]),
      group(t('f.proba'), [
        for (final p in meta.probas) chip('$p', p, f.proba, (v) => on(f.copyWith(proba: () => v))),
      ]),
      group(t('f.stone'), [
        for (final s in meta.stones) chip(stoneName(s.slug), s.slug, f.stone, (v) => on(f.copyWith(stone: () => v))),
      ]),
      group(t('f.condition'), [
        for (final c in meta.conditions)
          chip(conditionName(c.slug), c.slug, f.condition, (v) => on(f.copyWith(condition: () => v))),
      ]),
      group(t('f.city'), [
        for (final c in meta.cities) chip(cityName(c), c, f.city, (v) => on(f.copyWith(city: () => v))),
      ]),
    ]);
  }
}
