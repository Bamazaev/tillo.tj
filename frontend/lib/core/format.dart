import 'package:intl/intl.dart';

import 'i18n.dart';

final _money = NumberFormat.decimalPattern('ru');

String money(num value) => '${_money.format(value.round())} ${t('currency')}';

String grams(num value) {
  final g = t('gram');
  if (value == value.roundToDouble()) return '${value.toStringAsFixed(0)} $g';
  final s = value.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
  return '$s $g';
}

String timeAgo(DateTime time) {
  final d = DateTime.now().toUtc().difference(time);
  if (d.inMinutes < 1) return t('time.now');
  if (d.inMinutes < 60) return t('time.min', {'n': d.inMinutes});
  if (d.inHours < 24) return t('time.hour', {'n': d.inHours});
  if (d.inDays < 30) return t('time.day', {'n': d.inDays});
  return DateFormat('dd.MM.yyyy').format(time.toLocal());
}

String prettyPhone(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length != 12) return phone;
  return '+${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10)}';
}
