import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../../../core/services/firestore_service.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import '../../billing/data/bill_model.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const baseColor = kClayBaseColor;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.salesSummary),
        backgroundColor: baseColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getBillsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allBills = (snapshot.data?.docs ?? [])
              .map((doc) => BillModel.fromSnapshot(doc))
              .where((bill) => bill.partyType == 'customer')
              .toList();

          if (allBills.isEmpty && snapshot.connectionState == ConnectionState.active) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.noInvoicesFound,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          final now = DateTime.now();
          final todayBills = allBills
              .where((b) => _isSameDay(b.date, now))
              .toList();
          final weekBills = allBills
              .where(
                (b) => b.date.isAfter(now.subtract(const Duration(days: 7))),
              )
              .toList();
          final monthBills = allBills
              .where(
                (b) => b.date.month == now.month && b.date.year == now.year,
              )
              .toList();

          double todaySales = todayBills.fold(
            0.0,
            (total, item) => total + item.totalAmount,
          );
          double weekSales = weekBills.fold(
            0.0,
            (total, item) => total + item.totalAmount,
          );
          double monthSales = monthBills.fold(
            0.0,
            (total, item) => total + item.totalAmount,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSaleCard(
                        AppLocalizations.of(context)!.todaySales,
                        todaySales,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildSaleCard(
                        AppLocalizations.of(context)!.thisWeek,
                        weekSales,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSaleCard(
                  AppLocalizations.of(context)!.thisMonth,
                  monthSales,
                  Colors.green,
                  isFullWidth: true,
                ),
                const SizedBox(height: 30),
                Text(
                  AppLocalizations.of(context)!.recentTransactions,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                if (allBills.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(
                        AppLocalizations.of(context)!.noInvoicesFound,
                      ),
                    ),
                  )
                else
                  ...allBills.take(10).map((bill) => _buildInvoiceItem(bill)),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildSaleCard(
    String title,
    double amount,
    Color color, {
    bool isFullWidth = false,
  }) {
    return ClayCard(
      color: kClayBaseColor,
      child: Column(
        crossAxisAlignment: isFullWidth
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isFullWidth ? 28 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(BillModel bill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClayCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.partyName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${DateFormat('dd MMM yyyy').format(bill.date)} | ${bill.billNumber}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${bill.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  bill.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: bill.paymentStatus == 'paid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
