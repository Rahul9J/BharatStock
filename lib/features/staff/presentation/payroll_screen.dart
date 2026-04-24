import 'package:flutter/material.dart';
import 'package:bharatstock/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:intl/intl.dart';
import '../data/staff_model.dart';
import '../logic/staff_service.dart';
import 'package:bharatstock/core/services/firestore_service.dart';
import 'package:bharatstock/features/analytics/data/expense_model.dart';

class PayrollScreen extends StatefulWidget {
  final String businessId;
  final StaffModel staff;

  const PayrollScreen({
    super.key,
    required this.businessId,
    required this.staff,
  });

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final StaffService _staffService = StaffService();
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  SalaryRecord? _currentRecord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalary();
  }

  void _loadSalary() async {
    setState(() => _isLoading = true);
    // We'll calculate it fresh for now to show live updates based on attendance
    final calculated = await _staffService.calculateSalary(
      widget.businessId,
      widget.staff,
      _selectedDate.month,
      _selectedDate.year,
    );

    if (mounted) {
      setState(() {
        _currentRecord = calculated;
        _isLoading = false;
      });
    }
  }

  void _markAsPaid() async {
    if (_currentRecord == null) return;

    setState(() => _isLoading = true);
    final paymentDate = DateTime.now();
    final paidRecord = SalaryRecord(
      monthYear: _currentRecord!.monthYear,
      presentDays: _currentRecord!.presentDays,
      totalWorkingDays: _currentRecord!.totalWorkingDays,
      calculatedSalary: _currentRecord!.calculatedSalary,
      bonus: _currentRecord!.bonus,
      status: 'Paid',
      paymentDate: paymentDate,
    );

    try {
      // 1. Save the salary record in the staff subcollection
      await _staffService.saveSalaryRecord(
        widget.businessId,
        widget.staff.id,
        paidRecord,
      );

      // 2. ✅ Write an expense entry so it shows in Expenses & Profit/Loss
      //    Use a deterministic ID (staffId_monthYear) to prevent duplicates.
      final expenseId = 'salary_${widget.staff.id}_${paidRecord.monthYear}';
      final totalPaid =
          paidRecord.calculatedSalary + paidRecord.bonus;
      final expense = ExpenseModel(
        id: expenseId,
        title: 'Salary – ${widget.staff.name} (${paidRecord.monthYear.replaceAll('_', '/')})',
        amount: totalPaid,
        date: paymentDate,
        category: 'Salary',
        type: 'recurring',
      );
      await _firestoreService.addExpense(expense);

      _loadSalary();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Salary of ₹${totalPaid.toStringAsFixed(0)} paid to ${widget.staff.name} '
              'and recorded in Expenses.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFF2F4F8);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: const Text("Payroll Management"),
        backgroundColor: baseColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMonthPicker(baseColor),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : _buildSalaryOverview(baseColor),
            const SizedBox(height: 40),
            if (!_isLoading &&
                _currentRecord != null &&
                _currentRecord!.totalWorkingDays > 0)
              ClayPrimaryButton(text: "MARK AS PAID", onTap: _markAsPaid),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPicker(Color baseColor) {
    return ClayContainer(
      color: baseColor,
      borderRadius: 15,
      depth: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Select Month",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(
                      () => _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month - 1,
                      ),
                    );
                    _loadSalary();
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(
                      () => _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                      ),
                    );
                    _loadSalary();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryOverview(Color baseColor) {
    if (_currentRecord == null || _currentRecord!.totalWorkingDays == 0) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              "No attendance marked for this month.",
              style: TextStyle(color: Colors.grey),
            ),
            const Text(
              "Salary cannot be calculated.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ClayContainer(
      color: baseColor,
      borderRadius: 25,
      depth: 15,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              widget.staff.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 30),
            _buildStatRow(
              "Fixed Monthly Salary",
              "₹${widget.staff.salaryPerMonth.toInt()}",
            ),
            const Divider(height: 30),
            _buildStatRow(
              "Days Marked (Working)",
              "${_currentRecord!.totalWorkingDays} Days",
            ),
            _buildStatRow(
              "Effective Present Days",
              "${_currentRecord!.presentDays} Days",
            ),
            const Divider(height: 30),
            _buildStatRow(
              "Calculated Salary",
              "₹${_currentRecord!.calculatedSalary.toStringAsFixed(2)}",
              isTotal: true,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _currentRecord!.status == 'Paid'
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentRecord!.status.toUpperCase(),
                style: TextStyle(
                  color: _currentRecord!.status == 'Paid'
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.blueGrey : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 20 : 14,
              color: isTotal ? Colors.deepOrange : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
