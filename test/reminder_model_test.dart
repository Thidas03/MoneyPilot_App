import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/features/reminders/data/models/reminder_model.dart';

void main() {
  group('ReminderFrequency Enum Tests', () {
    test('fromString parses valid frequency strings correctly', () {
      expect(ReminderFrequencyExtension.fromString('once'), ReminderFrequency.once);
      expect(ReminderFrequencyExtension.fromString('daily'), ReminderFrequency.daily);
      expect(ReminderFrequencyExtension.fromString('weekly'), ReminderFrequency.weekly);
      expect(ReminderFrequencyExtension.fromString('monthly'), ReminderFrequency.monthly);
      expect(ReminderFrequencyExtension.fromString('yearly'), ReminderFrequency.yearly);
    });

    test('fromString defaults to monthly on unknown or null string', () {
      expect(ReminderFrequencyExtension.fromString(null), ReminderFrequency.monthly);
      expect(ReminderFrequencyExtension.fromString('invalid_freq'), ReminderFrequency.monthly);
      expect(ReminderFrequencyExtension.fromString(''), ReminderFrequency.monthly);
    });

    test('displayName returns human friendly labels', () {
      expect(ReminderFrequency.once.displayName, 'Once');
      expect(ReminderFrequency.daily.displayName, 'Daily');
      expect(ReminderFrequency.weekly.displayName, 'Weekly');
      expect(ReminderFrequency.monthly.displayName, 'Monthly');
      expect(ReminderFrequency.yearly.displayName, 'Yearly');
    });

    test('value matches database check constraint string', () {
      expect(ReminderFrequency.once.value, 'once');
      expect(ReminderFrequency.daily.value, 'daily');
      expect(ReminderFrequency.weekly.value, 'weekly');
      expect(ReminderFrequency.monthly.value, 'monthly');
      expect(ReminderFrequency.yearly.value, 'yearly');
    });
  });

  group('Reminder Model Serialization Tests', () {
    test('Reminder.fromJson parses full Supabase row correctly', () {
      final json = {
        'id': 'b1f6305a-f1f3-424a-b516-728639e71f90',
        'user_id': 'u100-user-uuid',
        'category_id': 'cat-util-123',
        'title': 'Electricity Bill',
        'amount': 8500.50,
        'due_date': '2026-10-15T08:00:00Z',
        'frequency': 'monthly',
        'is_completed': false,
        'note': 'Pay before 15th to avoid penalty',
        'created_at': '2026-10-01T10:00:00Z',
        'updated_at': '2026-10-01T12:00:00Z',
        'categories': {
          'name': 'Utilities',
          'icon': 'bolt_rounded',
          'color_hex': '#EAB308',
        },
      };

      final reminder = Reminder.fromJson(json);

      expect(reminder.id, 'b1f6305a-f1f3-424a-b516-728639e71f90');
      expect(reminder.userId, 'u100-user-uuid');
      expect(reminder.categoryId, 'cat-util-123');
      expect(reminder.title, 'Electricity Bill');
      expect(reminder.amount, 8500.50);
      expect(reminder.frequency, ReminderFrequency.monthly);
      expect(reminder.isCompleted, isFalse);
      expect(reminder.note, 'Pay before 15th to avoid penalty');
      expect(reminder.category, 'Utilities');
      expect(reminder.categoryIcon, 'bolt_rounded');
      expect(reminder.categoryColorHex, '#EAB308');
      expect(reminder.dueDate.year, 2026);
      expect(reminder.dueDate.month, 10);
      expect(reminder.dueDate.day, 15);
    });

    test('Reminder.fromJson safely handles null amount, null category, and null note', () {
      final json = {
        'id': 'rem-null-fields-01',
        'user_id': 'u100',
        'category_id': null,
        'title': 'Passport Renewal Due',
        'amount': null,
        'due_date': '2026-11-20T00:00:00Z',
        'frequency': 'once',
        'is_completed': false,
        'note': null,
        'created_at': '2026-10-01T00:00:00Z',
        'updated_at': '2026-10-01T00:00:00Z',
      };

      final reminder = Reminder.fromJson(json);

      expect(reminder.id, 'rem-null-fields-01');
      expect(reminder.title, 'Passport Renewal Due');
      expect(reminder.amount, isNull);
      expect(reminder.categoryId, isNull);
      expect(reminder.category, isNull);
      expect(reminder.note, isNull);
      expect(reminder.frequency, ReminderFrequency.once);
      expect(reminder.isCompleted, isFalse);
    });

    test('Reminder.toSupabaseMap generates valid SQL payload without joined objects', () {
      final reminder = Reminder(
        id: 'rem-uuid-test',
        userId: 'user-uuid-99',
        categoryId: 'cat-uuid-44',
        category: 'Insurance',
        title: 'Vehicle Insurance',
        amount: 32000.0,
        dueDate: DateTime.utc(2026, 12, 1, 9, 30),
        frequency: ReminderFrequency.yearly,
        isCompleted: true,
        note: 'Comprehensive cover policy',
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
      );

      final map = reminder.toSupabaseMap();

      expect(map['user_id'], 'user-uuid-99');
      expect(map['category_id'], 'cat-uuid-44');
      expect(map['title'], 'Vehicle Insurance');
      expect(map['amount'], 32000.0);
      expect(map['frequency'], 'yearly');
      expect(map['is_completed'], isTrue);
      expect(map['note'], 'Comprehensive cover policy');
      expect(map.containsKey('categories'), isFalse);
      expect(map.containsKey('category_name'), isFalse);
    });

    test('Reminder.toJson produces valid full JSON map', () {
      final reminder = Reminder(
        id: 'rem-001',
        userId: 'u-1',
        title: 'Gym Membership',
        amount: 5000,
        dueDate: DateTime.utc(2026, 10, 5),
        frequency: ReminderFrequency.monthly,
      );

      final json = reminder.toJson();

      expect(json['id'], 'rem-001');
      expect(json['user_id'], 'u-1');
      expect(json['title'], 'Gym Membership');
      expect(json['amount'], 5000.0);
      expect(json['frequency'], 'monthly');
      expect(json['is_completed'], isFalse);
    });

    test('Reminder.copyWith creates modified copy preserving original values', () {
      final original = Reminder(
        id: 'rem-copy-1',
        userId: 'u1',
        title: 'Original Title',
        amount: 1000,
        dueDate: DateTime(2026, 10, 10),
        frequency: ReminderFrequency.once,
        isCompleted: false,
      );

      final copy = original.copyWith(
        title: 'Updated Title',
        isCompleted: true,
      );

      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.title, 'Updated Title');
      expect(copy.amount, original.amount);
      expect(copy.isCompleted, isTrue);
      expect(copy.frequency, ReminderFrequency.once);
    });
  });

  group('Reminder Due Date and Relative Calculation Tests', () {
    test('relativeDueDescription for overdue reminder', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      final reminder = Reminder(
        id: 'rem-past',
        userId: 'u1',
        title: 'Past Bill',
        dueDate: pastDate,
        frequency: ReminderFrequency.monthly,
      );

      expect(reminder.isOverdue, isTrue);
      expect(reminder.isDueToday, isFalse);
      expect(reminder.relativeDueDescription, contains('Overdue'));
    });

    test('relativeDueDescription for reminder due today', () {
      final todayDate = DateTime.now();
      final reminder = Reminder(
        id: 'rem-today',
        userId: 'u1',
        title: 'Today Bill',
        dueDate: todayDate,
        frequency: ReminderFrequency.monthly,
      );

      expect(reminder.isDueToday, isTrue);
      expect(reminder.isOverdue, isFalse);
      expect(reminder.relativeDueDescription, 'Due today');
    });

    test('relativeDueDescription for reminder due tomorrow', () {
      final tomorrowDate = DateTime.now().add(const Duration(days: 1));
      final reminder = Reminder(
        id: 'rem-tomorrow',
        userId: 'u1',
        title: 'Tomorrow Bill',
        dueDate: tomorrowDate,
        frequency: ReminderFrequency.monthly,
      );

      expect(reminder.relativeDueDescription, 'Due tomorrow');
    });

    test('relativeDueDescription for reminder due in 5 days', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final reminder = Reminder(
        id: 'rem-future',
        userId: 'u1',
        title: 'Future Bill',
        dueDate: futureDate,
        frequency: ReminderFrequency.monthly,
      );

      expect(reminder.relativeDueDescription, 'Due in 5 days');
    });
  });
}
