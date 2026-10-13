import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tillo/bloc/catalog_bloc.dart';
import 'package:tillo/core/format.dart';
import 'package:tillo/data/api.dart';
import 'package:tillo/data/models.dart';

Map<String, dynamic> _item(int id, {int price = 1000}) => {
      'id': id,
      'user_id': 1,
      'title': 'Ангуштарин $id',
      'description': '',
      'category': 'rings',
      'metal': 'gold',
      'proba': 585,
      'weight': 3.5,
      'stone': 'none',
      'condition': 'new',
      'price': price,
      'city': 'Душанбе',
      'phone': '+992900000001',
      'images': <String>[],
      'featured': false,
      'views': 1,
      'created_at': '2026-10-13 10:00:00',
      'seller_name': 'Заргар',
      'is_shop': true,
    };

void main() {
  test('CatalogBloc: филтр ва саҳифаи навбатӣ', () async {
    final requests = <Uri>[];
    final client = MockClient((req) async {
      requests.add(req.url);
      final page = int.parse(req.url.queryParameters['page']!);
      final items = page == 1 ? List.generate(24, (i) => _item(i + 1)) : [_item(25)];
      return http.Response(jsonEncode({'items': items, 'total': 25, 'page': page, 'per_page': 24}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final api = TilloApi(client: client, base: 'http://x');
    const filter = ListingFilter(category: 'rings', proba: 585, sort: 'price_asc');
    final bloc = CatalogBloc(api, filter)..add(const CatalogFilterChanged(filter));

    await expectLater(bloc.stream, emitsThrough(predicate<CatalogState>((s) => s.status == CatalogStatus.ready)));
    expect(bloc.state.items, hasLength(24));
    expect(bloc.state.hasMore, isTrue);
    expect(requests.first.queryParameters, containsPair('proba', '585'));
    expect(requests.first.queryParameters, containsPair('sort', 'price_asc'));

    bloc.add(const CatalogNextPage());
    await expectLater(bloc.stream, emitsThrough(predicate<CatalogState>((s) => s.items.length == 25)));
    expect(bloc.state.hasMore, isFalse);
    await bloc.close();
  });

  test('ApiException матни хатогии сервериро медиҳад', () async {
    final api = TilloApi(
      client: MockClient((_) async => http.Response(
            jsonEncode({'detail': 'server text'}),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
      base: 'http://x',
    );
    expect(
      () => api.login('900000001', 'x'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Неверный номер или пароль')
          .having((e) => e.status, 'status', 401)),
    );
  });

  test('ListingFilter: тоза кардани қиматҳо', () {
    const f = ListingFilter(category: 'rings', metal: 'gold', minPrice: 100);
    final g = f.copyWith(metal: () => null);
    expect(g.metal, isNull);
    expect(g.category, 'rings');
    expect(g.activeCount, 1);
    expect(f.clearExtras().activeCount, 0);
    expect(f.toQuery().containsKey('metal'), isTrue);
  });

  test('формат', () {
    expect(grams(10), '10 г');
    expect(grams(3.5), '3.5 г');
    expect(grams(7.78), '7.78 г');
    expect(prettyPhone('+992900000001'), '+992 90 000 00 01');
    expect(money(12500).replaceAll(RegExp(r'\s'), ' '), '12 500 с.');
  });
}
