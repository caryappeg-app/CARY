// Core: تنسيق التاريخ والوقت بالعربي (من غير حزم): 13/10/2026 - 08:45 م
String formatDateTime(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final h12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final period = l.hour < 12 ? 'ص' : 'م';
  return '${two(l.day)}/${two(l.month)}/${l.year} - ${two(h12)}:${two(l.minute)} $period';
}
