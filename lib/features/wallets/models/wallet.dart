class Wallet {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'ewallet', 'other'
  final int initialBalance;
  final String icon;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentBalance; // Computed dynamically via query

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.currentBalance = 0,
  });

  Wallet copyWith({
    String? id,
    String? name,
    String? type,
    int? initialBalance,
    String? icon,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentBalance,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
      'icon': icon,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map, {int currentBalance = 0}) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      initialBalance: map['initial_balance'] as int? ?? 0,
      icon: map['icon'] as String,
      color: map['color'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      currentBalance: currentBalance,
    );
  }
}
