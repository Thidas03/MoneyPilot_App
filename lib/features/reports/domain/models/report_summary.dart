/// Strongly typed summary of financial performance for a selected period.
class ReportSummary {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final int transactionCount;
  final double averageDailyExpense;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.transactionCount,
    required this.averageDailyExpense,
  });

  /// Factory creating safe default summary with zeroed metrics.
  factory ReportSummary.empty() => const ReportSummary(
        totalIncome: 0.0,
        totalExpenses: 0.0,
        balance: 0.0,
        transactionCount: 0,
        averageDailyExpense: 0.0,
      );

  /// Safe calculation constructor ensuring balance and daily average are valid numbers.
  factory ReportSummary.calculate({
    required double totalIncome,
    required double totalExpenses,
    required int transactionCount,
    required int daysInPeriod,
  }) {
    final safeIncome = (totalIncome.isNaN || totalIncome.isInfinite) ? 0.0 : totalIncome;
    final safeExpenses = (totalExpenses.isNaN || totalExpenses.isInfinite) ? 0.0 : totalExpenses;
    final safeBalance = safeIncome - safeExpenses;

    final double avgDaily;
    if (daysInPeriod <= 0 || safeExpenses <= 0) {
      avgDaily = 0.0;
    } else {
      final calculated = safeExpenses / daysInPeriod;
      avgDaily = (calculated.isNaN || calculated.isInfinite) ? 0.0 : calculated;
    }

    return ReportSummary(
      totalIncome: safeIncome,
      totalExpenses: safeExpenses,
      balance: safeBalance,
      transactionCount: transactionCount < 0 ? 0 : transactionCount,
      averageDailyExpense: avgDaily,
    );
  }

  /// Net savings rate (0.0 to 100.0%). Returns 0.0 if income <= 0.
  double get savingsRate {
    if (totalIncome <= 0 || balance <= 0) return 0.0;
    final rate = (balance / totalIncome) * 100.0;
    return rate.clamp(0.0, 100.0);
  }
}
