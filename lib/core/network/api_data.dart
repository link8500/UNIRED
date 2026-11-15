/// Traducción estricta de la frontera JSON; las vistas nunca manejan `dynamic`.
typedef Json = Map<String, Object?>;

Json jsonObject(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, Object?>{};
List<Json> jsonRows(Object? value) =>
    value is List ? value.map(jsonObject).toList(growable: false) : <Json>[];
String textValue(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;
int intValue(Object? value) => int.tryParse(textValue(value)) ?? 0;
double numberValue(Object? value) => double.tryParse(textValue(value)) ?? 0;

class ApiPage {
  const ApiPage(this.items, this.total, this.page, this.limit);
  factory ApiPage.fromJson(Object? value) {
    final data = jsonObject(value);
    return ApiPage(
      jsonRows(data['items']),
      intValue(data['total']),
      intValue(data['page']),
      intValue(data['limit']),
    );
  }
  final List<Json> items;
  final int total;
  final int page;
  final int limit;
  bool get hasMore => page * limit < total;
}
