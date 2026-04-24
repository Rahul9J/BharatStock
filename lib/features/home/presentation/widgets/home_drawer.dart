import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharatstock/core/providers/language_provider.dart';
import 'package:bharatstock/core/theme/font_size_provider.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, user, theme),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: l.dashboard,
                  onTap: () => Navigator.pop(context),
                  selected: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: l.billingInvoices,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sales');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: l.stockSubtitle.split(':').first, // Inventory
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/stock');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_alt_rounded,
                  title: l.staffManagement,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/staff');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.business_center_rounded,
                  title: l.businessHub,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/business-hub');
                  },
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.analytics_rounded,
                  title: l.analytics,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profit-loss');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: l.expenseManager,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/expenses');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.description_rounded,
                  title: l.taxLedger,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/tax-ledger');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_rounded,
                  title: l.partiesLedgers,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/parties');
                  },
                ),
                const Divider(),
                _buildLanguageSelector(context, l),
                _buildFontSizeSelector(context, l),
                const Divider(),
              ],
            ),
          ),
          _buildFooter(context, l),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user, ThemeData theme) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = user?.email?.split('@').first ?? 'User';
        String businessName = 'BharatStock Merchant';
        String? userImageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            name = data['fullName'] ?? name;
            businessName = data['businessName'] ?? businessName;
            // Use userImageUrl (consistent with UserModel) or fallback to photoUrl
            userImageUrl = data['userImageUrl'] ?? data['photoUrl'];
          }
        }

        return Container(
          padding: const EdgeInsets.only(
            top: 50,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                backgroundImage: userImageUrl != null
                    ? (userImageUrl.startsWith('data:image')
                          ? MemoryImage(
                              base64Decode(userImageUrl.split(',').last),
                            )
                          : NetworkImage(userImageUrl) as ImageProvider)
                    : null,
                child: userImageUrl == null
                    ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      businessName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).primaryColor : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      selected: selected,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Divider(color: Colors.white24, height: 1),
          _buildMenuItem(
            context,
            icon: Icons.logout_rounded,
            title: l.logout,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/language', (route) => false);
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                'v2.1.0 Premium',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, AppLocalizations l) {
    final langProvider = LanguageProvider.instance;
    return ListenableBuilder(
      listenable: langProvider,
      builder: (context, _) {
        return ExpansionTile(
          leading: const Icon(Icons.language_rounded, color: Colors.blue),
          title: Text(l.changeLanguage, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            langProvider.currentLocale.languageCode == 'hi'
                ? 'Hindi'
                : langProvider.currentLocale.languageCode == 'gu'
                ? 'Gujarati'
                : 'English',
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            _buildLangChip(context, 'English', 'en', langProvider),
            _buildLangChip(context, 'हिंदी (Hindi)', 'hi', langProvider),
            _buildLangChip(context, 'ગુજરાતી (Gujarati)', 'gu', langProvider),
          ],
        );
      },
    );
  }

  Widget _buildLangChip(
    BuildContext context,
    String label,
    String code,
    LanguageProvider provider,
  ) {
    final isSelected = provider.currentLocale.languageCode == code;
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () => provider.changeLanguage(code),
      dense: true,
    );
  }

  Widget _buildFontSizeSelector(BuildContext context, AppLocalizations l) {
    final fsProvider = FontSizeProvider.instance;
    return ListenableBuilder(
      listenable: fsProvider,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_size_rounded,
                    color: Colors.purple,
                    size: 20,
                  ),
                  SizedBox(width: 15),
                  Text(l.fontSize, style: const TextStyle(fontSize: 14)),
                ],
              ),
              Slider(
                value: fsProvider.scaleFactor,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                activeColor: Colors.purple,
                label: "${(fsProvider.scaleFactor * 100).toInt()}%",
                onChanged: (val) => fsProvider.update(val),
              ),
            ],
          ),
        );
      },
    );
  }
}
