import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../data/expense_model.dart';
import 'package:bharatstock/l10n/app_localizations.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Other';
  String _expenseType = 'One-time';
  bool _loading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Rent', 'icon': Icons.home, 'color': Colors.blue},
    {'name': 'Salary', 'icon': Icons.people, 'color': Colors.purple},
    {
      'name': 'Electricity',
      'icon': Icons.electrical_services,
      'color': Colors.orange,
    },
    {'name': 'Transport', 'icon': Icons.local_shipping, 'color': Colors.teal},
    {'name': 'Marketing', 'icon': Icons.campaign, 'color': Colors.pink},
    {'name': 'Maintenance', 'icon': Icons.build, 'color': Colors.brown},
    {'name': 'Other', 'icon': Icons.category, 'color': Colors.blueGrey},
  ];

  @override
  Widget build(BuildContext context) {
    const baseColor = kClayBaseColor;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addExpense),
        backgroundColor: baseColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(
                AppLocalizations.of(context)!.expenseTitle.toUpperCase(),
              ),
              const SizedBox(height: 10),
              ClayTextField(
                controller: _titleController,
                placeholder: "Ex: Office Rent, Internet Bill...",
                validator: (val) => val!.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 25),

              _buildLabel(
                "${AppLocalizations.of(context)!.amountLabel.toUpperCase()} (₹)",
              ),
              const SizedBox(height: 10),
              ClayTextField(
                controller: _amountController,
                placeholder: "0.00",
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Enter amount" : null,
              ),
              const SizedBox(height: 25),

              _buildLabel("DATE"),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDate,
                child: ClayCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.deepOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              _buildLabel(AppLocalizations.of(context)!.category.toUpperCase()),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat['name']),
                    child: ClayContainer(
                      color: baseColor,
                      borderRadius: 12,
                      depth: isSelected ? -12 : 10,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'],
                              size: 16,
                              color: isSelected ? cat['color'] : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['name'],
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? Colors.black : Colors.grey,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),

              _buildLabel("EXPENSE TYPE"),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildRadio("One-time"),
                  const SizedBox(width: 20),
                  _buildRadio("Recurring"),
                ],
              ),
              const SizedBox(height: 40),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ClayPrimaryButton(
                      text: "SAVE EXPENSE",
                      onTap: _saveExpense,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildRadio(String value) {
    final isSelected = _expenseType == value;
    return GestureDetector(
      onTap: () => setState(() => _expenseType = value),
      child: Row(
        children: [
          ClayContainer(
            height: 20,
            width: 20,
            borderRadius: 10,
            color: kClayBaseColor,
            depth: isSelected ? -10 : 10,
            child: isSelected
                ? Center(
                    child: Container(
                      height: 8,
                      width: 8,
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final expense = ExpenseModel(
        id: '',
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate,
        category: _selectedCategory,
        type: _expenseType,
      );

      await FirestoreService().addExpense(expense);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
