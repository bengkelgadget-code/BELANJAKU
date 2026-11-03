import 'dart:convert';

class DefaultCategoryItem {
  final String id;
  final String code;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon;
  final String color;
  final int sortOrder;
  final List<String> keywords;

  const DefaultCategoryItem({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.keywords,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_active': 1,
      'is_built_in': 1,
      'sort_order': sortOrder,
      'keywords': jsonEncode(keywords),
    };
  }
}

class DefaultCategories {
  // Income Categories (§5.2)
  static final List<DefaultCategoryItem> incomeCategories = [
    const DefaultCategoryItem(
      id: 'cat_inc_gaji',
      code: 'INC_GAJI',
      name: 'Gaji',
      type: 'income',
      icon: 'banknote',
      color: '0xFF16A34A',
      sortOrder: 1,
      keywords: ['gaji', 'thr', 'bonus', 'lembur', 'payroll', 'salary'],
    ),
    const DefaultCategoryItem(
      id: 'cat_inc_usaha',
      code: 'INC_USAHA',
      name: 'Usaha & Jualan',
      type: 'income',
      icon: 'store',
      color: '0xFF0D9488',
      sortOrder: 2,
      keywords: ['jualan', 'untung', 'komisi', 'omset', 'dagang', 'toko'],
    ),
    const DefaultCategoryItem(
      id: 'cat_inc_freelance',
      code: 'INC_FREELANCE',
      name: 'Freelance & Jasa',
      type: 'income',
      icon: 'laptop',
      color: '0xFF0284C7',
      sortOrder: 3,
      keywords: ['proyek', 'desain', 'coding', 'foto', 'freelance', 'jasa'],
    ),
    const DefaultCategoryItem(
      id: 'cat_inc_investasi',
      code: 'INC_INVESTASI',
      name: 'Investasi',
      type: 'income',
      icon: 'trending-up',
      color: '0xFF4F46E5',
      sortOrder: 4,
      keywords: ['dividen', 'bunga', 'deposito', 'saham', 'reksadana', 'crypto', 'yield'],
    ),
    const DefaultCategoryItem(
      id: 'cat_inc_hadiah',
      code: 'INC_HADIAH',
      name: 'Hadiah & Transfer Masuk',
      type: 'income',
      icon: 'gift',
      color: '0xFFD97706',
      sortOrder: 5,
      keywords: ['hadiah', 'transfer', 'kiriman', 'cashback', 'angpau', 'thr keluarga'],
    ),
    const DefaultCategoryItem(
      id: 'cat_inc_lain',
      code: 'INC_LAIN',
      name: 'Pemasukan Lainnya',
      type: 'income',
      icon: 'plus-circle',
      color: '0xFF6B7280',
      sortOrder: 6,
      keywords: ['temuan', 'refund', 'bekas', 'lain-lain'],
    ),
  ];

  // Expense Categories (§5.3 & §7.5)
  static final List<DefaultCategoryItem> expenseCategories = [
    const DefaultCategoryItem(
      id: 'cat_exp_makan',
      code: 'EXP_MAKAN',
      name: 'Makan & Minum',
      type: 'expense',
      icon: 'utensils',
      color: '0xFFFEF3C7',
      sortOrder: 1,
      keywords: [
        'nasi', 'ayam', 'geprek', 'bakso', 'soto', 'kopi', 'teh', 'botol', 'jus',
        'roti', 'snack', 'coklat', 'es krim', 'ice cream', 'katering', 'rice bowl',
        'indomie goreng', 'mie ayam', 'burger', 'pizza', 'warteg', 'padang',
        'cafe', 'restoran', 'boba', 'minuman', 'makanan', 'gorengan'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_sembako',
      code: 'EXP_SEMBAKO',
      name: 'Belanja Harian & Sembako',
      type: 'expense',
      icon: 'shopping-basket',
      color: '0xFFDCFCE7',
      sortOrder: 2,
      keywords: [
        'beras', 'minyak', 'minyak goreng', 'gula', 'telur', 'tepung', 'mie', 'indomie',
        'susu', 'kecap', 'saus', 'garam', 'sabun cuci', 'deterjen', 'tisu', 'tissue',
        'sampo', 'shampoo', 'pasta gigi', 'odol', 'pembalut', 'rinso', 'sunlight',
        'daia', 'mama lemon', 'dettol', 'pepsodent', 'lifebuoy', 'baygon', 'hit',
        'bumbu', 'bawang', 'cabe', 'sayur', 'buah', 'popok', 'pampers'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_transport',
      code: 'EXP_TRANSPORT',
      name: 'Transportasi',
      type: 'expense',
      icon: 'car',
      color: '0xFFDBEAFE',
      sortOrder: 3,
      keywords: [
        'pertalite', 'pertamax', 'solar', 'dexlite', 'oli', 'ban', 'parkir',
        'goride', 'grab', 'gocar', 'tol', 'bensin', 'spbu', 'pertamina', 'shell',
        'servis', 'cuci motor', 'cuci mobil', 'kereta', 'tiket bus', 'angkot'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_tagihan',
      code: 'EXP_TAGIHAN',
      name: 'Tagihan & Utilitas',
      type: 'expense',
      icon: 'zap',
      color: '0xFFEDE9FE',
      sortOrder: 4,
      keywords: [
        'pln', 'token listrik', 'listrik', 'pdam', 'air', 'wifi', 'indihome',
        'biznet', 'myrepublic', 'pulsa', 'paket data', 'telkomsel', 'xl',
        'indosat', 'tri', 'smartfren', 'netflix', 'spotify', 'youtube premium', 'langganan'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_rumah',
      code: 'EXP_RUMAH',
      name: 'Rumah & Tempat Tinggal',
      type: 'expense',
      icon: 'home',
      color: '0xFFFCE7F3',
      sortOrder: 5,
      keywords: [
        'kos', 'kontrakan', 'sewa rumah', 'cat', 'lampu', 'galon', 'aqua galon',
        'gas lpg', 'lpg 3kg', 'ember', 'sapu', 'pel', 'perabot', 'kunci', 'pompa'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_kesehatan',
      code: 'EXP_KESEHATAN',
      name: 'Kesehatan',
      type: 'expense',
      icon: 'heart-pulse',
      color: '0xFFFEE2E2',
      sortOrder: 6,
      keywords: [
        'paracetamol', 'obat', 'vitamin', 'masker', 'antiseptik', 'salep',
        'bpjs', 'dokter', 'klinik', 'apotek', 'kimia farma', 'k24', 'panadol',
        'bodrex', 'tolak angin', 'hansaplast', 'betadine', 'termometer'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_pendidikan',
      code: 'EXP_PENDIDIKAN',
      name: 'Pendidikan',
      type: 'expense',
      icon: 'book-open',
      color: '0xFFCCFBF1',
      sortOrder: 7,
      keywords: [
        'buku', 'pulpen', 'pensil', 'fotokopi', 'print', 'kursus', 'spp',
        'uang sekolah', 'semester', 'kuliah', 'alat tulis', 'binder', 'kertas hvs'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_pakaian',
      code: 'EXP_PAKAIAN',
      name: 'Pakaian & Penampilan',
      type: 'expense',
      icon: 'shirt',
      color: '0xFFE0E7FF',
      sortOrder: 8,
      keywords: [
        'kaos', 'celana', 'kemeja', 'sepatu', 'sandal', 'jaket', 'hijab',
        'parfum', 'skincare', 'sunscreen', 'facial', 'cukur', 'barbershop',
        'potong rambut', 'laundry', 'cuci baju', 'baju'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_hiburan',
      code: 'EXP_HIBURAN',
      name: 'Hiburan & Rekreasi',
      type: 'expense',
      icon: 'gamepad-2',
      color: '0xFFFEF9C3',
      sortOrder: 9,
      keywords: [
        'bioskop', 'cinema xxi', 'cgv', 'tiket', 'top up', 'diamond', 'game',
        'steam', 'mobile legends', 'playstation', 'futsal', 'karaoke', 'mancing',
        'rekreasi', 'liburan', 'wisata'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_sosial',
      code: 'EXP_SOSIAL',
      name: 'Sosial & Donasi',
      type: 'expense',
      icon: 'gift',
      color: '0xFFFFEDD5',
      sortOrder: 10,
      keywords: [
        'kado', 'amplop', 'kondangan', 'parcel', 'sedekah', 'donasi', 'zakat',
        'infaq', 'traktir', 'urunan', 'sumbangan'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_keuangan',
      code: 'EXP_KEUANGAN',
      name: 'Cicilan & Keuangan',
      type: 'expense',
      icon: 'credit-card',
      color: '0xFFE0E7FF',
      sortOrder: 11,
      keywords: [
        'cicilan', 'bunga', 'admin bank', 'denda', 'kpr', 'leasing',
        'fif', 'adira', 'kartu kredit', 'pinjaman'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_kerja',
      code: 'EXP_KERJA',
      name: 'Kerja & Bisnis',
      type: 'expense',
      icon: 'briefcase',
      color: '0xFFD1FAE5',
      sortOrder: 12,
      keywords: [
        'modal', 'atk usaha', 'banner', 'ongkir', 'packing', 'kardus',
        'lakban', 'iklan', 'ads', 'stok barang'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_peliharaan',
      code: 'EXP_PELIHARAAN',
      name: 'Hewan Peliharaan',
      type: 'expense',
      icon: 'paw-print',
      color: '0xFFFEE2E2',
      sortOrder: 13,
      keywords: [
        'pakan kucing', 'pasir kucing', 'makanan anjing', 'whiskas', 'me-o',
        'royal canin', 'pet shop', 'vaksin hewan', 'dokter hewan'
      ],
    ),
    const DefaultCategoryItem(
      id: 'cat_exp_lain',
      code: 'EXP_LAIN',
      name: 'Pengeluaran Lainnya',
      type: 'expense',
      icon: 'more-horizontal',
      color: '0xFFF3F4F6',
      sortOrder: 14,
      keywords: ['lain-lain', 'biaya lain', 'pengeluaran tak terduga'],
    ),
  ];

  static List<DefaultCategoryItem> get allCategories => [
    ...expenseCategories,
    ...incomeCategories,
  ];
}
