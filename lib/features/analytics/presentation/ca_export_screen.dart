import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../../../core/services/firestore_service.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import '../services/excel_service.dart';

class CaExportScreen extends StatefulWidget {
  const CaExportScreen({super.key});

  @override
  State<CaExportScreen> createState() => _CaExportScreenState();
}

class _CaExportScreenState extends State<CaExportScreen> {
  final FirestoreService _service = FirestoreService();
  final ExcelService _excelService = ExcelService();

  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  bool _includeSalesRegister = true;
  bool _includePurchaseRegister = true;
  bool _includePdfSummary = true;

  bool _exporting = false;
  String _businessName = '';
  String _gstin = '';

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  Future<void> _loadBusinessInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!userDoc.exists) return;

    final userData = userDoc.data();
    final businessId = userData?['businessId'] ?? '';

    if (businessId.isNotEmpty) {
      final bizDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();
      final bizData = bizDoc.data();
      if (mounted && bizData != null) {
        setState(() {
          _businessName = bizData['businessName'] ?? 'My Business';
          _gstin = bizData['gstin'] ?? '';
        });
      }
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _exportBundle() async {
    if (!_includeSalesRegister &&
        !_includePurchaseRegister &&
        !_includePdfSummary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one report to export")),
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      final allBills = await _service.getBillsFuture();

      await _excelService.exportCABundle(
        businessName: _businessName,
        gstin: _gstin,
        allBills: allBills,
        from: _fromDate,
        to: _toDate,
        includeSalesRegister: _includeSalesRegister,
        includePurchaseRegister: _includePurchaseRegister,
        includePdfSummary: _includePdfSummary,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = kClayBaseColor;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(
          AppLocalizations.of(context)!.caExport,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            ClayCard(
              depth: 12,
              borderRadius: 18,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.indigo,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _businessName.isNotEmpty
                              ? _businessName
                              : 'Loading...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_gstin.isNotEmpty)
                          Text(
                            "GSTIN: $_gstin",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        Text(
                          AppLocalizations.of(context)!.exportReportsForCA,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Range Section
            Text(
              AppLocalizations.of(context)!.selectPeriod,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF303030),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    AppLocalizations.of(context)!.from,
                    dateFormat.format(_fromDate),
                    () => _pickDate(true),
                    baseColor,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey),
                ),
                Expanded(
                  child: _buildDateButton(
                    AppLocalizations.of(context)!.to,
                    dateFormat.format(_toDate),
                    () => _pickDate(false),
                    baseColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Report Selection
            Text(
              AppLocalizations.of(context)!.reportsToInclude,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF303030),
              ),
            ),
            const SizedBox(height: 12),

            _buildReportToggle(
              title: AppLocalizations.of(context)!.salesRegister,
              subtitle: AppLocalizations.of(context)!.salesRegisterDesc,
              icon: Icons.receipt_long,
              color: Colors.blue,
              value: _includeSalesRegister,
              onChanged: (v) =>
                  setState(() => _includeSalesRegister = v ?? true),
              baseColor: baseColor,
            ),
            const SizedBox(height: 10),

            _buildReportToggle(
              title: AppLocalizations.of(context)!.purchaseRegister,
              subtitle: AppLocalizations.of(context)!.purchaseRegisterDesc,
              icon: Icons.shopping_bag,
              color: Colors.teal,
              value: _includePurchaseRegister,
              onChanged: (v) =>
                  setState(() => _includePurchaseRegister = v ?? true),
              baseColor: baseColor,
            ),
            const SizedBox(height: 10),

            _buildReportToggle(
              title: AppLocalizations.of(context)!.taxSummaryPDF,
              subtitle: AppLocalizations.of(context)!.taxSummaryPdfDesc,
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              value: _includePdfSummary,
              onChanged: (v) => setState(() => _includePdfSummary = v ?? true),
              baseColor: baseColor,
            ),
            const SizedBox(height: 30),

            // Export Button
            ClayButton(
              text: _exporting
                  ? AppLocalizations.of(context)!.generating
                  : AppLocalizations.of(context)!.generateAndShare,
              onTap: _exporting ? () {} : _exportBundle,
              icon: _exporting ? Icons.sync : Icons.share,
              color: const Color(0xFFFF9800),
            ),
            const SizedBox(height: 16),

            // Info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Files will be shared as CSV + PDF. "
                      "Your CA can directly import them.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(
    String label,
    String value,
    VoidCallback onTap,
    Color baseColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: ClayCard(
        depth: 8,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color baseColor,
  }) {
    return ClayCard(
      depth: value ? 12 : 6,
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFFF9800),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
