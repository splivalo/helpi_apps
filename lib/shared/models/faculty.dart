/// Faculty model — loaded from backend API.
class Faculty {
  const Faculty({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  final int id;
  final String name;
  final String abbreviation;

  /// Parse a single faculty from the backend JSON response.
  /// Backend format: { "id": 1, "translations": { "hr": { "name": "...", "abbreviation": "..." }, "en": { ... } } }
  factory Faculty.fromJson(Map<String, dynamic> json, {String lang = 'hr'}) {
    final id = json['id'] as int;
    final translations = json['translations'] as Map<String, dynamic>? ?? {};
    final langMap = translations[lang] as Map<String, dynamic>?;
    final fallbackMap = translations['en'] as Map<String, dynamic>?;
    final name =
        (langMap?['name'] as String?) ??
        (fallbackMap?['name'] as String?) ??
        'Faculty $id';
    final abbreviation =
        (langMap?['abbreviation'] as String?) ??
        (fallbackMap?['abbreviation'] as String?) ??
        '';
    return Faculty(id: id, name: name, abbreviation: abbreviation);
  }

  /// Parse list of faculties from API response.
  static List<Faculty> fromJsonList(List<dynamic> list, {String lang = 'hr'}) {
    return list
        .map((e) => Faculty.fromJson(e as Map<String, dynamic>, lang: lang))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
