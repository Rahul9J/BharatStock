import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../data/expense_model.dart';
import 'add_expense_screen.dart';
import 'package:bharatstock/l10n/app_localizations.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final FirestoreService _service = FirestoreService();
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Rent',
    'Salary',
    'Electricity',
    'Maintenance',
    'Transport',
    'Marketing',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    const baseColor = kClayBaseColor;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.expenseManager),
        backgroundColor: baseColor,
        elevation: 0,
        foregroundColor: Colors.black,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getExpensesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noInvoicesFound,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ClayPrimaryButton(
                    text: "ADD FIRST EXPENSE",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddExpenseScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final allExpenses = snapshot.data!.docs
              .map((doc) => ExpenseModel.fromSnapshot(doc))
              .toList();
          final filteredExpenses = _selectedCategory == 'All'
              ? allExpenses
              : allExpenses
                    .where((e) => e.category == _selectedCategory)
                    .toList();

          double totalExpenses = filteredExpenses.fold(
            0.0,
            (prev, item) => prev + item.amount,
          );

          return Column(
            children: [
              // HEADER SUMMARY
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClayCard(
                  color: const Color.fromARGB(255, 250, 235, 233),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalSpending,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "₹${NumberFormat('#,##,###.##').format(totalExpenses)}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _selectedCategory == 'All'
                            ? AppLocalizations.of(context)!.allCategories
                            : "In $_selectedCategory",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CATEGORY CHIPS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 20),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: ClayContainer(
                          color: baseColor,
                          borderRadius: 20,
                          depth: isSelected ? -12 : 10,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.deepOrange
                                    : Colors.blueGrey,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // EXPENSE LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (ctx, i) {
                    final expense = filteredExpenses[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: ClayCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                expense.category,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              _getCategoryIcon(expense.category),
                              color: _getCategoryColor(expense.category),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            expense.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                DateFormat('dd MMM').format(expense.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  expense.type,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "- ₹${expense.amount.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          onLongPress: () => _confirmDelete(context, expense),
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

  void _confirmDelete(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.deleteExpense),
        content: Text(
          "${AppLocalizations.of(context)!.confirmDeleteExpense} ('${expense.title}')",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              _service.deleteExpense(expense.id);
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
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
      case 'maintenance':
        return Icons.build;
      case 'tea/coffee':
        return Icons.coffee;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
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
      case 'maintenance':
        return Colors.brown;
      case 'tea/coffee':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }
}
