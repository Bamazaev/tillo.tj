import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/app_cubits.dart';
import '../../bloc/listing_cubits.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/gold.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => PostCubit(context.read<TilloApi>()),
        child: BlocConsumer<PostCubit, PostState>(
          listenWhen: (a, b) => a.status != b.status || (b.error != null && a.error != b.error),
          listener: (context, s) {
            if (s.status == PostStatus.done) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('post.done'))));
              context.go('/item/${s.created!.id}');
            } else if (s.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!)));
            }
          },
          builder: (context, s) {
            final meta = context.watch<MetaCubit>().state.meta;
            if (meta == null) return const Center(child: CircularProgressIndicator());
            return _PostForm(meta: meta);
          },
        ),
      );
}

class _PostForm extends StatefulWidget {
  const _PostForm({required this.meta});
  final Meta meta;
  @override
  State<_PostForm> createState() => _PostFormState();
}

class _PostFormState extends State<_PostForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _weight = TextEditingController();
  late final _phone = TextEditingController(text: context.read<AuthCubit>().state.user?.phone ?? '');
  String? _category;
  String _metal = 'gold';
  int? _proba = 585;
  String _stone = 'none';
  String _condition = 'new';
  String _city = 'Душанбе';

  @override
  void dispose() {
    for (final c in [_title, _desc, _price, _weight, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _weightValue => double.tryParse(_weight.text.replaceAll(',', '.'));

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<PostCubit>().submit({
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'category': _category,
      'metal': _metal,
      'proba': _metal == 'none' ? null : _proba,
      'weight': _weightValue,
      'stone': _stone,
      'condition': _condition,
      'price': int.parse(_price.text.replaceAll(RegExp(r'\D'), '')),
      'city': _city,
      'phone': _phone.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meta;
    final post = context.watch<PostCubit>().state;
    final quote = context.watch<GoldCubit>().state;
    final compact = isCompact(context);
    final w = _weightValue;
    final hint = (quote != null && w != null && _proba != null && _metal != 'none' && _metal != 'platinum')
        ? quote.value(metal: _metal == 'silver' ? 'silver' : 'gold', proba: _proba!, weight: w)
        : null;

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Text(text.toUpperCase(),
              style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: Gold.muted, fontWeight: FontWeight.w700)),
        );

    Widget chips<T>(List<(T, String)> items, T current, ValueChanged<T> set) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (v, name) in items)
              ChoiceChip(
                label: Text(name),
                selected: current == v,
                showCheckmark: false,
                side: BorderSide(color: current == v ? Gold.gold : Gold.line),
                onSelected: (_) => setState(() => set(v)),
              ),
          ],
        );

    Widget section(List<Widget> children) => Container(
          margin: const EdgeInsets.only(top: 16),
          padding: EdgeInsets.fromLTRB(compact ? 16 : 22, 0, compact ? 16 : 22, compact ? 18 : 22),
          decoration: cardDecoration(radius: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );

    return ListView(padding: EdgeInsets.symmetric(vertical: compact ? 20 : 32), children: [
      Constrained(
        maxWidth: 760,
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('post.title'), style: Gold.display(compact ? 34 : 44)),
            Text(t('post.sub'), style: TextStyle(color: Gold.muted)),
            section([
              label(t('post.photos', {'n': PostCubit.maxImages})),
              _Photos(images: post.images),
              label(t('f.category')),
              FormField<String>(
                validator: (_) => _category == null ? t('post.category.err') : null,
                builder: (field) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  chips([for (final c in m.categories) (c.slug, categoryName(c.slug))], _category, (v) {
                    _category = v;
                    field.didChange(v);
                    if (v == 'gems') {
                      _metal = 'none';
                      _proba = null;
                    } else if (v == 'silver') {
                      _metal = 'silver';
                      _proba = 925;
                    }
                  }),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(field.errorText!, style: const TextStyle(color: Gold.danger, fontSize: 12)),
                    ),
                ]),
              ),
              label(t('post.title_f')),
              TextFormField(
                controller: _title,
                maxLength: 120,
                decoration: InputDecoration(hintText: t('post.title.hint')),
                validator: (v) => (v ?? '').trim().length < 3 ? t('post.title.err') : null,
              ),
            ]),
            section([
              label(t('f.metal')),
              chips([for (final x in m.metals) (x.slug, metalName(x.slug))], _metal, (v) {
                _metal = v;
                if (v == 'none') {
                  _proba = null;
                } else if (v == 'silver') {
                  _proba = 925;
                } else if (v == 'platinum') {
                  _proba = 950;
                } else if (_proba == null || _proba == 925 || _proba == 950) {
                  _proba = 585;
                }
              }),
              if (_metal != 'none') ...[
                label(t('f.proba')),
                chips([for (final p in m.probas) (p, '$p')], _proba, (v) => _proba = v),
              ],
              label(t('post.weight_price')),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: InputDecoration(labelText: t('f.weight'), suffixText: t('gram')),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return _metal == 'none' ? null : t('post.weight.err');
                      return (_weightValue ?? 0) > 0 ? null : t('post.number.err');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t('post.price'), suffixText: t('post.somoni')),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : t('post.price.err'),
                  ),
                ),
              ]),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: Gold.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(t('metal.value', {'v': money(hint)}),
                          style: TextStyle(color: Gold.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _price.text = '${hint.round()}'),
                      child: Text(t('post.use')),
                    ),
                  ]),
                ),
              label(t('f.stone')),
              chips([for (final x in m.stones) (x.slug, stoneName(x.slug))], _stone, (v) => _stone = v),
              label(t('f.condition')),
              chips([for (final x in m.conditions) (x.slug, conditionName(x.slug))], _condition, (v) => _condition = v),
            ]),
            section([
              label(t('f.city')),
              DropdownButtonFormField<String>(
                initialValue: _city,
                dropdownColor: Gold.surface,
                items: [for (final c in m.cities) DropdownMenuItem(value: c, child: Text(cityName(c)))],
                onChanged: (v) => setState(() => _city = v!),
              ),
              label(t('post.description')),
              TextFormField(
                controller: _desc,
                maxLines: 5,
                maxLength: 4000,
                decoration: InputDecoration(hintText: t('post.description.hint')),
              ),
              label(t('post.phone')),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? t('auth.phone.err') : null,
              ),
            ]),
            const SizedBox(height: 26),
            GoldButton(
              label: post.status == PostStatus.sending ? t('post.sending') : t('post.submit'),
              icon: Icons.publish,
              expand: true,
              loading: post.status == PostStatus.sending,
              onPressed: _submit,
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.images});
  final List<PickedImage> images;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostCubit>();
    final size = isCompact(context) ? 92.0 : 100.0;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (var i = 0; i < images.length; i++)
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(images[i].bytes, width: size, height: size, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => cubit.removeImage(i),
              child: CircleAvatar(radius: 12, backgroundColor: Gold.surface, child: const Icon(Icons.close, size: 14)),
            ),
          ),
          if (i == 0) Positioned(bottom: 6, left: 6, child: Pill(t('post.main_photo'), gold: true)),
        ]),
      if (images.length < PostCubit.maxImages)
        InkWell(
          onTap: cubit.pickImages,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Gold.gold.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Gold.gold.withValues(alpha: .5)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_a_photo_outlined, color: Gold.accent),
              const SizedBox(height: 6),
              Text(t('post.add_photo'), style: TextStyle(fontSize: 12, color: Gold.muted)),
            ]),
          ),
        ),
    ]);
  }
}
