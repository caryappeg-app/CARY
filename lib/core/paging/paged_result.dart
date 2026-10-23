// Core: نتيجة صفحة واحدة من قايمة كبيرة (Pagination)

class PagedResult<T> {
  final List<T> items;
  final int page; // رقم الصفحة (بيبدأ من 1)
  final int total; // إجمالي العناصر المطابقة (مش بس المحمّلة)
  final bool hasMore;

  const PagedResult({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
}
