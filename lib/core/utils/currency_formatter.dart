import 'package:intl/intl.dart';

/// Formatting utilities for Sri Lankan Rupees (Rs.).
class CurrencyFormatter {
  CurrencyFormatter._();

  static const String currencySymbol = 'Rs.';

  /// Formats amount into standard Sri Lankan Rupee format.
  /// Example: 25000 -> "Rs. 25,000"
  /// Example with decimals: 125500.5 -> "LKR 125,500.50"
  static String format(num? amount, {bool forceDecimals = false}) {
    if (amount == null) return '$currencySymbol 0';

    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '$currencySymbol ',
      decimalDigits: forceDecimals || (amount % 1 != 0) ? 2 : 0,
    );

    return formatter.format(amount);
  }

  /// Formats amount into compact form.
  /// Example: 25000 -> "LKR 25K", 1500000 -> "LKR 1.5M"
  static String formatCompact(num? amount) {
    if (amount == null) return '$currencySymbol 0';

    final formatter = NumberFormat.compact(locale: 'en_US');
    return '$currencySymbol ${formatter.format(amount)}';
  }

  /// Parses a string representation back to double.
  /// Strips out "LKR", "Rs.", "Rs", commas, spaces.
  static double? parse(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final cleaned = input
        .replaceAll('LKR', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned);
  }
}
