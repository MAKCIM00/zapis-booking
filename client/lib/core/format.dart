/// Форматирование дат, времени и цен по-русски — без intl и лишних зависимостей.
library;

const List<String> _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const List<String> _monthsShort = [
  'янв',
  'фев',
  'мар',
  'апр',
  'май',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];

const List<String> _weekdaysShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

String formatPrice(num value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[i]);
  }
  return '$buffer ₽';
}

String formatDateLong(DateTime date) => '${date.day} ${_monthsGenitive[date.month - 1]}';

String formatDateShort(DateTime date) => '${date.day} ${_monthsShort[date.month - 1]}';

String formatWeekday(DateTime date) => _weekdaysShort[date.weekday - 1];

String formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String formatTimeRange(DateTime start, DateTime end) =>
    '${formatTime(start)} – ${formatTime(end)}';

String formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) {
    return '$rest мин';
  }
  if (rest == 0) {
    return '$hours ч';
  }
  return '$hours ч $rest мин';
}

String greetingFor(DateTime now) {
  if (now.hour < 6) {
    return 'Доброй ночи';
  }
  if (now.hour < 12) {
    return 'Доброе утро';
  }
  if (now.hour < 18) {
    return 'Добрый день';
  }
  return 'Добрый вечер';
}

/// Первое слово имени — для короткого приветствия.
String firstName(String fullName) => fullName.trim().split(' ').first;
