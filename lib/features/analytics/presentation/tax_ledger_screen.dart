import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../../billing/data/bill_model.dart';
import '../../inventory/data/stock_model.dart';
import 'package:bharatstock/l10n/app_localizations.dart';

class TaxLedgerScreen extends StatefulWidget {
  const TaxLedgerScreen({super.key});

  @override
  State<TaxLedgerScreen> createState() => _TaxLedgerScreenState();
}

class _TaxLedgerScreenState extends State<TaxLedgerScreen> {
  final FirestoreService _service = FirestoreService();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    const baseColor = kClayBaseColor;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.taxLedger),
        backgroundColor: baseColor,
        elevation: 0,
        foregroundColor: Colors.black,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black,
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([
          _service.getBillsFuture(),
          _service.getStocksFuture(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bills = (snapshot.data![0] as List<BillModel>)
              .where(
                (b) =>
                    b.date.month == _selectedDate.month &&
                    b.date.year == _selectedDate.year,
              )
              .toList();

          final stocks = (snapshot.data![1] as List<StockModel>)
              .where(
                (s) =>
                    s.createdAt.month == _selectedDate.month &&
                    s.createdAt.year == _selectedDate.year,
              )
              .toList();

          // Calculations
          double outputTax = bills.fold(
            0,
            (previousValue, b) =>
                previousValue + b.totalCgst + b.totalSgst + b.totalIgst,
          );
          double inputTax = stocks.fold(
            0,
            (previousValue, s) =>
                previousValue + (s.itcEligible ? s.itcAmount : 0),
          );
          double netPayable = outputTax - inputTax;

          // Combined Ledger Entries
          List<Map<String, dynamic>> entries = [];
          for (var b in bills) {
            entries.add({
              'date': b.date,
              'desc': "Sale: ${b.billNumber}",
              'type': 'OUTPUT',
              'amount': b.totalCgst + b.totalSgst + b.totalIgst,
              'color': Colors.red,
            });
          }
          for (var s in stocks) {
            if (s.itcEligible) {
              entries.add({
                'date': s.createdAt,
                'desc': "Purchase: ${s.name}",
                'type': 'ITC',
                'amount': s.itcAmount,
                'color': Colors.green,
              });
            }
          }
          entries.sort((a, b) => b['date'].compareTo(a['date']));

          return Column(
            children: [
              // MONTH SELECTOR
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildMonthPicker(baseColor),
              ),

              // SUMMARY CARDS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildSummaryCard("OUTPUT LIAB.", outputTax, Colors.red),
                    const SizedBox(width: 15),
                    _buildSummaryCard("INPUT CREDIT", inputTax, Colors.green),
                    const SizedBox(width: 15),
                    _buildSummaryCard(
                      "NET PAYABLE",
                      netPayable > 0 ? netPayable : 0,
                      Colors.deepOrange,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // LEDGER TABLE HEADER
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      "TRANSACTION HISTORY",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // LEDGER LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final entry = entries[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: ClayCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: entry['color'].withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                entry['type'] == 'OUTPUT'
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: entry['color'],
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry['desc'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd MMM, yyyy',
                                    ).format(entry['date']),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${entry['type'] == 'OUTPUT' ? '+' : '-'} ₹${entry['amount'].toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: entry['color'],
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  entry['type'],
                                  style: TextStyle(
                                    color: entry['color'].withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthPicker(Color baseColor) {
    return ClayContainer(
      color: baseColor,
      borderRadius: 15,
      depth: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: DropdownButton<int>(
          value: _selectedDate.month,
          underline: const SizedBox(),
          isExpanded: true,
          items: List.generate(
            12,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(
                DateFormat(
                  'MMMM yyyy',
                ).format(DateTime(_selectedDate.year, i + 1)),
              ),
            ),
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedDate = DateTime(_selectedDate.year, val));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return ClayCard(
      width: 150,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${NumberFormat('#,##,###').format(amount)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
