import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/core/storage/secure_storage.dart';
import 'package:moneypilot/features/auth/data/auth_repository.dart';
import 'package:moneypilot/features/categories/data/category_repository.dart';
import 'package:moneypilot/features/categories/domain/category_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageService secureStorage;
  late SupabaseAuthRepository authRepository;
  late SupabaseCategoryRepository categoryRepository;

  setUp(() {
    secureStorage = SecureStorageService();
    authRepository = SupabaseAuthRepository(
      client: null,
      secureStorage: secureStorage,
    );
    categoryRepository = SupabaseCategoryRepository(
      client: null,
      authRepository: authRepository,
    );
  });

  group('Category Model unit tests', () {
    test('Category.fromMap parses PostgreSQL schema row correctly', () {
      final map = {
        'id': 'c5f94d12-1111-2222-3333-444455556666',
        'user_id': 'u123',
        'name': 'Fuel & Gas',
        'type': 'expense',
        'icon': 'local_gas_station_outlined',
        'color_hex': '#EF4444',
        'is_system': false,
        'created_at': '2026-09-29T10:00:00Z',
      };

      final cat = Category.fromMap(map);

      expect(cat.id, equals('c5f94d12-1111-2222-3333-444455556666'));
      expect(cat.userId, equals('u123'));
      expect(cat.name, equals('Fuel & Gas'));
      expect(cat.type, equals(CategoryType.expense));
      expect(cat.icon, equals('local_gas_station_outlined'));
      expect(cat.colorHex, equals('#EF4444'));
      expect(cat.isSystem, isFalse);
      expect(cat.createdAt, isNotNull);
    });

    test('Category.toMap formats data correctly for Supabase insert/update', () {
      const cat = Category(
        id: 'c5f94d12-1111-2222-3333-444455556666',
        userId: 'u123',
        name: 'Bonus',
        type: CategoryType.income,
        icon: 'card_giftcard_outlined',
        colorHex: '#10B981',
        isSystem: false,
      );

      final map = cat.toMap();

      expect(map['id'], equals('c5f94d12-1111-2222-3333-444455556666'));
      expect(map['user_id'], equals('u123'));
      expect(map['name'], equals('Bonus'));
      expect(map['type'], equals('income'));
      expect(map['color_hex'], equals('#10B981'));
      expect(map['is_system'], isFalse);
    });

    test('CategoryType.fromString handles case-insensitivity and defaults', () {
      expect(CategoryType.fromString('INCOME'), equals(CategoryType.income));
      expect(CategoryType.fromString('Expense'), equals(CategoryType.expense));
      expect(CategoryType.fromString('both'), equals(CategoryType.both));
      expect(CategoryType.fromString('other'), equals(CategoryType.both));
    });

    test('12 System Categories are seeded and complete', () {
      expect(Category.systemCategories.length, equals(12));
      expect(
        Category.systemCategories.any((c) => c.name == 'Salary' && c.type == CategoryType.income),
        isTrue,
      );
      expect(
        Category.systemCategories.any((c) => c.name == 'Groceries' && c.type == CategoryType.expense),
        isTrue,
      );
      expect(
        Category.systemCategories.any((c) => c.name == 'Misc' && c.type == CategoryType.both),
        isTrue,
      );
    });
  });

  group('CategoryRepository CRUD unit tests', () {
    test('getCategories returns system categories initially in fallback mode', () async {
      final list = await categoryRepository.getCategories();
      expect(list.length, equals(12));
      expect(list.any((c) => c.name == 'Salary'), isTrue);
    });

    test('getCategoriesByType filters income categories (income + both)', () async {
      final incomeList = await categoryRepository.getCategoriesByType(CategoryType.income);
      expect(incomeList.every((c) => c.type == CategoryType.income || c.type == CategoryType.both), isTrue);
      expect(incomeList.any((c) => c.name == 'Salary'), isTrue);
      expect(incomeList.any((c) => c.name == 'Groceries'), isFalse);
    });

    test('getCategoriesByType filters expense categories (expense + both)', () async {
      final expenseList = await categoryRepository.getCategoriesByType(CategoryType.expense);
      expect(expenseList.every((c) => c.type == CategoryType.expense || c.type == CategoryType.both), isTrue);
      expect(expenseList.any((c) => c.name == 'Groceries'), isTrue);
      expect(expenseList.any((c) => c.name == 'Salary'), isFalse);
    });

    test('createCategory adds a user-created category', () async {
      final created = await categoryRepository.createCategory(
        name: 'Aircraft Maintenance',
        type: CategoryType.expense,
        icon: 'build_outlined',
        colorHex: '#3B82F6',
      );

      expect(created.name, equals('Aircraft Maintenance'));
      expect(created.type, equals(CategoryType.expense));
      expect(created.isSystem, isFalse);

      final all = await categoryRepository.getCategories();
      expect(all.any((c) => c.name == 'Aircraft Maintenance'), isTrue);
    });

    test('updateCategory updates existing category properties', () async {
      final created = await categoryRepository.createCategory(
        name: 'Temp Category',
        type: CategoryType.expense,
      );

      final updated = created.copyWith(name: 'Updated Category Name');
      final result = await categoryRepository.updateCategory(updated);

      expect(result.name, equals('Updated Category Name'));
      final all = await categoryRepository.getCategories();
      expect(all.any((c) => c.name == 'Updated Category Name'), isTrue);
    });

    test('deleteCategory removes user category but protects system categories', () async {
      final created = await categoryRepository.createCategory(
        name: 'To Delete',
        type: CategoryType.expense,
      );

      await categoryRepository.deleteCategory(created.id);
      final allAfter = await categoryRepository.getCategories();
      expect(allAfter.any((c) => c.id == created.id), isFalse);

      // Attempting to delete a system category should be ignored
      await categoryRepository.deleteCategory('cat-sys-1');
      final allAgain = await categoryRepository.getCategories();
      expect(allAgain.any((c) => c.id == 'cat-sys-1'), isTrue);
    });
  });
}
