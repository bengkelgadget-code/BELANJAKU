import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesProvider = FutureProvider.autoDispose.family<List<Category>, String?>((ref, type) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getCategories(type: type, onlyActive: true);
});

final allCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getCategories();
});
