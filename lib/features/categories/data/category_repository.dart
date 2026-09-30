import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/category_model.dart';

/// Contract for category CRUD operations.
abstract class CategoryRepository {
  /// Retrieves all categories (system defaults + user-created).
  Future<List<Category>> getCategories();

  /// Retrieves categories filtered by income or expense compatibility.
  Future<List<Category>> getCategoriesByType(CategoryType type);

  /// Creates a new custom category for the authenticated user.
  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    String? icon,
    String? colorHex,
  });

  /// Updates an existing user category.
  Future<Category> updateCategory(Category category);

  /// Deletes a user category. System categories cannot be deleted.
  Future<void> deleteCategory(String id);
}

/// Unified category repository supporting Supabase PostgreSQL and mock fallback.
class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository({
    this.client,
    required this.authRepository,
  });

  final SupabaseClient? client;
  final AuthRepository authRepository;

  bool get isLiveSupabase => client != null;

  // In-memory mock storage
  final List<Category> _mockCategories = List<Category>.from(Category.systemCategories);

  @override
  Future<List<Category>> getCategories() async {
    if (!isLiveSupabase) {
      return List.unmodifiable(_mockCategories);
    }

    try {
      final data = await client!
          .from('categories')
          .select()
          .order('is_system', ascending: false)
          .order('name', ascending: true);

      final list = (data as List)
          .map((item) => Category.fromMap(item as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        // If database table is empty or unseeded, fall back to default system categories
        return List.unmodifiable(_mockCategories);
      }
      return list;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CategoryRepository] Error fetching categories: $e\n$st');
      }
      return List.unmodifiable(_mockCategories);
    }
  }

  @override
  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final all = await getCategories();
    if (type == CategoryType.both) return all;
    return all.where((c) => c.type == type || c.type == CategoryType.both).toList();
  }

  @override
  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    String? icon,
    String? colorHex,
  }) async {
    final user = authRepository.getCurrentUser();
    final newCategory = Category(
      id: 'cat-usr-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id,
      name: name.trim(),
      type: type,
      icon: icon ?? 'category_outlined',
      colorHex: colorHex ?? '#64748B',
      isSystem: false,
      createdAt: DateTime.now(),
    );

    if (!isLiveSupabase) {
      _mockCategories.add(newCategory);
      return newCategory;
    }

    try {
      final res = await client!.from('categories').insert({
        'user_id': user?.id,
        'name': name.trim(),
        'type': type.value,
        'icon': icon ?? 'category_outlined',
        'color_hex': colorHex ?? '#64748B',
        'is_system': false,
      }).select().single();

      return Category.fromMap(res);
    } catch (e) {
      // Fallback
      _mockCategories.add(newCategory);
      return newCategory;
    }
  }

  @override
  Future<Category> updateCategory(Category category) async {
    if (!isLiveSupabase) {
      final index = _mockCategories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _mockCategories[index] = category;
      }
      return category;
    }

    final res = await client!
        .from('categories')
        .update({
          'name': category.name,
          'type': category.type.value,
          'icon': category.icon,
          'color_hex': category.colorHex,
        })
        .eq('id', category.id)
        .select()
        .single();

    return Category.fromMap(res);
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (!isLiveSupabase) {
      _mockCategories.removeWhere((c) => c.id == id && !c.isSystem);
      return;
    }

    await client!.from('categories').delete().eq('id', id);
  }
}

/// Provider for [CategoryRepository].
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return SupabaseCategoryRepository(
    client: client,
    authRepository: authRepo,
  );
});

/// AsyncNotifier managing the categories state across the application.
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repo = ref.watch(categoryRepositoryProvider);
    return await repo.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(categoryRepositoryProvider);
      return await repo.getCategories();
    });
  }

  Future<Category> addCategory({
    required String name,
    required CategoryType type,
    String? icon,
    String? colorHex,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    final created = await repo.createCategory(
      name: name,
      type: type,
      icon: icon,
      colorHex: colorHex,
    );
    await refresh();
    return created;
  }
}

/// Provider exposing category list with async loading/error states.
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

/// Provider for categories compatible with Expenses.
final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final asyncCategories = ref.watch(categoriesProvider);
  final list = asyncCategories.asData?.value ?? Category.systemCategories;
  return list.where((c) => c.type == CategoryType.expense || c.type == CategoryType.both).toList();
});

/// Provider for categories compatible with Income.
final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final asyncCategories = ref.watch(categoriesProvider);
  final list = asyncCategories.asData?.value ?? Category.systemCategories;
  return list.where((c) => c.type == CategoryType.income || c.type == CategoryType.both).toList();
});
