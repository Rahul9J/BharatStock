import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:clay_containers/clay_containers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatstock/l10n/app_localizations.dart';

import 'package:bharatstock/core/services/firestore_service.dart';
import 'package:bharatstock/features/home/presentation/widgets/home_drawer.dart';
import 'package:bharatstock/features/home/presentation/widgets/dashboard_card.dart';
import 'package:bharatstock/core/widgets/responsive_layout.dart';

// Import Screens from features
import 'package:bharatstock/features/staff/presentation/staff_list_screen.dart';
import 'package:bharatstock/features/inventory/presentation/stock_screen.dart';
import 'package:bharatstock/features/interactions/presentation/interaction_hub_screen.dart';
import 'package:bharatstock/features/accounting/presentation/party_list_screen.dart';
import 'package:bharatstock/features/analytics/presentation/profit_loss_screen.dart';
import 'package:bharatstock/features/analytics/presentation/tax_ledger_screen.dart';
import 'package:bharatstock/features/analytics/presentation/sales_screen.dart';
import 'package:bharatstock/features/analytics/presentation/gstr1_report_screen.dart';
import 'package:bharatstock/features/analytics/presentation/gstr3b_report_screen.dart';
import 'package:bharatstock/features/analytics/presentation/ca_export_screen.dart';
import 'package:bharatstock/features/analytics/presentation/expenses_screen.dart';
import 'package:bharatstock/features/billing/presentation/bill_generation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _desktopSelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const baseColor = Color(0xFFF2F4F8);
    final user = FirebaseAuth.instance.currentUser;

    return ResponsiveLayout(
      mobileBody: _buildMobileScaffold(context, l, baseColor, user),
      desktopBody: _buildDesktopScaffold(context, l, baseColor, user),
    );
  }

  Widget _buildMobileScaffold(
      BuildContext context, AppLocalizations l, Color baseColor, User? user) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: baseColor,
      drawer: const HomeDrawer(),
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: ClayContainer(
              borderRadius: 12,
              depth: 10,
              spread: 2,
              color: baseColor,
              child: const Icon(Icons.menu, color: Colors.black87),
            ),
          ),
        ),
        title: Text(
          l.hello,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: _buildBottomNav(context, l),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BillGenerationScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFFF9800),
        elevation: 4,
        child: const Icon(Icons.receipt_long, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: _buildHomeBody(context, l, baseColor, user),
    );
  }

  Widget _buildDesktopScaffold(
      BuildContext context, AppLocalizations l, Color baseColor, User? user) {
    return Scaffold(
      backgroundColor: baseColor,
      body: Row(
        children: [
          // CLAY SIDEBAR
          _buildDesktopSidebar(context, l, baseColor),
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  color: baseColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.hello,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Row(
                        children: [
                          _buildDesktopIconButton(Icons.notifications_outlined),
                          const SizedBox(width: 15),
                          _buildDesktopIconButton(Icons.settings_outlined),
                          const SizedBox(width: 15),
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFF9800),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildHomeBody(context, l, baseColor, user, isDesktop: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
      BuildContext context, AppLocalizations l, Color baseColor) {
    return Container(
      width: 250,
      margin: const EdgeInsets.all(15),
      child: ClayContainer(
        color: baseColor,
        borderRadius: 20,
        depth: 15,
        child: Column(
          children: [
            const SizedBox(height: 30),
            // APP LOGO
            const Icon(Icons.shopping_bag_rounded,
                size: 50, color: Color(0xFFFF9800)),
            const Text(
              "BharatStock",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 40),
            _buildSidebarItem(0, Icons.dashboard_outlined, "Dashboard"),
            _buildSidebarItem(1, Icons.receipt_long_outlined, "Bills"),
            _buildSidebarItem(2, Icons.people_outline, "Parties"),
            _buildSidebarItem(3, Icons.inventory_2_outlined, "Inventory"),
            _buildSidebarItem(4, Icons.insights_outlined, "Analytics"),
            const Spacer(),
            _buildSidebarItem(-1, Icons.logout_rounded, "Logout", onTap: () {
              FirebaseAuth.instance.signOut();
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title,
      {VoidCallback? onTap}) {
    final isSelected = _desktopSelectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: GestureDetector(
        onTap: onTap ?? () => setState(() => _desktopSelectedIndex = index),
        child: ClayContainer(
          color: const Color(0xFFF2F4F8),
          borderRadius: 12,
          depth: isSelected ? -10 : 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
                    size: 22),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF1A1A2E) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopIconButton(IconData icon) {
    return ClayContainer(
      color: const Color(0xFFF2F4F8),
      borderRadius: 12,
      depth: 10,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 20, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildHomeBody(
      BuildContext context, AppLocalizations l, Color baseColor, User? user,
      {bool isDesktop = false}) {
    return user == null
        ? const Center(child: Text("Please Login"))
        : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                debugPrint("HomeScreen: User Snap State: ${snapshot.connectionState}, HasData: ${snapshot.hasData}");
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("User data not found"));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final userName = userData['fullName'] ?? user.email?.split('@').first ?? 'User';
                final businessId = userData['businessId'] ?? '';
                final userImg = userData['userImageUrl'] as String?;
                final bool needsSetup = businessId.isEmpty;

                if (!needsSetup) {
                  FirestoreService().setBusinessId(businessId);
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: !needsSetup
                      ? FirebaseFirestore.instance
                          .collection('businesses')
                          .doc(businessId)
                          .snapshots()
                      : null,
                  builder: (context, bizSnap) {
                    debugPrint("HomeScreen: Biz Snap State: ${bizSnap.connectionState}, HasData: ${bizSnap.hasData}");
                    String shopName = l.yourShop;
                    if (bizSnap.hasData && bizSnap.data!.exists) {
                      final bizData = bizSnap.data!.data() as Map<String, dynamic>;
                      shopName = bizData['businessName'] ??
                          bizData['legalBusinessName'] ??
                          l.yourShop;
                    }

                    return SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. PROFILE HEADER
                            ClayContainer(
                              color: const Color(0xFFFFF5E1),
                              surfaceColor: const Color(0xFFFFFBF2),
                              borderRadius: 25,
                              depth: 20,
                              spread: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Row(
                                  children: [
                                    userImg != null && userImg.isNotEmpty
                                        ? CircleAvatar(
                                            radius: 27.0,
                                            backgroundImage: userImg.startsWith('data:image')
                                                ? MemoryImage(base64Decode(userImg.split(',').last))
                                                : NetworkImage(userImg) as ImageProvider,
                                            backgroundColor: Colors.orange,
                                          )
                                        : CircleAvatar(
                                            radius: 27.0,
                                            backgroundColor: Colors.orange,
                                            child: Icon(
                                              needsSetup ? Icons.priority_high : Icons.person,
                                              color: Colors.white,
                                            ),
                                          ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.welcome,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF7F8498),
                                            ),
                                          ),
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          needsSetup
                                              ? GestureDetector(
                                                  onTap: () => Navigator.pushNamed(
                                                    context,
                                                    '/complete-profile',
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.redAccent,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      l.completeSetup,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFE0B2),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const CircleAvatar(
                                                        radius: 4,
                                                        backgroundColor: Colors.deepOrange,
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        shopName,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.deepOrange,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            _buildPendingSection(l),
                            const SizedBox(height: 25),

                      // 3. MANAGE STORE GRID
                      Text(
                        l.manageStore,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF303030),
                        ),
                      ),
                      const SizedBox(height: 15),

                      LayoutBuilder(builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = isDesktop ? (width > 1400 ? 4 : (width > 900 ? 3 : 2)) : 2;
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.85,
                          children: [
                          DashboardCard(
                            title: l.waitersStaff,
                            subtitle: l.viewWorkers,
                            icon: Icons.people,
                            iconColor: const Color(0xFF2E7D32),
                            iconBgColor: const Color(0xFFE8F5E9),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StaffListScreen(),
                              ),
                            ),
                          ),
                          DashboardCard(
                            title: l.stockSubtitle.split(':').first,
                            subtitle: l.viewItems,
                            icon: Icons.inventory_2,
                            iconColor: const Color(0xFFE65100),
                            iconBgColor: const Color(0xFFFFF3E0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StockScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: l.myCustomers,
                            subtitle: l.manageCustomers,
                            icon: Icons.people_alt,
                            iconColor: const Color(0xFF2E7D32),
                            iconBgColor: const Color(0xFFE8F5E9),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PartyListScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: l.mySuppliers,
                            subtitle: l.manageSuppliers,
                            icon: Icons.local_shipping,
                            iconColor: const Color(0xFF1565C0),
                            iconBgColor: const Color(0xFFE3F2FD),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PartyListScreen(initialIndex: 1),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: l.expenseManager,
                            subtitle: l.expenses,
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: const Color(0xFFC2185B),
                            iconBgColor: const Color(0xFFFCE4EC),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ExpensesScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: l.profitLossAnalysis,
                            subtitle: l.analysis,
                            icon: Icons.insights,
                            iconColor: Colors.teal,
                            iconBgColor: Colors.teal.shade50,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfitLossScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: l.taxLedger,
                            subtitle: l.taxSummary,
                            icon: Icons.account_balance_wallet,
                            iconColor: Colors.indigo,
                            iconBgColor: Colors.indigo.shade50,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TaxLedgerScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: l.businessHub,
                            subtitle: l.businessHubSubtitle,
                            icon: Icons.business_center,
                            iconColor: const Color(0xFFFF9800),
                            iconBgColor: const Color(0xFFFFF3E0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InteractionHubScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: "GSTR-1",
                            subtitle: l.salesReport,
                            icon: Icons.description,
                            iconColor: Colors.deepOrange,
                            iconBgColor: Colors.deepOrange.shade50,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Gstr1ReportScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: "GSTR-3B",
                            subtitle: l.taxSummary,
                            icon: Icons.summarize,
                            iconColor: Colors.red,
                            iconBgColor: Colors.red.shade50,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Gstr3bReportScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: "CA Export",
                            subtitle: l.csvPdf,
                            icon: Icons.folder_shared,
                            iconColor: Colors.indigo,
                            iconBgColor: Colors.indigo.shade50,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CaExportScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: l.salesRevenue,
                            subtitle: l.transactions,
                            icon: Icons.history,
                            iconColor: Colors.purple,
                            iconBgColor: Colors.purple.shade50,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SalesScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }),

                      // 4. RECENT TRANSACTIONS
                      const SizedBox(height: 25),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirestoreService().getRecentBillsStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final bills = snapshot.data!.docs
                              .map((doc) => doc.data() as Map<String, dynamic>)
                              .toList();

                          return Column(
                            children: [
                              _buildRecentHeader(context, l),
                              const SizedBox(height: 15),
                              ...bills.map((data) {
                                final isCredit =
                                    data['paymentStatus'] == 'credit';
                                DateTime date;
                                if (data['date'] is Timestamp) {
                                  date = (data['date'] as Timestamp).toDate();
                                } else {
                                  date = DateTime.now();
                                }

                                final dateStr = "${date.day}/${date.month}";
                                final total =
                                    (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildTransactionTile(
                                    data['partyName'] ?? 'Unknown',
                                    "Bill #${data['invoiceNumber'] ?? ''} • $dateStr",
                                    "₹${total.toStringAsFixed(0)}",
                                    isCredit,
                                  ),
                                );
                              }),
                              const SizedBox(height: 80),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
  }

  Widget _buildPendingSection(AppLocalizations l) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getOverdueBillsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        int overdueCount = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['dueDate'] != null) {
            final dueDate = (data['dueDate'] as Timestamp).toDate();
            if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
              overdueCount++;
            }
          }
        }

        if (overdueCount == 0) return const SizedBox.shrink();

        return ClayContainer(
          color: const Color(0xFFFFF0F0),
          borderRadius: 20,
          depth: 10,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCDD2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.pendingPayment,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.overdueBills(overdueCount),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7F8498),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentHeader(BuildContext context, AppLocalizations l) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l.recentTransactions,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF303030),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SalesScreen()),
          ),
          child: Text(
            l.seeAll,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
    String title,
    String subtitle,
    String amount,
    bool isCredit,
  ) {
    return ClayContainer(
      borderRadius: 15,
      depth: 10,
      spread: 2,
      color: const Color(0xFFF2F4F8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit ? Colors.red[50] : Colors.green[50], // credit means pending payment for us
          child: Icon(
            isCredit ? Icons.hourglass_bottom : Icons.check_circle,
            color: isCredit ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCredit ? Colors.red : Colors.green,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // BOTTOM NAV
  Widget _buildBottomNav(BuildContext context, AppLocalizations l) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFFF2F4F8),
      child: SafeArea(
        bottom: true,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFFFF9800)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesScreen()),
                  );
                },
              ),
              const SizedBox(width: 40), // Space for floating action button
              IconButton(
                icon: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.grey,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfitLossScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.people, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PartyListScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
