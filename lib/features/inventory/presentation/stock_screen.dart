import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../data/stock_model.dart';
import 'add_edit_stock_screen.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text("Stock Management"),
        backgroundColor: const Color(0xFFF2F4F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditStockScreen()),
          );
        },
        backgroundColor: const Color(0xFFFFCA28),
        label: const Text("Add Item", style: TextStyle(color: Colors.black)),
        icon: const Icon(Icons.add, color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            ClayInput(
              hint: "Search products...",
              icon: Icons.search,
              onChanged: (v) {
                // Filter logic can be added here if needed
              },
            ),
            const SizedBox(height: 20),

            // REAL-TIME LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: service.getStocksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No items in stock. Add one!"),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final stock = StockModel.fromSnapshot(docs[index]);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditStockScreen(stock: stock),
                            ),
                          );
                        },
                        child: ClayCard(
                          borderRadius: 15,
                          depth: 10,
                          padding: const EdgeInsets.all(0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: ClayCard(
                              depth: -5,
                              padding: const EdgeInsets.all(8),
                              borderRadius: 10,
                              color: const Color(0xFFFFF3E0),
                              child: const Icon(
                                Icons.inventory_2,
                                color: Colors.orange,
                              ),
                            ),
                            title: Text(
                              stock.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Cat: ${stock.category}"),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${stock.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "Qty: ${stock.quantity.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    color:
                                        stock.quantity < (stock.lowStockNotify)
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            onLongPress: () {
                              _showDeleteDialog(context, service, stock);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    FirestoreService service,
    StockModel stock,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text("Are you sure you want to delete ${stock.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteStock(stock.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
