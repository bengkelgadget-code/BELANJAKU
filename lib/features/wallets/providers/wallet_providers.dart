import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import '../repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

final walletsProvider = FutureProvider.autoDispose<List<Wallet>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return await repo.getWallets(onlyActive: true);
});

final allWalletsProvider = FutureProvider.autoDispose<List<Wallet>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return await repo.getWallets(onlyActive: false);
});

final totalBalanceProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return await repo.getTotalBalance();
});

class SelectedWalletIdNotifier extends Notifier<String?> {
  @override
  String? build() => 'w_tunai';

  void setWalletId(String? id) => state = id;
}

final selectedWalletIdProvider = NotifierProvider<SelectedWalletIdNotifier, String?>(
  SelectedWalletIdNotifier.new,
);
