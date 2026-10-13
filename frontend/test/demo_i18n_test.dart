import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tillo/core/format.dart';
import 'package:tillo/core/i18n.dart';
import 'package:tillo/data/api.dart';
import 'package:tillo/data/demo_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => currentLang = Lang.ru);

  test('се забон: калидҳо, категорияҳо, шаҳрҳо, параметрҳо', () {
    currentLang = Lang.ru;
    expect(t('nav.catalog'), 'Каталог');
    expect(categoryName('rings'), 'Кольца');
    expect(cityName('Хуҷанд'), 'Худжанд');
    expect(t('catalog.found', {'n': 5}), 'Найдено: 5');
    currentLang = Lang.tg;
    expect(categoryName('rings'), 'Ангуштарин');
    expect(timeAgo(DateTime.now().toUtc().subtract(const Duration(hours: 3))), '3 соат пеш');
    currentLang = Lang.en;
    expect(stoneName('spinel'), 'Badakhshan spinel');
    expect(money(1500).endsWith('TJS'), isTrue);
  });

  test('DemoClient бе сервер кор мекунад: рӯйхат, филтр, воридшавӣ, эълони нав', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = TilloApi(client: DemoClient(prefs), base: 'http://demo');

    final meta = await api.meta();
    expect(meta.categories, hasLength(12));

    final bullion = await api.listings({'category': 'bullion', 'sort': 'price_asc'});
    final prices = bullion.items.map((l) => l.price).toList();
    expect(bullion.total, greaterThan(0));
    expect(prices, [...prices]..sort());

    final search = await api.listings({'q': 'БРИЛЛИАНТ'});
    expect(search.total, greaterThan(0));

    await expectLater(api.login('900000001', 'wrong!'), throwsA(isA<ApiException>()));
    final (token, user) = await api.login('+992 90 000 00 01', 'tillo123');
    api.token = token;
    expect(user.isShop, isTrue);

    final created = await api.createListing({
      'title': 'Тестовое кольцо',
      'category': 'rings',
      'metal': 'gold',
      'proba': 585,
      'weight': 2.0,
      'price': 3000,
      'city': 'Душанбе',
      'images': <String>[],
    });
    final mine = await api.listings({'mine': 'true'});
    expect(mine.items.map((l) => l.id), contains(created.id));

    final detail = await api.listing(created.id);
    expect(detail.metalValue, greaterThan(0));

    await api.deleteListing(created.id);
    expect((await api.listings({'mine': 'true'})).items.map((l) => l.id), isNot(contains(created.id)));
  });
}
