import 'dart:convert';

class Category {
  final String id;
  final String code;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon;
  final String color;
  final bool isActive;
  final bool isBuiltIn;
  final int sortOrder;
  final List<String> keywords;

  Category({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.isBuiltIn,
    required this.sortOrder,
    required this.keywords,
  });

  Category copyWith({
    String? id,
    String? code,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isActive,
    bool? isBuiltIn,
    int? sortOrder,
    List<String>? keywords,
  }) {
    return Category(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      sortOrder: sortOrder ?? this.sortOrder,
      keywords: keywords ?? this.keywords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'is_built_in': isBuiltIn ? 1 : 0,
      'sort_order': sortOrder,
      'keywords': jsonEncode(keywords),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    List<String> parsedKeywords = [];
    final kw = map['keywords'];
    if (kw is String && kw.isNotEmpty) {
      try {
        final decoded = jsonDecode(kw);
        if (decoded is List) {
          parsedKeywords = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return Category(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isBuiltIn: (map['is_built_in'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      keywords: parsedKeywords,
    );
  }
}
