import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/app_cubits.dart';
import '../../bloc/listing_cubits.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../shell.dart';
import '../widgets/gold.dart';
import '../widgets/gold_price.dart';
import '../widgets/listing_card.dart';

// ---------------- Вход / Регистрация ----------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.next});
  final String? next;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+992 ');
  final _pass = TextEditingController();
  bool _register = false;
  bool _isShop = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthCubit>();
    final ok = _register
        ? await auth.register(_name.text.trim(), _phone.text, _pass.text, _isShop)
        : await auth.login(_phone.text, _pass.text);
    if (ok && mounted) context.go(widget.next ?? '/profile');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final compact = isCompact(context);
    return ListView(padding: EdgeInsets.symmetric(vertical: compact ? 24 : 56), children: [
      Constrained(
        maxWidth: 460,
        child: Container(
          padding: EdgeInsets.all(compact ? 22 : 30),
          decoration: cardDecoration(radius: 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Center(child: Logo(size: 32)),
              const SizedBox(height: 8),
              Center(child: Text(t('auth.welcome'), style: Gold.display(24, color: Gold.muted))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(t('auth.login'))),
                    ButtonSegment(value: true, label: Text(t('auth.register'))),
                  ],
                  selected: {_register},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _register = s.first),
                  style: segmentedStyle(),
                ),
              ),
              const SizedBox(height: 22),
              if (_register) ...[
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: t('auth.name'), prefixIcon: const Icon(Icons.person_outline)),
                  validator: (v) => (v ?? '').trim().length < 2 ? t('auth.name.err') : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t('auth.phone'), prefixIcon: const Icon(Icons.phone_outlined)),
                validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? t('auth.phone.err') : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _obscure,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: t('auth.password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v ?? '').length < 6 ? t('auth.password.err') : null,
              ),
              if (_register) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isShop,
                  onChanged: (v) => setState(() => _isShop = v),
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('auth.is_shop')),
                ),
              ],
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(auth.error!, style: const TextStyle(color: Gold.danger)),
              ],
              const SizedBox(height: 22),
              GoldButton(
                label: _register ? t('auth.submit.register') : t('auth.submit.login'),
                expand: true,
                loading: auth.loading,
                onPressed: _submit,
              ),
              if (AppConfig.demo && !_register) ...[
                const SizedBox(height: 16),
                Text(t('auth.demo'), textAlign: TextAlign.center, style: TextStyle(color: Gold.muted, fontSize: 12)),
              ],
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ---------------- Избранное ----------------

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ids = context.watch<FavoritesCubit>().state;
    return BlocProvider(
      key: ValueKey((ids.toList()..sort()).join(',')),
      create: (_) => ListCubit(context.read<TilloApi>(), () => {'ids': ids.join(',')}, perPage: 60)..load(),
      child: ListView(children: [
        Constrained(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: isCompact(context) ? 20 : 28),
            SectionTitle(t('fav.title'), subtitle: t('fav.sub')),
            if (ids.isEmpty)
              EmptyState(
                icon: Icons.favorite_border,
                title: t('fav.empty'),
                text: t('fav.empty.d'),
                action: GoldButton(label: t('item.catalog'), onPressed: () => context.go('/catalog')),
              )
            else
              BlocBuilder<ListCubit, ListState>(
                builder: (context, s) => s.items == null
                    ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                    : ListingGrid(s.items!),
              ),
          ]),
        ),
        const Footer(),
      ]),
    );
  }
}

// ---------------- Профиль ----------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user!;
    final compact = isCompact(context);
    return BlocProvider(
      create: (_) => ListCubit(context.read<TilloApi>(), () => {'mine': 'true'}, perPage: 60)..load(),
      child: ListView(children: [
        Constrained(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: compact ? 20 : 28),
            Container(
              padding: EdgeInsets.all(compact ? 18 : 24),
              decoration: cardDecoration(radius: 22).copyWith(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Gold.gold.withValues(alpha: .12), Gold.surface],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(gradient: Gold.gradient, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(user.name.characters.first.toUpperCase(),
                        style: Gold.display(32, color: Gold.onGold, weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.name, style: Gold.display(compact ? 26 : 30), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${prettyPhone(user.phone)}${user.isShop ? '  ·  ${t('profile.shop')}' : ''}',
                          style: TextStyle(color: Gold.muted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: GoldButton(
                      label: t('profile.new'),
                      icon: Icons.add,
                      expand: true,
                      onPressed: () => context.go('/post'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GhostButton(
                    label: t('profile.logout'),
                    icon: Icons.logout,
                    onPressed: () {
                      context.read<AuthCubit>().logout();
                      context.go('/');
                    },
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 32),
            SectionTitle(t('profile.mine')),
            BlocBuilder<ListCubit, ListState>(
              builder: (context, s) {
                if (s.items == null) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                if (s.items!.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: t('profile.empty'),
                    text: t('profile.empty.d'),
                  );
                }
                return ListingGrid(
                  s.items!,
                  trailing: (l) => InkWell(
                    onTap: () => _confirmDelete(context, l.id),
                    child: const Icon(Icons.delete_outline, size: 18, color: Gold.danger),
                  ),
                );
              },
            ),
          ]),
        ),
        const Footer(),
      ]),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final cubit = context.read<ListCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete.title')),
        content: Text(t('delete.text')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('no'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('delete.yes'), style: const TextStyle(color: Gold.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await cubit.delete(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
