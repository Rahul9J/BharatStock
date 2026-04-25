import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../data/party_model.dart';
import 'add_party_screen.dart';
import 'party_detail_screen.dart';

class PartyListScreen extends StatelessWidget {
  final int initialIndex; // 0 for Customers, 1 for Suppliers

  const PartyListScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),
        appBar: AppBar(
          title: const Text("My Parties"),
          backgroundColor: const Color(0xFFF2F4F8),
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(text: "Customers"),
              Tab(text: "Suppliers"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPartyScreen()),
            );
          },
          backgroundColor: Colors.indigo,
          label: const Text("Add Party", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.person_add, color: Colors.white),
        ),
        body: TabBarView(
          children: [
            _PartyList(service: service, type: 'customer'),
            _PartyList(service: service, type: 'supplier'),
          ],
        ),
      ),
    );
  }
}

class _PartyList extends StatefulWidget {
  final FirestoreService service;
  final String type;

  const _PartyList({required this.service, required this.type});

  @override
  State<_PartyList> createState() => _PartyListState();
}

class _PartyListState extends State<_PartyList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          ClayInput(
            hint: "Search ${widget.type}s...",
            icon: Icons.search,
            controller: _searchController,
            onChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.service.getPartiesStream(type: widget.type),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No ${widget.type}s found",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Apply search filter by name, mobile, or city
                final docs = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final party = PartyModel.fromSnapshot(doc);
                  return party.name.toLowerCase().contains(_searchQuery) ||
                      party.mobile.toLowerCase().contains(_searchQuery) ||
                      party.billingCity.toLowerCase().contains(_searchQuery);
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
                  separatorBuilder: (context, index) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final party = PartyModel.fromSnapshot(docs[index]);
                    final isCustomer = party.type == 'customer';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartyDetailScreen(party: party),
                          ),
                        );
                      },
                      child: ClayCard(
                        borderRadius: 15,
                        depth: 10,
                        spread: 1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClayCard(
                            padding: const EdgeInsets.all(8),
                            borderRadius: 10,
                            depth: 5,
                            color: isCustomer
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            child: Icon(
                              isCustomer ? Icons.person : Icons.local_shipping,
                              color: isCustomer ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            party.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${party.mobile}${party.billingCity.isNotEmpty ? '\n${party.billingCity}' : ''}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
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
    );
  }
}
