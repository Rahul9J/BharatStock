import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../../../core/services/firestore_service.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import '../../billing/data/bill_model.dart';
import '../services/excel_service.dart';

class Gstr1ReportScreen extends StatefulWidget {
  const Gstr1ReportScreen({super.key});

  @override
  State<Gstr1ReportScreen> createState() => _Gstr1ReportScreenState();
}

class _Gstr1ReportScreenState extends State<Gstr1ReportScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _service = FirestoreService();
  final ExcelService _excelService = ExcelService();
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  bool _loading = true;
  List<BillModel> _allBills = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    setState(() => _loading = true);
    final bills = await _service.getBillsFuture();
    if (mounted) {
      setState(() {
        _allBills = bills;
        _loading = false;
      });
    }
  }

  List<BillModel> get _filteredSales =>
      _allBills
          .where(
            (b) =>
                b.partyType == 'customer' &&
                b.date.month == _selectedMonth.month &&
                b.date.year == _selectedMonth.year,
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<BillModel> get _b2bBills =>
      _filteredSales.where((b) => b.billType == 'B2B').toList();

  List<BillModel> get _b2cBills =>
      _filteredSales.where((b) => b.billType == 'B2C').toList();

  Map<String, Map<String, double>> get _hsnAggregated {
    final Map<String, Map<String, double>> result = {};
    for (final bill in _filteredSales) {
      for (final item in bill.items) {
        final hsn = (item['hsnCode'] ?? 'N/A').toString();
        if (hsn.isEmpty) continue;
        final taxableValue = ((item['taxableValue'] ?? 0) as num).toDouble();
        final cgst = ((item['cgst'] ?? 0) as num).toDouble();
        final sgst = ((item['sgst'] ?? 0) as num).toDouble();
        final igst = ((item['igst'] ?? 0) as num).toDouble();

        if (!result.containsKey(hsn)) {
          result[hsn] = {
            'taxable': 0,
            'cgst': 0,
            'sgst': 0,
            'igst': 0,
            'total': 0,
          };
        }
        result[hsn]!['taxable'] = result[hsn]!['taxable']! + taxableValue;
        result[hsn]!['cgst'] = result[hsn]!['cgst']! + cgst;
        result[hsn]!['sgst'] = result[hsn]!['sgst']! + sgst;
        result[hsn]!['igst'] = result[hsn]!['igst']! + igst;
        result[hsn]!['total'] =
            result[hsn]!['total']! + taxableValue + cgst + sgst + igst;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = kClayBaseColor;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(
          AppLocalizations.of(context)!.gstr1Report,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_present, color: Colors.blue),
            onPressed: () => _excelService.exportGSTR1(_filteredSales),
            tooltip: "Export to Excel",
          ),
        ],
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          indicatorWeight: 3,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.b2bInvoices),
            Tab(text: AppLocalizations.of(context)!.b2cInvoices),
            Tab(text: AppLocalizations.of(context)!.hsnSummary),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month picker
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildMonthPicker(baseColor),
                ),

                // Premium Summary Chart and Cards
                if (_filteredSales.isNotEmpty) ...[_buildTopSummary(baseColor)],

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildB2BTab(baseColor),
                      _buildB2CTab(baseColor),
                      _buildHSNTab(baseColor),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTopSummary(Color baseColor) {
    double totalTaxable = 0, totalCgst = 0, totalSgst = 0, totalIgst = 0;
    for (var b in _filteredSales) {
      totalTaxable += b.totalTaxableValue;
      totalCgst += b.totalCgst;
      totalSgst += b.totalSgst;
      totalIgst += b.totalIgst;
    }
    final totalGst = totalCgst + totalSgst + totalIgst;

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Left: Mini Chart
          Expanded(
            flex: 4,
            child: ClayCard(
              padding: const EdgeInsets.all(12),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 25,
                  sections: [
                    PieChartSectionData(
                      value: totalTaxable,
                      color: Colors.blue.withValues(alpha: 0.7),
                      radius: 12,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: totalGst,
                      color: Colors.orange.withValues(alpha: 0.7),
                      radius: 12,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right: Key Numbers
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniMetric(
                  AppLocalizations.of(context)!.taxableValue,
                  totalTaxable,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildMiniMetric(
                  AppLocalizations.of(context)!.totalTax,
                  totalGst,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, double value, Color color) {
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
              Text(
                "₹${NumberFormat('#,##,###').format(value)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Icon(
            Icons.trending_up,
            size: 16,
            color: color.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker(Color baseColor) {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return ClayContainer(
      color: baseColor,
      borderRadius: 15,
      depth: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: Colors.deepOrange,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButton<int>(
                value: _selectedMonth.month,
                underline: const SizedBox(),
                isExpanded: true,
                items: List.generate(12, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                      "${months[i]} ${_selectedMonth.year}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setState(
                      () => _selectedMonth = DateTime(_selectedMonth.year, val),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildB2BTab(Color baseColor) {
    final bills = _b2bBills;
    if (bills.isEmpty) return _buildEmptyState("No B2B invoices this month");

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final totalTax = bill.totalCgst + bill.totalSgst + bill.totalIgst;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClayCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bill.billNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(bill.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _buildRow("Party Name", bill.partyName),
                _buildRow(
                  "GSTIN",
                  bill.customerGstin.isEmpty ? "N/A" : bill.customerGstin,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmountInfo("Taxable", bill.totalTaxableValue),
                    _buildAmountInfo("GST", totalTax, color: Colors.orange),
                    _buildAmountInfo("Total", bill.totalAmount, bold: true),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildB2CTab(Color baseColor) {
    final bills = _b2cBills;
    if (bills.isEmpty) return _buildEmptyState("No B2C invoices this month");

    double totalTaxable = 0, totalGst = 0;
    for (final b in bills) {
      totalTaxable += b.totalTaxableValue;
      totalGst += (b.totalCgst + b.totalSgst + b.totalIgst);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClayCard(
          color: Colors.orange.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "B2C AGGREGATE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    "Invoices",
                    bills.length.toString(),
                    Colors.blue,
                  ),
                  _buildStatCard(
                    "Total Taxable",
                    "₹${totalTaxable.toStringAsFixed(0)}",
                    Colors.teal,
                  ),
                  _buildStatCard(
                    "Total GST",
                    "₹${totalGst.toStringAsFixed(0)}",
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...bills.map(
          (bill) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClayCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  bill.billNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${bill.partyName} • ${DateFormat('dd MMM').format(bill.date)}",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  "₹${bill.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHSNTab(Color baseColor) {
    final hsnData = _hsnAggregated;
    if (hsnData.isEmpty) return _buildEmptyState("No HSN data this month");

    final entries = hsnData.entries.toList()
      ..sort((a, b) => b.value['total']!.compareTo(a.value['total']!));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final data = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClayCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "HSN ${entry.key}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    Text(
                      "₹${data['total']!.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSmallMetric("Taxable", data['taxable']!),
                    _buildSmallMetric("CGST", data['cgst']!),
                    _buildSmallMetric("SGST", data['sgst']!),
                    _buildSmallMetric("IGST", data['igst']!),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HELPERS ---

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(
    String label,
    double value, {
    Color? color,
    bool bold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          "₹${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSmallMetric(String label, double value) {
    return Column(
      children: [
        Text(
          "₹${value.toStringAsFixed(0)}",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
