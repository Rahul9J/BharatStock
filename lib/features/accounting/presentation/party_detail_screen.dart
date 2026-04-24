import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/gst_constants.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../../billing/data/bill_model.dart';
import '../../analytics/services/excel_service.dart';
import '../data/party_model.dart';

class PartyDetailScreen extends StatelessWidget {
  final PartyModel party;

  const PartyDetailScreen({super.key, required this.party});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final excelService = ExcelService();

    return Scaffold(
      backgroundColor: kClayBaseColor,
      appBar: AppBar(
        title: Text(party.name, style: const TextStyle(color: Colors.black)),
        backgroundColor: kClayBaseColor,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: service.getPartyStream(party.id),
        builder: (context, partySnapshot) {
          if (!partySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final partyData = PartyModel.fromSnapshot(partySnapshot.data!);
          final double balance = partyData.balance;

          return StreamBuilder<QuerySnapshot>(
            stream: service.getBillsStream(),
            builder: (context, billsSnapshot) {
              if (billsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot>(
                stream: service.getPartyTransactionsStream(party.id),
                builder: (context, transSnapshot) {
                  if (transSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allBills = billsSnapshot.hasData
                      ? billsSnapshot.data!.docs
                            .map((d) => BillModel.fromSnapshot(d))
                            .toList()
                      : <BillModel>[];

                  // Filter Party Bills
                  final partyBills = allBills.where((b) {
                    final bool idMatch =
                        b.id ==
                        party.id; // Corrected to match business logic if needed
                    final bool nameMatch =
                        b.partyName.toLowerCase() ==
                        partyData.name.toLowerCase();
                    return idMatch || nameMatch;
                  }).toList();

                  // Process Transactions
                  final transactions = transSnapshot.hasData
                      ? transSnapshot.data!.docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return {
                            'type': 'payment',
                            'date':
                                (data['date'] as Timestamp?)?.toDate() ??
                                DateTime.now(),
                            'amount': (data['amount'] ?? 0).toDouble(),
                            'note': data['note'] ?? '',
                            'id': d.id,
                          };
                        }).toList()
                      : [];

                  // Merge & Sort
                  final List<Map<String, dynamic>> timeline = [];

                  for (var b in partyBills) {
                    timeline.add({
                      'type': 'bill',
                      'date': b.date,
                      'amount': b.totalAmount,
                      'title': "Bill #${b.billNumber}",
                      'subtitle': "${b.items.length} Items",
                      'isCredit': b.paymentStatus == 'credit',
                      'obj': b,
                    });
                  }

                  for (var t in transactions) {
                    timeline.add({
                      'type': 'payment',
                      'date': t['date'],
                      'amount': t['amount'],
                      'title': "Payment Received",
                      'subtitle': t['note'],
                      'isCredit': false,
                    });
                  }

                  timeline.sort(
                    (a, b) => (b['date'] as DateTime).compareTo(
                      a['date'] as DateTime,
                    ),
                  );

                  // Calculate Stats
                  double totalBusiness = partyBills.fold(
                    0.0,
                    (acc, item) => acc + item.totalAmount,
                  );

                  // Balance Color & Label Logic
                  Color balanceColor = Colors.grey;
                  String balanceLabel = "Settled";
                  String balanceText = "₹ 0";

                  if (partyData.type == 'customer') {
                    if (balance > 0) {
                      balanceColor = Colors.red;
                      balanceLabel = "Due Amount (To Receive)";
                      balanceText = "₹ ${balance.toStringAsFixed(2)}";
                    } else if (balance < 0) {
                      balanceColor = Colors.green;
                      balanceLabel = "Advance (To Pay)";
                      balanceText = "₹ ${balance.abs().toStringAsFixed(2)}";
                    }
                  } else {
                    // Supplier
                    if (balance < 0) {
                      balanceColor = Colors.red;
                      balanceLabel = "Due Amount (To Pay)";
                      balanceText = "₹ ${balance.abs().toStringAsFixed(2)}";
                    } else if (balance > 0) {
                      balanceColor = Colors.green;
                      balanceLabel = "Advance (To Receive)";
                      balanceText = "₹ ${balance.toStringAsFixed(2)}";
                    }
                  }

                  return CustomScrollView(
                    slivers: [
                      // 1. SUMMARY CARD
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ClayCard(
                            color: const Color(0xFFE8EAF6),
                            borderRadius: 20,
                            depth: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Total Business",
                                          style: TextStyle(
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "₹ ${totalBusiness.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          balanceLabel,
                                          style: TextStyle(
                                            color: balanceColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          balanceText,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: balanceColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 10),

                                // Detailed Party Info
                                _buildDetailRow("Mobile", partyData.mobile),
                                _buildDetailRow(
                                  "Type",
                                  partyData.type.toUpperCase(),
                                ),
                                _buildDetailRow(
                                  "Reg. Type",
                                  partyData.registrationType.toUpperCase(),
                                ),
                                if (partyData.gstin.isNotEmpty)
                                  _buildDetailRow("GSTIN", partyData.gstin),
                                if (partyData.stateCode.isNotEmpty)
                                  _buildDetailRow(
                                    "State",
                                    "${GstConstants.getStateName(partyData.stateCode)} (${partyData.stateCode})",
                                  ),
                                if (partyData.pan.isNotEmpty)
                                  _buildDetailRow("PAN", partyData.pan),

                                const SizedBox(height: 10),
                                const Text(
                                  "Billing Address:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  partyData.billingArea.isNotEmpty
                                      ? "${partyData.billingFlatShopNo}, ${partyData.billingArea}, ${partyData.billingCity}"
                                      : "N/A",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. EXPORT BUTTON
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GestureDetector(
                            onTap: () async {
                              if (partyBills.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No transactions to export"),
                                  ),
                                );
                                return;
                              }
                              await excelService.exportBillsToCSV(partyBills);
                            },
                            child: ClayCard(
                              borderRadius: 15,
                              depth: 10,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download, color: Colors.green),
                                  SizedBox(width: 10),
                                  Text(
                                    "Export Statement (CSV)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // 2.5 PIE CHART (Purchase Analysis)
                      if (partyBills.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: ClayCard(
                              borderRadius: 20,
                              depth: 10,
                              child: Column(
                                children: [
                                  const Text(
                                    "Purchase Analysis",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  AspectRatio(
                                    aspectRatio: 1.5,
                                    child: _buildPieChart(partyBills),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // 3. TRANSACTION LIST
                      timeline.isEmpty
                          ? const SliverFillRemaining(
                              child: Center(
                                child: Text("No transactions yet."),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final item = timeline[i];
                                final isPayment = item['type'] == 'payment';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 5,
                                  ),
                                  child: ClayCard(
                                    borderRadius: 12,
                                    depth: 5,
                                    padding: const EdgeInsets.all(8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isPayment
                                            ? Colors.green.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.blue.withValues(
                                                alpha: 0.1,
                                              ),
                                        child: Icon(
                                          isPayment
                                              ? Icons.payment
                                              : Icons.receipt,
                                          color: isPayment
                                              ? Colors.green
                                              : Colors.blue,
                                        ),
                                      ),
                                      title: Text(
                                        item['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy, hh:mm a',
                                            ).format(item['date']),
                                          ),
                                          if ((item['subtitle'] as String)
                                              .isNotEmpty)
                                            Text(
                                              item['subtitle'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Text(
                                        "₹ ${item['amount'].toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isPayment
                                              ? Colors.green
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }, childCount: timeline.length),
                            ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(context, service),
        label: const Text("Add Payment"),
        icon: const Icon(Icons.payment),
        backgroundColor: const Color.fromARGB(255, 218, 222, 244),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<BillModel> bills) {
    Map<String, double> itemQuantities = {};
    for (var bill in bills) {
      for (var item in bill.items) {
        String name = item['name'] ?? 'Unknown';
        double qty = (item['qty'] ?? item['quantity'] ?? 0).toDouble();
        itemQuantities[name] = (itemQuantities[name] ?? 0) + qty;
      }
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    int colorIndex = 0;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: itemQuantities.entries.map((e) {
          final color = colors[colorIndex % colors.length];
          colorIndex++;
          return PieChartSectionData(
            value: e.value,
            title: "${e.key}\n${e.value.toInt()}",
            color: color,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, FirestoreService service) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                helperText: "Positive value reduces balance (Customer paid)",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note (Optional)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null) return;

              await service.addPartyTransaction(
                partyId: party.id,
                amount: amount,
                note: noteController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
