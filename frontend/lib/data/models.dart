import 'package:equatable/equatable.dart';

class Option extends Equatable {
  const Option(this.slug, this.name, {this.count = 0});
  final String slug;
  final String name;
  final int count;

  factory Option.fromJson(Map<String, dynamic> j) =>
      Option(j['slug'] as String, j['name'] as String, count: (j['count'] as int?) ?? 0);

  @override
  List<Object?> get props => [slug, name, count];
}

class Meta {
  const Meta({
    required this.categories,
    required this.metals,
    required this.probas,
    required this.stones,
    required this.conditions,
    required this.cities,
  });

  final List<Option> categories;
  final List<Option> metals;
  final List<int> probas;
  final List<Option> stones;
  final List<Option> conditions;
  final List<String> cities;

  factory Meta.fromJson(Map<String, dynamic> j) {
    List<Option> opts(String k) =>
        (j[k] as List).map((e) => Option.fromJson(e as Map<String, dynamic>)).toList();
    return Meta(
      categories: opts('categories'),
      metals: opts('metals'),
      probas: (j['probas'] as List).cast<int>(),
      stones: opts('stones'),
      conditions: opts('conditions'),
      cities: (j['cities'] as List).cast<String>(),
    );
  }

  static String _name(List<Option> list, String slug) =>
      list.firstWhere((o) => o.slug == slug, orElse: () => Option(slug, slug)).name;

  String category(String slug) => _name(categories, slug);
  String metal(String slug) => _name(metals, slug);
  String stone(String slug) => _name(stones, slug);
  String condition(String slug) => _name(conditions, slug);
}

class GoldQuote extends Equatable {
  const GoldQuote({
    required this.usdPerOz,
    required this.silverUsdPerOz,
    required this.tjsPerUsd,
    required this.goldPerGram,
    required this.silverPerGram,
    required this.live,
    required this.updatedAt,
  });

  final double usdPerOz;
  final double silverUsdPerOz;
  final double tjsPerUsd;
  final Map<int, double> goldPerGram;
  final Map<int, double> silverPerGram;
  final bool live;
  final DateTime updatedAt;

  factory GoldQuote.fromJson(Map<String, dynamic> j) {
    Map<int, double> m(String k) => (j[k] as Map<String, dynamic>)
        .map((key, v) => MapEntry(int.parse(key), (v as num).toDouble()));
    return GoldQuote(
      usdPerOz: (j['usd_per_oz'] as num).toDouble(),
      silverUsdPerOz: (j['silver_usd_per_oz'] as num).toDouble(),
      tjsPerUsd: (j['tjs_per_usd'] as num).toDouble(),
      goldPerGram: m('gold_per_gram'),
      silverPerGram: m('silver_per_gram'),
      live: j['live'] as bool,
      updatedAt: DateTime.parse(j['updated_at'] as String),
    );
  }

  /// Арзиши металл: вазн × проба × нархи 999.
  double value({required String metal, required int proba, required double weight}) {
    final base = metal == 'silver' ? silverPerGram[999]! : goldPerGram[999]!;
    return base * proba / 1000 * weight;
  }

  @override
  List<Object?> get props => [usdPerOz, tjsPerUsd, updatedAt];
}

class User extends Equatable {
  const User({required this.id, required this.name, required this.phone, required this.isShop});
  final int id;
  final String name;
  final String phone;
  final bool isShop;

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        name: j['name'] as String,
        phone: j['phone'] as String,
        isShop: (j['is_shop'] as bool?) ?? false,
      );

  @override
  List<Object?> get props => [id, name, phone, isShop];
}

class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.metal,
    required this.proba,
    required this.weight,
    required this.stone,
    required this.condition,
    required this.price,
    required this.city,
    required this.phone,
    required this.images,
    required this.featured,
    required this.views,
    required this.createdAt,
    required this.sellerName,
    required this.isShop,
    this.metalValue,
    this.similar = const [],
  });

  final int id;
  final int userId;
  final String title;
  final String description;
  final String category;
  final String metal;
  final int? proba;
  final double? weight;
  final String stone;
  final String condition;
  final int price;
  final String city;
  final String phone;
  final List<String> images;
  final bool featured;
  final int views;
  final DateTime createdAt;
  final String sellerName;
  final bool isShop;
  final double? metalValue;
  final List<Listing> similar;

  /// Нархи як грамм (барои муқоиса бо нархи биржа).
  double? get pricePerGram => (weight ?? 0) > 0 ? price / weight! : null;

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
        id: j['id'] as int,
        userId: j['user_id'] as int,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        category: j['category'] as String,
        metal: j['metal'] as String,
        proba: j['proba'] as int?,
        weight: (j['weight'] as num?)?.toDouble(),
        stone: j['stone'] as String,
        condition: j['condition'] as String,
        price: j['price'] as int,
        city: j['city'] as String,
        phone: j['phone'] as String,
        images: (j['images'] as List).cast<String>(),
        featured: j['featured'] as bool,
        views: j['views'] as int,
        // SQLite datetime('now') бе минтақа аст, вале UTC.
        createdAt: DateTime.parse('${(j['created_at'] as String).replaceFirst(' ', 'T')}Z'),
        sellerName: (j['seller_name'] as String?) ?? '',
        isShop: (j['is_shop'] as bool?) ?? false,
        metalValue: (j['metal_value'] as num?)?.toDouble(),
        similar: ((j['similar'] as List?) ?? const [])
            .map((e) => Listing.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, views, price];
}

class ListingsPage {
  const ListingsPage(this.items, this.total, this.page);
  final List<Listing> items;
  final int total;
  final int page;
}

class ListingFilter extends Equatable {
  const ListingFilter({
    this.q = '',
    this.category,
    this.metal,
    this.proba,
    this.stone,
    this.city,
    this.condition,
    this.minPrice,
    this.maxPrice,
    this.sort = 'new',
  });

  final String q;
  final String? category;
  final String? metal;
  final int? proba;
  final String? stone;
  final String? city;
  final String? condition;
  final int? minPrice;
  final int? maxPrice;
  final String sort;

  int get activeCount => [metal, proba, stone, city, condition, minPrice, maxPrice]
      .where((v) => v != null)
      .length;

  /// `copyWith` бо имкони тоза кардан: `() => null`.
  ListingFilter copyWith({
    String? q,
    String? Function()? category,
    String? Function()? metal,
    int? Function()? proba,
    String? Function()? stone,
    String? Function()? city,
    String? Function()? condition,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    String? sort,
  }) =>
      ListingFilter(
        q: q ?? this.q,
        category: category != null ? category() : this.category,
        metal: metal != null ? metal() : this.metal,
        proba: proba != null ? proba() : this.proba,
        stone: stone != null ? stone() : this.stone,
        city: city != null ? city() : this.city,
        condition: condition != null ? condition() : this.condition,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        sort: sort ?? this.sort,
      );

  ListingFilter clearExtras() => ListingFilter(q: q, category: category, sort: sort);

  Map<String, String> toQuery() => {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        'category': ?category,
        'metal': ?metal,
        if (proba != null) 'proba': '$proba',
        'stone': ?stone,
        'city': ?city,
        'condition': ?condition,
        if (minPrice != null) 'min_price': '$minPrice',
        if (maxPrice != null) 'max_price': '$maxPrice',
        'sort': sort,
      };

  @override
  List<Object?> get props => [q, category, metal, proba, stone, city, condition, minPrice, maxPrice, sort];
}
