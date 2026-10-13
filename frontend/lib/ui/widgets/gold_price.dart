import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/app_cubits.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import 'gold.dart';

/// Сатри нархҳои зинда дар болои сайт (ҳамеша торик — ҳамчун лентаи биржа).
class GoldTicker extends StatelessWidget {
  const GoldTicker({super.key});

  @override
  Widget build(BuildContext context) {
    final q = context.watch<GoldCubit>().state;
    final g = t('per_gram');
    final items = q == null
        ? [(t('ticker.gold'), t('ticker.loading'))]
        : [
            ('${t('ticker.gold')} 999', '${money(q.goldPerGram[999]!)}$g'),
            ('750', '${money(q.goldPerGram[750]!)}$g'),
            ('585', '${money(q.goldPerGram[585]!)}$g'),
            ('583', '${money(q.goldPerGram[583]!)}$g'),
            ('${t('ticker.silver')} 925', '${money(q.silverPerGram[925]!)}$g'),
            ('XAU', '\$${NumberFormat('#,##0.00', 'en').format(q.usdPerOz)}'),
            ('USD', '${q.tjsPerUsd.toStringAsFixed(2)} ${t('currency')}'),
          ];
    return Container(
      height: 32,
      color: const Color(0xFF0E0C08),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _LiveDot(live: q?.live ?? false),
        ),
        Expanded(
          child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, .92, 1],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: Diamond()),
              ),
              itemBuilder: (_, i) => Center(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${items[i].$1}  ', style: const TextStyle(color: Color(0xFFA39A86), fontSize: 11.5)),
                  TextSpan(
                    text: items[i].$2,
                    style: const TextStyle(color: Gold.light, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ])),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? const Color(0xFF3DDC84) : const Color(0xFFA39A86);
    return Tooltip(
      message: live ? t('ticker.live_tip') : t('ticker.offline_tip'),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: live ? [BoxShadow(color: color.withValues(alpha: .6), blurRadius: 6)] : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(live ? t('ticker.live') : t('ticker.offline'),
            style: const TextStyle(
                fontSize: 10, letterSpacing: 1.2, color: Color(0xFFA39A86), fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Ҷудокунандаи хурди алмосшакл.
class Diamond extends StatelessWidget {
  const Diamond({super.key, this.size = 5, this.color = Gold.deep});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: .785398,
        child: Container(width: size, height: size, color: color),
      );
}

/// Ҳисобкунаки арзиши тилло: вазн × проба × нархи биржа.
class GoldCalculator extends StatefulWidget {
  const GoldCalculator({super.key});
  @override
  State<GoldCalculator> createState() => _GoldCalculatorState();
}

class _GoldCalculatorState extends State<GoldCalculator> {
  String _metal = 'gold';
  int _proba = 585;
  double _weight = 5;
  final _ctrl = TextEditingController(text: '5');

  static const _goldProbas = [375, 500, 583, 585, 750, 916, 958, 999];
  static const _silverProbas = [875, 925, 999];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = context.watch<GoldCubit>().state;
    final compact = isCompact(context);
    final probas = _metal == 'gold' ? _goldProbas : _silverProbas;
    final value = q?.value(metal: _metal, proba: _proba, weight: _weight) ?? 0;
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: Gold.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Gold.dark ? Gold.line : Gold.gold.withValues(alpha: .35)),
        boxShadow: Gold.dark
            ? const []
            : [BoxShadow(color: Gold.gold.withValues(alpha: .14), blurRadius: 40, offset: const Offset(0, 16))],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Gold.gold.withValues(alpha: Gold.dark ? .08 : .10), Gold.surface, Gold.surface],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const GoldIcon(Icons.calculate_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text(t('calc.title'), style: Gold.display(compact ? 24 : 26))),
        ]),
        const SizedBox(height: 4),
        Text(t('calc.subtitle'), style: TextStyle(color: Gold.muted, fontSize: 13)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'gold', label: Text(t('calc.gold'))),
              ButtonSegment(value: 'silver', label: Text(t('calc.silver'))),
            ],
            selected: {_metal},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() {
              _metal = s.first;
              _proba = _metal == 'gold' ? 585 : 925;
            }),
            style: segmentedStyle(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final p in probas)
            ChoiceChip(
              label: Text('$p'),
              selected: _proba == p,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: _proba == p ? Gold.gold : Gold.line),
              onSelected: (_) => setState(() => _proba = p),
            ),
        ]),
        const SizedBox(height: 14),
        TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t('calc.weight'), suffixText: t('grams')),
          onChanged: (v) => setState(() => _weight = double.tryParse(v.replaceAll(',', '.')) ?? 0),
        ),
        const SizedBox(height: 16),
        Text(t('calc.value'), style: TextStyle(color: Gold.muted, fontSize: 12)),
        TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: GoldText(money(v), style: Gold.display(compact ? 38 : 44, weight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 6),
        if (q != null)
          Text('1 ${t('gram')} $_proba = ${money(q.value(metal: _metal, proba: _proba, weight: 1))}',
              style: TextStyle(color: Gold.muted, fontSize: 12)),
      ]),
    );
  }
}

ButtonStyle segmentedStyle() => SegmentedButton.styleFrom(
      selectedBackgroundColor: Gold.gold.withValues(alpha: Gold.dark ? .2 : .22),
      selectedForegroundColor: Gold.dark ? Gold.light : Gold.text,
      foregroundColor: Gold.muted,
      backgroundColor: Gold.dark ? null : Gold.surface,
      side: BorderSide(color: Gold.line),
    );

/// Муқоисаи нархи эълон бо арзиши металл.
class MetalValueBox extends StatelessWidget {
  const MetalValueBox(this.listing, {super.key});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final value = listing.metalValue;
    if (value == null || value <= 0) return const SizedBox.shrink();
    final ratio = listing.price / value;
    final note = ratio < 1.05 ? t('metal.close') : t('metal.premium', {'p': ((ratio - 1) * 100).round()});
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Gold.gold.withValues(alpha: Gold.dark ? .07 : .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Gold.gold.withValues(alpha: .3)),
      ),
      child: Row(children: [
        const GoldIcon(Icons.insights_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('metal.value', {'v': money(value)}), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(note, style: TextStyle(color: Gold.muted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
