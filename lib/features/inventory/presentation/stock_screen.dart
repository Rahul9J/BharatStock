import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../data/stock_model.dart';
import 'add_edit_stock_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            // Search Bar — now wired to state
            ClayInput(
              hint: "Search products...",
              icon: Icons.search,
              controller: _searchController,
              onChanged: (v) {
                setState(() => _searchQuery = v.trim().toLowerCase());
              },
            ),
            const SizedBox(height: 20),

            // REAL-TIME LIST with local filter
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

                  // Apply search filter
                  final docs = snapshot.data!.docs.where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final stock = StockModel.fromSnapshot(doc);
                    return stock.name.toLowerCase().contains(_searchQuery) ||
                        stock.category.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No results for "$_searchQuery"',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

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
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
                                    color: stock.quantity < (stock.lowStockNotify)
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
