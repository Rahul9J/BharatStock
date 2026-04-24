import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../../billing/data/bill_model.dart';
import '../data/expense_model.dart';
import 'expenses_screen.dart';
import 'package:bharatstock/l10n/app_localizations.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  final FirestoreService _service = FirestoreService();
  String _timeFrame = 'thisMonth'; // Using keys now

  @override
  Widget build(BuildContext context) {
    const baseColor = kClayBaseColor;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profitLossAnalysis),
        backgroundColor: baseColor,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: DropdownButton<String>(
              value: _timeFrame,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, color: Colors.indigo),
              items: [
                DropdownMenuItem(
                  value: 'today',
                  child: Text(AppLocalizations.of(context)!.today),
                ),
                DropdownMenuItem(
                  value: 'thisWeek',
                  child: Text(AppLocalizations.of(context)!.thisWeek),
                ),
                DropdownMenuItem(
                  value: 'thisMonth',
                  child: Text(AppLocalizations.of(context)!.thisMonth),
                ),
                DropdownMenuItem(
                  value: 'allTime',
                  child: Text(AppLocalizations.of(context)!.allTime),
                ),
              ],
              onChanged: (val) => setState(() => _timeFrame = val!),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "expenses_fab",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpensesScreen()),
          );
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.receipt_long, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.manageExpenses,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getBillsStream(),
        builder: (context, billsSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _service.getExpensesStream(),
            builder: (context, expensesSnapshot) {
              if (billsSnapshot.connectionState == ConnectionState.waiting ||
                  expensesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final now = DateTime.now();

              // 1. Process Bills
              final allBills = (billsSnapshot.data?.docs ?? [])
                  .map((d) => BillModel.fromSnapshot(d))
                  .toList();

              final filteredBills = allBills
                  .where((bill) => _filterDate(bill.date, now))
                  .toList();

              // 2. Process Expenses
              final allExpenses = (expensesSnapshot.data?.docs ?? [])
                  .map((d) => ExpenseModel.fromSnapshot(d))
                  .toList();

              final filteredExpenses = allExpenses
                  .where((exp) => _filterDate(exp.date, now))
                  .toList();

              // 3. Calculate Metrics
              double totalRevenue = 0;
              double totalCost = 0;
              int totalItemsSold = 0;

              for (var bill in filteredBills) {
                if (bill.partyType == 'customer') {
                  totalRevenue += bill.totalAmount;
                  for (var item in bill.items) {
                    // Robust null checks for item fields
                    final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
                    final price = (item['price'] as num?)?.toDouble() ?? 0.0;

                    // Using costPrice if available, otherwise fallback to 70% of price for legacy data
                    final cp =
                        (item['costPrice'] as num?)?.toDouble() ??
                        (price * 0.7);

                    totalCost += (qty * cp);
                    totalItemsSold += qty.toInt();
                  }
                }
              }

              double totalExpenseAmount = 0;
              for (var exp in filteredExpenses) {
                totalExpenseAmount += exp.amount;
              }

              final grossProfit = totalRevenue - totalCost;
              final netProfit = grossProfit - totalExpenseAmount;
              final isProfit = netProfit >= 0;
              final margin = totalRevenue > 0
                  ? (netProfit / totalRevenue) * 100
                  : 0.0;

              if (allBills.isEmpty && allExpenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 80,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No transaction or expense data available.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NET PROFIT CARD
                    ClayCard(
                      color: isProfit
                          ? const Color.fromARGB(255, 190, 250, 192)
                          : const Color.fromARGB(255, 252, 224, 224),
                      child: Column(
                        children: [
                          Text(
                            isProfit
                                ? AppLocalizations.of(
                                    context,
                                  )!.netProfit.toUpperCase()
                                : AppLocalizations.of(
                                    context,
                                  )!.netLoss.toUpperCase(),
                            style: TextStyle(
                              color: isProfit
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "₹${NumberFormat('#,##,###.##').format(netProfit.abs())}",
                            style: TextStyle(
                              color: isProfit
                                  ? Colors.green[900]
                                  : Colors.red[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMiniStat(
                                AppLocalizations.of(context)!.grossProfit,
                                grossProfit,
                                Colors.indigo,
                              ),
                              const SizedBox(width: 20),
                              _buildMiniStat(
                                AppLocalizations.of(context)!.margin,
                                margin,
                                isProfit ? Colors.green : Colors.red,
                                isPercent: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // SECTION TITLE
                    Text(
                      AppLocalizations.of(context)!.financialPerformance,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // CHART SECTION
                    ClayCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bar_chart,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.revenueVsExpenses,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AspectRatio(
                            aspectRatio: 1.7,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY:
                                    [
                                      totalRevenue,
                                      totalCost,
                                      totalExpenseAmount,
                                      netProfit.abs(),
                                    ].reduce((a, b) => a > b ? a : b) *
                                    1.2,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) =>
                                        Colors.indigo.withValues(alpha: 0.9),
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                          String label = [
                                            'Revenue',
                                            'Cost',
                                            'Expense',
                                            'Profit',
                                          ][group.x];
                                          return BarTooltipItem(
                                            '$label\n₹${rod.toY.toInt()}',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const labels = [
                                          'Rev',
                                          'Cost',
                                          'Exp',
                                          'Pft',
                                        ];
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < labels.length) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              labels[value.toInt()],
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: [
                                  _buildBarGroup(0, totalRevenue, Colors.blue),
                                  _buildBarGroup(1, totalCost, Colors.orange),
                                  _buildBarGroup(
                                    2,
                                    totalExpenseAmount,
                                    Colors.red,
                                  ),
                                  _buildBarGroup(
                                    3,
                                    netProfit > 0 ? netProfit : 0,
                                    Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // METRICS GRID
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.4,
                      children: [
                        _buildMetricCard(
                          AppLocalizations.of(context)!.revenue,
                          totalRevenue,
                          Icons.trending_up,
                          Colors.blue,
                        ),
                        _buildMetricCard(
                          AppLocalizations.of(context)!.inventoryCost,
                          totalCost,
                          Icons.inventory_2,
                          Colors.orange,
                        ),
                        _buildMetricCard(
                          AppLocalizations.of(context)!.operatingExpenses,
                          totalExpenseAmount,
                          Icons.payments,
                          Colors.red,
                        ),
                        _buildMetricCard(
                          AppLocalizations.of(context)!.itemsSold,
                          totalItemsSold.toDouble(),
                          Icons.shopping_bag,
                          Colors.teal,
                          isCurrency: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // RECENT EXPENSE PREVIEW
                    if (filteredExpenses.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.recentExpenses,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExpensesScreen(),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.viewAll),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...filteredExpenses
                          .take(3)
                          .map(
                            (exp) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClayCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getExpenseColor(
                                        exp.category,
                                      ).withValues(alpha: 0.1),
                                      child: Icon(
                                        _getExpenseIcon(exp.category),
                                        color: _getExpenseColor(exp.category),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exp.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'dd MMM',
                                            ).format(exp.date),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "₹${exp.amount.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: y * 0.1, // Subtle shadow base
            color: color.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    String label,
    double value,
    Color color, {
    bool isPercent = false,
  }) {
    return Column(
      children: [
        Text(
          isPercent
              ? "${value.toStringAsFixed(1)}%"
              : "₹${NumberFormat.compact().format(value)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  bool _filterDate(DateTime date, DateTime now) {
    switch (_timeFrame) {
      case 'today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'thisWeek':
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case 'thisMonth':
        return date.year == now.year && date.month == now.month;
      case 'allTime':
      default:
        return true;
    }
  }

  Widget _buildMetricCard(
    String title,
    double value,
    IconData icon,
    Color color, {
    bool isCurrency = true,
  }) {
    return ClayCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            isCurrency
                ? "₹${NumberFormat.compact().format(value)}"
                : value.toInt().toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExpenseIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.people;
      case 'rent':
        return Icons.home;
      case 'electricity':
        return Icons.electrical_services;
      case 'transport':
        return Icons.local_shipping;
      case 'marketing':
        return Icons.campaign;
      default:
        return Icons.category;
    }
  }

  Color _getExpenseColor(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Colors.purple;
      case 'rent':
        return Colors.blue;
      case 'electricity':
        return Colors.orange;
      case 'transport':
        return Colors.teal;
      case 'marketing':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }
}
