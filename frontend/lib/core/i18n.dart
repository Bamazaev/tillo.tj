/// Се забон: русӣ (асосӣ), тоҷикӣ, англисӣ.
/// Забони ҷорӣ дар [currentLang] аст; MaterialApp ҳангоми иваз аз нав сохта мешавад.
enum Lang {
  ru('RU', 'Русский'),
  tg('TJ', 'Тоҷикӣ'),
  en('EN', 'English');

  const Lang(this.code, this.label);
  final String code;
  final String label;
}

Lang currentLang = Lang.ru;

/// Тарҷумаи калид. Параметрҳо: `t('items', {'n': 5})` → «{n}» иваз мешавад.
String t(String key, [Map<String, Object>? params]) {
  final row = _strings[key];
  var s = row == null ? key : row[currentLang.index];
  params?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

String _pick(Map<String, List<String>> map, String key) => map[key]?[currentLang.index] ?? key;

String categoryName(String slug) => _pick(_categories, slug);
String metalName(String slug) => _pick(_metals, slug);
String stoneName(String slug) => _pick(_stones, slug);
String conditionName(String slug) => _pick(_conditions, slug);

/// Шаҳрҳо дар база бо номи тоҷикӣ нигоҳ дошта мешаванд.
String cityName(String tg) => _pick(_cities, tg);

const _categories = {
  'rings': ['Кольца', 'Ангуштарин', 'Rings'],
  'earrings': ['Серьги', 'Гӯшвора', 'Earrings'],
  'chains': ['Цепи', 'Занҷир', 'Chains'],
  'pendants': ['Подвески и колье', 'Овеза ва гарданбанд', 'Pendants & necklaces'],
  'bracelets': ['Браслеты', 'Дастпона', 'Bracelets'],
  'sets': ['Гарнитуры', 'Гарнитур', 'Jewelry sets'],
  'wedding': ['Свадебные', 'Арӯсӣ', 'Wedding'],
  'watches': ['Часы', 'Соатҳо', 'Watches'],
  'bullion': ['Слитки и монеты', 'Хиштча ва танга', 'Bullion & coins'],
  'gems': ['Драгоценные камни', 'Сангҳои қиматбаҳо', 'Gemstones'],
  'silver': ['Серебро', 'Нуқра', 'Silver'],
  'antique': ['Антиквариат', 'Антиқа', 'Antiques'],
};

const _metals = {
  'gold': ['Жёлтое золото', 'Тиллои зард', 'Yellow gold'],
  'white_gold': ['Белое золото', 'Тиллои сафед', 'White gold'],
  'rose_gold': ['Розовое золото', 'Тиллои гулобӣ', 'Rose gold'],
  'platinum': ['Платина', 'Платина', 'Platinum'],
  'silver': ['Серебро', 'Нуқра', 'Silver'],
  'none': ['Без металла', 'Бе металл', 'No metal'],
};

const _stones = {
  'none': ['Без камня', 'Бе санг', 'No stone'],
  'diamond': ['Бриллиант', 'Бриллиант', 'Diamond'],
  'emerald': ['Изумруд', 'Зумуррад', 'Emerald'],
  'ruby': ['Рубин', 'Ёқут', 'Ruby'],
  'sapphire': ['Сапфир', 'Сапфир', 'Sapphire'],
  'spinel': ['Бадахшанский лал', 'Лаъли Бадахшон', 'Badakhshan spinel'],
  'pearl': ['Жемчуг', 'Марворид', 'Pearl'],
  'topaz': ['Топаз', 'Топаз', 'Topaz'],
  'zirconia': ['Фианит', 'Фианит', 'Cubic zirconia'],
};

const _conditions = {
  'new': ['Новое', 'Нав', 'New'],
  'used': ['Б/у', 'Истифодашуда', 'Pre-owned'],
};

const _cities = {
  'Душанбе': ['Душанбе', 'Душанбе', 'Dushanbe'],
  'Хуҷанд': ['Худжанд', 'Хуҷанд', 'Khujand'],
  'Бохтар': ['Бохтар', 'Бохтар', 'Bokhtar'],
  'Кӯлоб': ['Куляб', 'Кӯлоб', 'Kulob'],
  'Истаравшан': ['Истаравшан', 'Истаравшан', 'Istaravshan'],
  'Хоруғ': ['Хорог', 'Хоруғ', 'Khorog'],
  'Турсунзода': ['Турсунзаде', 'Турсунзода', 'Tursunzoda'],
  'Панҷакент': ['Пенджикент', 'Панҷакент', 'Panjakent'],
  'Исфара': ['Исфара', 'Исфара', 'Isfara'],
  'Ваҳдат': ['Вахдат', 'Ваҳдат', 'Vahdat'],
  'Ҳисор': ['Гиссар', 'Ҳисор', 'Hisor'],
  'Конибодом': ['Канибадам', 'Конибодом', 'Konibodom'],
};

const _strings = <String, List<String>>{
  // общее
  'app.title': ['Tillo.tj — золото, украшения и драгоценные камни', 'Tillo.tj — тилло, ҷавоҳирот ва сангҳои қиматбаҳо', 'Tillo.tj — gold, jewelry & gemstones'],
  'nav.home': ['Главная', 'Асосӣ', 'Home'],
  'nav.catalog': ['Каталог', 'Каталог', 'Catalog'],
  'nav.post': ['Продать', 'Фурӯш', 'Sell'],
  'nav.favorites': ['Избранное', 'Дӯстдошта', 'Saved'],
  'nav.profile': ['Профиль', 'Профил', 'Profile'],
  'nav.login': ['Войти', 'Ворид шудан', 'Sign in'],
  'post.cta': ['Подать объявление', 'Эълон додан', 'Post an ad'],
  'search.hint': ['Кольцо, цепь, бриллиант, Rolex…', 'Ангуштарин, занҷир, бриллиант, Rolex…', 'Ring, chain, diamond, Rolex…'],
  'search': ['Поиск', 'Ҷустуҷӯ', 'Search'],
  'theme.light': ['Светлая тема', 'Ранги равшан', 'Light theme'],
  'theme.dark': ['Тёмная тема', 'Ранги торик', 'Dark theme'],
  'language': ['Язык', 'Забон', 'Language'],
  'retry': ['Повторить', 'Аз нав', 'Retry'],
  'all': ['Все', 'Ҳама', 'All'],
  'see_all': ['Смотреть все', 'Ҳамааш', 'See all'],
  'error': ['Ошибка', 'Хатогӣ', 'Error'],
  'error.network': ['Нет связи с сервером. Проверьте интернет.', 'Пайваст ба сервер нашуд. Интернетро санҷед.', 'Can\'t reach the server. Check your connection.'],
  'error.generic': ['Что-то пошло не так', 'Хатогӣ рух дод', 'Something went wrong'],
  'error.login': ['Неверный номер или пароль', 'Рақам ё парол нодуруст аст', 'Wrong phone number or password'],
  'error.exists': ['Этот номер уже зарегистрирован', 'Ин рақам аллакай сабт шудааст', 'This number is already registered'],
  'error.auth': ['Сначала войдите', 'Аввал ворид шавед', 'Please sign in first'],
  'error.validation': ['Проверьте заполненные поля', 'Майдонҳоро санҷед', 'Please check the fields'],
  'error.notfound': ['Объявление не найдено', 'Эълон ёфт нашуд', 'Listing not found'],
  'server.down': ['Сервер недоступен', 'Сервер дастрас нест', 'Server unavailable'],
  'demo.banner': ['Демо-версия: данные сохраняются только в этом браузере', 'Версияи намоишӣ: маълумот танҳо дар ҳамин браузер мемонад', 'Demo version: data is kept only in this browser'],
  'footer.copy': ['Tillo.tj — маркетплейс золота и украшений Таджикистана', 'Tillo.tj — бозори тилло ва ҷавоҳироти Тоҷикистон', 'Tillo.tj — Tajikistan\'s gold & jewelry marketplace'],
  'footer.note': ['Цены ориентировочные и не являются финансовой рекомендацией', 'Нархҳо тахминӣ буда, маслиҳати молиявӣ нестанд', 'Prices are indicative and not financial advice'],
  'currency': ['с.', 'с.', 'TJS'],
  'gram': ['г', 'г', 'g'],
  'grams': ['грамм', 'грамм', 'grams'],
  'per_gram': ['/г', '/г', '/g'],

  // тикер и калькулятор
  'ticker.live': ['LIVE', 'ЗИНДА', 'LIVE'],
  'ticker.offline': ['ОФЛАЙН', 'ТАХМИНӢ', 'OFFLINE'],
  'ticker.live_tip': ['Биржевая цена в реальном времени', 'Нархи биржавии зинда', 'Live exchange price'],
  'ticker.offline_tip': ['Ориентировочная цена', 'Нархи тахминӣ', 'Indicative price'],
  'ticker.gold': ['Золото', 'Тилло', 'Gold'],
  'ticker.silver': ['Серебро', 'Нуқра', 'Silver'],
  'ticker.loading': ['загрузка…', 'боргирӣ…', 'loading…'],
  'calc.title': ['Калькулятор золота', 'Ҳисобкунаки тилло', 'Gold calculator'],
  'calc.subtitle': ['Стоимость металла по сегодняшнему биржевому курсу', 'Арзиши металл аз рӯи нархи биржаи имрӯза', 'Metal value at today\'s exchange price'],
  'calc.gold': ['Золото', 'Тилло', 'Gold'],
  'calc.silver': ['Серебро', 'Нуқра', 'Silver'],
  'calc.weight': ['Вес', 'Вазн', 'Weight'],
  'calc.value': ['Ориентировочная стоимость', 'Арзиши тахминӣ', 'Estimated value'],
  'metal.value': ['Стоимость металла по бирже: {v}', 'Арзиши металл аз рӯи биржа: {v}', 'Metal value at exchange price: {v}'],
  'metal.close': ['Цена близка к стоимости металла', 'Нарх ба арзиши металл наздик аст', 'Price is close to the metal value'],
  'metal.premium': ['За работу, дизайн и камни: +{p}%', 'Барои кор, тарҳ ва сангҳо: +{p}%', 'Craft, design & stones: +{p}%'],

  // главная
  'hero.badge': ['Маркетплейс золота №1 в Таджикистане', 'Бозори №1 тилло дар Тоҷикистон', 'Tajikistan\'s #1 gold marketplace'],
  'hero.title': ['Золото.\nУкрашения.\nЛегенда.', 'Тилло.\nҶавоҳирот.\nАфсона.', 'Gold.\nJewelry.\nLegend.'],
  'hero.text': [
    'Кольца, серьги, цепи, слитки, бриллианты и бадахшанский лал — от проверенных ювелиров и частных продавцов, с прозрачной ценой по бирже.',
    'Ангуштарин, гӯшвора, занҷир, хиштчаҳои тилло, бриллиант ва лаъли Бадахшон — аз заргарони боэътимод ва фурӯшандагони хусусӣ, бо нархи шаффофи биржа.',
    'Rings, earrings, chains, bullion, diamonds and Badakhshan spinel — from trusted jewelers and private sellers, with transparent exchange-based pricing.',
  ],
  'hero.catalog': ['Открыть каталог', 'Каталогро кушоед', 'Browse catalog'],
  'hero.sell': ['Продать своё золото', 'Тиллоямро мефурӯшам', 'Sell my gold'],
  'stat.listings': ['объявлений', 'эълон', 'listings'],
  'stat.cities': ['городов', 'шаҳр', 'cities'],
  'stat.shops': ['ювелиров', 'заргар', 'jewelers'],
  'home.categories': ['Категории', 'Категорияҳо', 'Categories'],
  'home.categories.sub': ['Всё, что сияет', 'Ҳар чизе, ки дурахш дорад', 'Everything that shines'],
  'home.vip': ['VIP-коллекция', 'VIP коллексия', 'VIP collection'],
  'home.vip.sub': ['Лучшие украшения от проверенных ювелиров', 'Беҳтарин ҷавоҳирот аз заргарони боэътимод', 'Finest pieces from trusted jewelers'],
  'home.new': ['Новые объявления', 'Эълонҳои нав', 'New listings'],
  'home.new.sub': ['Каждый день — новые находки', 'Ҳар рӯз ашёи нав', 'Fresh finds every day'],
  'trust.1.t': ['Проба и вес', 'Проба ва вазн', 'Purity & weight'],
  'trust.1.d': ['У каждого объявления точная проба и вес — сравнивайте честно.', 'Ҳар эълон пробаю вазни аниқ дорад — муқоиса кунед.', 'Every listing shows exact purity and weight — compare fairly.'],
  'trust.2.t': ['Прозрачная цена', 'Нархи шаффоф', 'Transparent pricing'],
  'trust.2.d': ['Мировая биржевая цена в сомони обновляется каждые 15 минут.', 'Нархи биржаи ҷаҳонӣ ба сомонӣ ҳар 15 дақиқа нав мешавад.', 'World exchange price in somoni, updated every 15 minutes.'],
  'trust.3.t': ['Ювелирные магазины', 'Мағозаҳои заргарӣ', 'Jewelry stores'],
  'trust.3.d': ['Магазины отмечены значком. Звоните напрямую.', 'Мағозаҳо бо нишони махсус. Бевосита занг занед.', 'Stores are marked with a badge. Call them directly.'],
  'trust.4.t': ['Быстро и бесплатно', 'Тез ва ройгон', 'Fast & free'],
  'trust.4.d': ['Разместите объявление за минуту — бесплатно.', 'Эълонро дар 1 дақиқа гузоред — ройгон.', 'Post your listing in a minute — for free.'],
  'n.listings': ['{n} объявл.', '{n} эълон', '{n} listings'],

  // каталог
  'catalog.all': ['Все объявления', 'Ҳамаи эълонҳо', 'All listings'],
  'catalog.found': ['Найдено: {n}', 'Ёфт шуд: {n}', '{n} found'],
  'catalog.searching': ['Поиск…', 'Ҷустуҷӯ…', 'Searching…'],
  'catalog.search': ['Поиск по объявлениям…', 'Ҷустуҷӯ дар эълонҳо…', 'Search listings…'],
  'catalog.empty': ['Ничего не найдено', 'Чизе ёфт нашуд', 'Nothing found'],
  'catalog.empty.d': ['Измените фильтры или упростите запрос', 'Филтрҳоро тағйир диҳед ё ҷустуҷӯро соддатар кунед', 'Try changing filters or simplifying your search'],
  'catalog.reset': ['Сбросить фильтры', 'Тоза кардани филтрҳо', 'Reset filters'],
  'catalog.end': ['Это всё', 'Ин ҳама буд', 'That\'s everything'],
  'catalog.show': ['Показать ({n})', 'Нишон додан ({n})', 'Show ({n})'],
  'sort': ['Сортировка', 'Тартиб', 'Sort'],
  'sort.new': ['Сначала новые', 'Аввал навҳо', 'Newest'],
  'sort.price_asc': ['Дешевле', 'Арзонтар', 'Price: low to high'],
  'sort.price_desc': ['Дороже', 'Гаронтар', 'Price: high to low'],
  'sort.popular': ['Популярные', 'Машҳур', 'Popular'],
  'filters': ['Фильтры', 'Филтрҳо', 'Filters'],
  'filters.clear': ['Сбросить', 'Тоза', 'Clear'],
  'f.price': ['Цена, сомони', 'Нарх, сомонӣ', 'Price, TJS'],
  'f.from': ['от', 'аз', 'from'],
  'f.to': ['до', 'то', 'to'],
  'f.metal': ['Металл', 'Металл', 'Metal'],
  'f.proba': ['Проба', 'Проба', 'Purity'],
  'f.stone': ['Камень', 'Санг', 'Stone'],
  'f.condition': ['Состояние', 'Ҳолат', 'Condition'],
  'f.city': ['Город', 'Шаҳр', 'City'],
  'f.category': ['Категория', 'Категория', 'Category'],
  'f.weight': ['Вес', 'Вазн', 'Weight'],
  'f.price_gram': ['Цена за 1 г', 'Нархи 1 г', 'Price per 1 g'],

  // объявление
  'item.similar': ['Похожие', 'Монанд', 'Similar'],
  'item.similar.sub': ['Из этой же категории', 'Аз ҳамин категория', 'From the same category'],
  'item.catalog': ['В каталог', 'Ба каталог', 'To catalog'],
  'item.show_phone': ['Показать номер', 'Рақамро нишон додан', 'Show phone'],
  'item.call': ['Позвонить', 'Занг задан', 'Call'],
  'item.description': ['Описание', 'Тавсиф', 'Description'],
  'item.safety': [
    'Перед покупкой проверьте пробу и вес у ювелира и не вносите предоплату.',
    'Пеш аз харид пробаю вазнро дар назди заргар санҷед ва пешпардохт накунед.',
    'Check purity and weight with a jeweler before buying, and never pay in advance.',
  ],
  'item.shop': ['Ювелирный магазин', 'Мағозаи заргарӣ', 'Jewelry store'],
  'item.private': ['Частный продавец', 'Фурӯшандаи хусусӣ', 'Private seller'],
  'item.shop_badge': ['Магазин', 'Мағоза', 'Store'],
  'item.copied': ['Ссылка скопирована', 'Пайванд нусха шуд', 'Link copied'],
  'item.share': ['Скопировать ссылку', 'Нусхаи пайванд', 'Copy link'],
  'item.wa_text': ['Здравствуйте! По объявлению «{t}» на Tillo.tj', 'Салом! Дар бораи «{t}» дар Tillo.tj', 'Hello! About «{t}» on Tillo.tj'],
  'fav.add': ['В избранное', 'Ба дӯстдоштаҳо', 'Save'],
  'fav.remove': ['Убрать из избранного', 'Аз дӯстдоштаҳо хориҷ', 'Remove from saved'],

  // вход
  'auth.login': ['Вход', 'Ворид шудан', 'Sign in'],
  'auth.register': ['Регистрация', 'Бақайдгирӣ', 'Sign up'],
  'auth.name': ['Имя или название магазина', 'Ном ё номи мағоза', 'Name or store name'],
  'auth.name.err': ['Введите имя', 'Номро ворид кунед', 'Enter your name'],
  'auth.phone': ['Номер телефона', 'Рақами телефон', 'Phone number'],
  'auth.phone.err': ['Введите полный номер', 'Рақамро пурра нависед', 'Enter the full number'],
  'auth.password': ['Пароль', 'Парол', 'Password'],
  'auth.password.err': ['Минимум 6 символов', 'Ақаллан 6 аломат', 'At least 6 characters'],
  'auth.is_shop': ['У меня ювелирный магазин', 'Ман мағозаи заргарӣ дорам', 'I own a jewelry store'],
  'auth.submit.login': ['Войти', 'Ворид шудан', 'Sign in'],
  'auth.submit.register': ['Зарегистрироваться', 'Сабт шудан', 'Create account'],
  'auth.welcome': ['Добро пожаловать', 'Хуш омадед', 'Welcome'],
  'auth.demo': ['Демо: +992 90 000 00 01, пароль tillo123', 'Демо: +992 90 000 00 01, парол tillo123', 'Demo: +992 90 000 00 01, password tillo123'],

  // избранное и профиль
  'fav.title': ['Избранное', 'Дӯстдоштаҳо', 'Saved'],
  'fav.sub': ['Вещи, которые покорили ваше сердце', 'Ашёе, ки дили шуморо рабудааст', 'Pieces that stole your heart'],
  'fav.empty': ['Пока пусто', 'Ҳоло холӣ', 'Nothing here yet'],
  'fav.empty.d': ['Нажмите ♡ на объявлении, чтобы сохранить его', 'Дили ♡-ро дар эълон пахш кунед, то нигоҳ дошта шавад', 'Tap ♡ on a listing to save it'],
  'profile.new': ['Новое объявление', 'Эълони нав', 'New listing'],
  'profile.logout': ['Выйти', 'Баромад', 'Sign out'],
  'profile.shop': ['магазин', 'мағоза', 'store'],
  'profile.mine': ['Мои объявления', 'Эълонҳои ман', 'My listings'],
  'profile.empty': ['Объявлений пока нет', 'Ҳанӯз эълон нест', 'No listings yet'],
  'profile.empty.d': ['Выставьте своё золото на продажу за минуту', 'Тиллои худро дар як дақиқа ба фурӯш гузоред', 'List your gold for sale in a minute'],
  'delete.title': ['Удалить объявление?', 'Эълонро нест кунем?', 'Delete this listing?'],
  'delete.text': ['Это действие нельзя отменить.', 'Ин амалро бекор кардан мумкин нест.', 'This can\'t be undone.'],
  'delete.yes': ['Удалить', 'Нест кардан', 'Delete'],
  'no': ['Нет', 'Не', 'No'],

  // подача объявления
  'post.title': ['Новое объявление', 'Эълони нав', 'New listing'],
  'post.sub': ['Бесплатно. Тысячи покупателей по всему Таджикистану.', 'Ройгон. Ба ҳазорон харидор дар саросари Тоҷикистон.', 'Free. Thousands of buyers across Tajikistan.'],
  'post.photos': ['Фотографии (до {n})', 'Суратҳо (то {n})', 'Photos (up to {n})'],
  'post.add_photo': ['Добавить', 'Илова', 'Add'],
  'post.main_photo': ['Главное', 'Асосӣ', 'Cover'],
  'post.category.err': ['Выберите категорию', 'Категорияро интихоб кунед', 'Choose a category'],
  'post.title_f': ['Заголовок', 'Сарлавҳа', 'Title'],
  'post.title.hint': ['Например: Золотое кольцо с бриллиантом', 'Масалан: Ангуштарини тиллоӣ бо бриллиант', 'e.g. Gold ring with a diamond'],
  'post.title.err': ['Введите заголовок', 'Сарлавҳаро нависед', 'Enter a title'],
  'post.weight_price': ['Вес и цена', 'Вазн ва нарх', 'Weight & price'],
  'post.weight.err': ['Укажите вес', 'Вазнро нависед', 'Enter the weight'],
  'post.number.err': ['Неверное число', 'Рақами нодуруст', 'Invalid number'],
  'post.price': ['Цена', 'Нарх', 'Price'],
  'post.price.err': ['Укажите цену', 'Нархро нависед', 'Enter the price'],
  'post.somoni': ['сомони', 'сомонӣ', 'TJS'],
  'post.use': ['Подставить', 'Истифода', 'Use'],
  'post.description': ['Описание', 'Тавсиф', 'Description'],
  'post.description.hint': ['Размер, сертификат, состояние, гарантия…', 'Андоза, сертификат, ҳолат, кафолат…', 'Size, certificate, condition, warranty…'],
  'post.phone': ['Телефон для связи', 'Телефон барои тамос', 'Contact phone'],
  'post.submit': ['Опубликовать', 'Нашр кардан', 'Publish'],
  'post.sending': ['Публикуем…', 'Нашр шуда истодааст…', 'Publishing…'],
  'post.done': ['Объявление опубликовано ✨', 'Эълон нашр шуд ✨', 'Listing published ✨'],

  // время
  'time.now': ['только что', 'ҳозир', 'just now'],
  'time.min': ['{n} мин назад', '{n} дақ. пеш', '{n} min ago'],
  'time.hour': ['{n} ч назад', '{n} соат пеш', '{n} h ago'],
  'time.day': ['{n} дн назад', '{n} рӯз пеш', '{n} d ago'],
};
