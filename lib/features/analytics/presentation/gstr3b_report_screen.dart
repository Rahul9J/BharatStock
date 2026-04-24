import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../../../core/services/firestore_service.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import '../../billing/data/bill_model.dart';
import '../services/excel_service.dart';

class Gstr3bReportScreen extends StatefulWidget {
  const Gstr3bReportScreen({super.key});

  @override
  State<Gstr3bReportScreen> createState() => _Gstr3bReportScreenState();
}

class _Gstr3bReportScreenState extends State<Gstr3bReportScreen> {
  final FirestoreService _service = FirestoreService();
  final ExcelService _excelService = ExcelService();
  DateTime _selectedMonth = DateTime.now();
  bool _loading = true;
  List<BillModel> _allBills = [];

  @override
  void initState() {
    super.initState();
    _loadBills();
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

  List<BillModel> get _salesBills => _allBills
      .where(
        (b) =>
            b.partyType == 'customer' &&
            b.date.month == _selectedMonth.month &&
            b.date.year == _selectedMonth.year,
      )
      .toList();

  List<BillModel> get _purchaseBills => _allBills
      .where(
        (b) =>
            b.partyType == 'supplier' &&
            b.date.month == _selectedMonth.month &&
            b.date.year == _selectedMonth.year,
      )
      .toList();

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
          AppLocalizations.of(context)!.gstr3bReport,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF9800),
        icon: const Icon(Icons.file_download, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.exportCSV,
          style: const TextStyle(color: Colors.white),
        ),
        onPressed: () => _excelService.exportGSTR3B(
          salesBills: _salesBills,
          purchaseBills: _purchaseBills,
          month: _selectedMonth,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMonthPicker(baseColor),
                  const SizedBox(height: 20),
                  _buildPeriodBadge(),
                  const SizedBox(height: 20),
                  _buildSection31(baseColor),
                  const SizedBox(height: 20),
                  _buildSection4(baseColor),
                  const SizedBox(height: 20),
                  _buildSection61(baseColor),
                  const SizedBox(height: 100), // FAB clearance
                ],
              ),
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

  Widget _buildPeriodBadge() {
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            "Return Period: ${DateFormat('MMMM yyyy').format(_selectedMonth)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3.1 Outward Supplies ---
  Widget _buildSection31(Color baseColor) {
    final sales = _salesBills;
    double taxable = 0, cgst = 0, sgst = 0, igst = 0;

    for (final b in sales) {
      taxable += b.totalTaxableValue;
      cgst += b.totalCgst;
      sgst += b.totalSgst;
      igst += b.totalIgst;
    }

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("3.1 Outward Supplies", Icons.outbox, Colors.red),
          const SizedBox(height: 20),
          _buildRow("Total Taxable Value", taxable),
          _buildRow("Integrated Tax (IGST)", igst),
          _buildRow("Central Tax (CGST)", cgst),
          _buildRow("State Tax (SGST)", sgst),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "NET TAX COLLECTED",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                "₹${(cgst + sgst + igst).toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. ITC ---
  Widget _buildSection4(Color baseColor) {
    final purchases = _purchaseBills;
    double cgst = 0, sgst = 0, igst = 0;

    for (final b in purchases) {
      cgst += b.totalCgst;
      sgst += b.totalSgst;
      igst += b.totalIgst;
    }

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("4. Eligible ITC", Icons.input, Colors.green),
          const SizedBox(height: 20),
          _buildRow("ITC on Imports", 0),
          _buildRow("ITC on Inward Supplies", igst + cgst + sgst),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "NET CREDIT AVAILABLE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                "₹${(cgst + sgst + igst).toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6.1 Tax Payable ---
  Widget _buildSection61(Color baseColor) {
    final sales = _salesBills;
    final purchases = _purchaseBills;

    double outTax = sales.fold(
      0,
      (sum, b) => sum + b.totalCgst + b.totalSgst + b.totalIgst,
    );
    double itcTax = purchases.fold(
      0,
      (sum, b) => sum + b.totalCgst + b.totalSgst + b.totalIgst,
    );
    double net = outTax - itcTax;

    return ClayCard(
      color: net > 0
          ? const Color.fromARGB(255, 246, 211, 208)
          : const Color.fromARGB(255, 190, 250, 192),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            net > 0 ? "GST PAYABLE" : "EXCESS ITC",
            style: const TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "₹${net.abs().toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: net > 0 ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            net > 0
                ? "Payable for ${DateFormat('MMM yyyy').format(_selectedMonth)}"
                : "Forwarded to next month",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
