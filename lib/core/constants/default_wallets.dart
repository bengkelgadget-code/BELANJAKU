class DefaultWalletItem {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'ewallet', 'other'
  final int initialBalance;
  final String icon;
  final String color;

  const DefaultWalletItem({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
      'icon': icon,
      'color': color,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    };
  }
}

class DefaultWallets {
  static const List<DefaultWalletItem> wallets = [
    DefaultWalletItem(
      id: 'w_tunai',
      name: 'Tunai',
      type: 'cash',
      initialBalance: 0,
      icon: 'wallet',
      color: '0xFF16A34A', // Green
    ),
    DefaultWalletItem(
      id: 'w_bank',
      name: 'Bank',
      type: 'bank',
      initialBalance: 0,
      icon: 'landmark',
      color: '0xFF2563EB', // Blue
    ),
    DefaultWalletItem(
      id: 'w_ewallet',
      name: 'E-Wallet',
      type: 'ewallet',
      initialBalance: 0,
      icon: 'smartphone',
      color: '0xFF7C3AED', // Purple
    ),
  ];
}
