import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../billing/data/bill_model.dart';

class ExcelService {
  // -------------------------------------------------------------------------
  // General Bills Export
  // -------------------------------------------------------------------------
  Future<void> exportBillsToCSV(List<BillModel> bills) async {
    List<List<dynamic>> rows = [];

    rows.add([
      "Bill Number",
      "Date",
      "Party Name",
      "Mobile",
      "Total Amount",
      "Items Count",
    ]);

    for (var bill in bills) {
      rows.add([
        bill.billNumber,
        DateFormat('yyyy-MM-dd').format(bill.date),
        bill.partyName,
        bill.partyMobile,
        bill.totalAmount.toStringAsFixed(2),
        bill.items.length,
      ]);
    }

    await _shareCSV(rows, 'bills_export');
  }

  // -------------------------------------------------------------------------
  // GSTR-1: HSN-wise Sales Details (for filing)
  // -------------------------------------------------------------------------
  Future<void> exportGSTR1(List<BillModel> salesBills) async {
    List<List<dynamic>> rows = [];

    rows.add([
      "Invoice No",
      "Invoice Date",
      "Customer Name",
      "Customer GSTIN",
      "Place of Supply",
      "Tax Type",
      "HSN Code",
      "Taxable Value",
      "CGST",
      "SGST",
      "IGST",
      "Total Tax",
      "Grand Total",
    ]);

    for (final bill in salesBills) {
      if (bill.hsnSummary.isNotEmpty) {
        for (final entry in bill.hsnSummary.entries) {
          rows.add([
            bill.billNumber,
            DateFormat('dd/MM/yyyy').format(bill.date),
            bill.partyName,
            bill.customerGstin.isEmpty ? 'Unregistered' : bill.customerGstin,
            bill.placeOfSupply,
            bill.taxType == 'inter'
                ? 'Inter-State (IGST)'
                : 'Intra-State (CGST+SGST)',
            entry.key,
            entry.value.toStringAsFixed(2),
            bill.totalCgst.toStringAsFixed(2),
            bill.totalSgst.toStringAsFixed(2),
            bill.totalIgst.toStringAsFixed(2),
            (bill.totalCgst + bill.totalSgst + bill.totalIgst).toStringAsFixed(
              2,
            ),
            bill.totalAmount.toStringAsFixed(2),
          ]);
        }
      } else {
        rows.add([
          bill.billNumber,
          DateFormat('dd/MM/yyyy').format(bill.date),
          bill.partyName,
          bill.customerGstin.isEmpty ? 'Unregistered' : bill.customerGstin,
          bill.placeOfSupply,
          bill.taxType == 'inter'
              ? 'Inter-State (IGST)'
              : 'Intra-State (CGST+SGST)',
          'N/A',
          bill.totalTaxableValue.toStringAsFixed(2),
          bill.totalCgst.toStringAsFixed(2),
          bill.totalSgst.toStringAsFixed(2),
          bill.totalIgst.toStringAsFixed(2),
          (bill.totalCgst + bill.totalSgst + bill.totalIgst).toStringAsFixed(2),
          bill.totalAmount.toStringAsFixed(2),
        ]);
      }
    }

    await _shareCSV(rows, 'GSTR1_export');
  }

  // -------------------------------------------------------------------------
  // GSTR-3B: Monthly Summary
  // -------------------------------------------------------------------------
  Future<void> exportGSTR3B({
    required List<BillModel> salesBills,
    required List<BillModel> purchaseBills,
    DateTime? month,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final monthLabel = DateFormat('MMMM_yyyy').format(targetMonth);

    final filteredSales = salesBills
        .where(
          (b) =>
              b.date.month == targetMonth.month &&
              b.date.year == targetMonth.year,
        )
        .toList();
    final filteredPurchases = purchaseBills
        .where(
          (b) =>
              b.date.month == targetMonth.month &&
              b.date.year == targetMonth.year,
        )
        .toList();

    double outCgst = 0, outSgst = 0, outIgst = 0, outTaxable = 0;
    for (final b in filteredSales) {
      outCgst += b.totalCgst;
      outSgst += b.totalSgst;
      outIgst += b.totalIgst;
      outTaxable += b.totalTaxableValue;
    }

    double itcCgst = 0, itcSgst = 0, itcIgst = 0;
    for (final b in filteredPurchases) {
      itcCgst += b.totalCgst;
      itcSgst += b.totalSgst;
      itcIgst += b.totalIgst;
    }

    final netCgst = outCgst - itcCgst;
    final netSgst = outSgst - itcSgst;
    final netIgst = outIgst - itcIgst;
    final netPayable = netCgst + netSgst + netIgst;

    List<List<dynamic>> rows = [];
    rows.add([
      "GSTR-3B Monthly Summary — ${DateFormat('MMMM yyyy').format(targetMonth)}",
    ]);
    rows.add([]);
    rows.add(["3.1 — Outward Supplies (Sales)"]);
    rows.add(["Description", "Taxable Value", "CGST", "SGST", "IGST"]);
    rows.add([
      "Total Sales",
      outTaxable.toStringAsFixed(2),
      outCgst.toStringAsFixed(2),
      outSgst.toStringAsFixed(2),
      outIgst.toStringAsFixed(2),
    ]);
    rows.add([]);
    rows.add(["4 — Eligible ITC (Purchases)"]);
    rows.add(["Description", "", "CGST", "SGST", "IGST"]);
    rows.add([
      "Total ITC Available",
      "",
      itcCgst.toStringAsFixed(2),
      itcSgst.toStringAsFixed(2),
      itcIgst.toStringAsFixed(2),
    ]);
    rows.add([]);
    rows.add(["Net GST Payable to Government"]);
    rows.add(["", "", "CGST", "SGST", "IGST", "Total"]);
    rows.add([
      "",
      "",
      netCgst.toStringAsFixed(2),
      netSgst.toStringAsFixed(2),
      netIgst.toStringAsFixed(2),
      netPayable.toStringAsFixed(2),
    ]);

    await _shareCSV(rows, 'GSTR3B_$monthLabel');
  }

  // -------------------------------------------------------------------------
  // Purchase Register Export (for CA)
  // -------------------------------------------------------------------------
  Future<String> exportPurchaseRegisterToFile(
    List<BillModel> purchaseBills,
  ) async {
    List<List<dynamic>> rows = [];
    rows.add([
      "Invoice No",
      "Invoice Date",
      "Supplier Name",
      "Supplier GSTIN",
      "Place of Supply",
      "Tax Type",
      "Taxable Value",
      "CGST",
      "SGST",
      "IGST",
      "Total Tax",
      "Grand Total",
      "Payment Status",
    ]);

    for (final bill in purchaseBills) {
      final totalTax = bill.totalCgst + bill.totalSgst + bill.totalIgst;
      rows.add([
        bill.billNumber,
        DateFormat('dd/MM/yyyy').format(bill.date),
        bill.partyName,
        bill.customerGstin.isEmpty ? 'Unregistered' : bill.customerGstin,
        bill.placeOfSupply,
        bill.taxType == 'inter' ? 'Inter-State' : 'Intra-State',
        bill.totalTaxableValue.toStringAsFixed(2),
        bill.totalCgst.toStringAsFixed(2),
        bill.totalSgst.toStringAsFixed(2),
        bill.totalIgst.toStringAsFixed(2),
        totalTax.toStringAsFixed(2),
        bill.totalAmount.toStringAsFixed(2),
        bill.paymentStatus,
      ]);
    }

    return await _writeCSVToFile(rows, 'purchase_register');
  }

  // -------------------------------------------------------------------------
  // Sales Register Export (for CA)
  // -------------------------------------------------------------------------
  Future<String> exportSalesRegisterToFile(List<BillModel> salesBills) async {
    List<List<dynamic>> rows = [];
    rows.add([
      "Invoice No",
      "Invoice Date",
      "Customer Name",
      "Customer GSTIN",
      "Bill Type",
      "Place of Supply",
      "Tax Type",
      "Taxable Value",
      "CGST",
      "SGST",
      "IGST",
      "Total Tax",
      "Grand Total",
      "Payment Status",
    ]);

    for (final bill in salesBills) {
      final totalTax = bill.totalCgst + bill.totalSgst + bill.totalIgst;
      rows.add([
        bill.billNumber,
        DateFormat('dd/MM/yyyy').format(bill.date),
        bill.partyName,
        bill.customerGstin.isEmpty ? 'Unregistered' : bill.customerGstin,
        bill.billType,
        bill.placeOfSupply,
        bill.taxType == 'inter' ? 'Inter-State' : 'Intra-State',
        bill.totalTaxableValue.toStringAsFixed(2),
        bill.totalCgst.toStringAsFixed(2),
        bill.totalSgst.toStringAsFixed(2),
        bill.totalIgst.toStringAsFixed(2),
        totalTax.toStringAsFixed(2),
        bill.totalAmount.toStringAsFixed(2),
        bill.paymentStatus,
      ]);
    }

    return await _writeCSVToFile(rows, 'sales_register');
  }

  // -------------------------------------------------------------------------
  // PDF Tax Summary (for CA)
  // -------------------------------------------------------------------------
  Future<String> generateTaxSummaryPDF({
    required String businessName,
    required String gstin,
    required List<BillModel> salesBills,
    required List<BillModel> purchaseBills,
    required DateTime from,
    required DateTime to,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    double salesTaxable = 0, salesCgst = 0, salesSgst = 0, salesIgst = 0;
    for (final b in salesBills) {
      salesTaxable += b.totalTaxableValue;
      salesCgst += b.totalCgst;
      salesSgst += b.totalSgst;
      salesIgst += b.totalIgst;
    }
    final salesTotal = salesTaxable + salesCgst + salesSgst + salesIgst;

    double purchTaxable = 0, purchCgst = 0, purchSgst = 0, purchIgst = 0;
    for (final b in purchaseBills) {
      purchTaxable += b.totalTaxableValue;
      purchCgst += b.totalCgst;
      purchSgst += b.totalSgst;
      purchIgst += b.totalIgst;
    }
    final purchTotal = purchTaxable + purchCgst + purchSgst + purchIgst;

    final netCgst = salesCgst - purchCgst;
    final netSgst = salesSgst - purchSgst;
    final netIgst = salesIgst - purchIgst;
    final netPayable = netCgst + netSgst + netIgst;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'GST TAX SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (gstin.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'GSTIN: $gstin',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              pw.Center(
                child: pw.Text(
                  'Period: ${dateFormat.format(from)} — ${dateFormat.format(to)}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Sales Summary
              pw.Text(
                'OUTWARD SUPPLIES (SALES)',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _buildPDFTable([
                ['Description', 'Amount (₹)'],
                ['Total Invoices', '${salesBills.length}'],
                ['Taxable Value', salesTaxable.toStringAsFixed(2)],
                ['CGST', salesCgst.toStringAsFixed(2)],
                ['SGST', salesSgst.toStringAsFixed(2)],
                ['IGST', salesIgst.toStringAsFixed(2)],
                ['Grand Total', salesTotal.toStringAsFixed(2)],
              ]),
              pw.SizedBox(height: 16),

              // Purchase Summary
              pw.Text(
                'INWARD SUPPLIES (PURCHASES)',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _buildPDFTable([
                ['Description', 'Amount (₹)'],
                ['Total Invoices', '${purchaseBills.length}'],
                ['Taxable Value', purchTaxable.toStringAsFixed(2)],
                ['CGST (ITC)', purchCgst.toStringAsFixed(2)],
                ['SGST (ITC)', purchSgst.toStringAsFixed(2)],
                ['IGST (ITC)', purchIgst.toStringAsFixed(2)],
                ['Grand Total', purchTotal.toStringAsFixed(2)],
              ]),
              pw.SizedBox(height: 16),

              // Net Payable
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'NET GST LIABILITY',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _buildPDFTable([
                ['Tax Head', 'Output', 'ITC', 'Net Payable'],
                [
                  'CGST',
                  salesCgst.toStringAsFixed(2),
                  purchCgst.toStringAsFixed(2),
                  netCgst.toStringAsFixed(2),
                ],
                [
                  'SGST',
                  salesSgst.toStringAsFixed(2),
                  purchSgst.toStringAsFixed(2),
                  netSgst.toStringAsFixed(2),
                ],
                [
                  'IGST',
                  salesIgst.toStringAsFixed(2),
                  purchIgst.toStringAsFixed(2),
                  netIgst.toStringAsFixed(2),
                ],
                [
                  'TOTAL',
                  (salesCgst + salesSgst + salesIgst).toStringAsFixed(2),
                  (purchCgst + purchSgst + purchIgst).toStringAsFixed(2),
                  netPayable.toStringAsFixed(2),
                ],
              ]),
              pw.SizedBox(height: 16),

              if (netPayable < 0)
                pw.Text(
                  'Note: Excess ITC of ₹${netPayable.abs().toStringAsFixed(2)} to be carried forward.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),

              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Generated on ${dateFormat.format(DateTime.now())} via BVM App',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/tax_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  pw.Widget _buildPDFTable(List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerRight,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.all(5),
      data: data,
    );
  }

  // -------------------------------------------------------------------------
  // CA Bundle Export (multiple CSVs + PDF)
  // -------------------------------------------------------------------------
  Future<void> exportCABundle({
    required String businessName,
    required String gstin,
    required List<BillModel> allBills,
    required DateTime from,
    required DateTime to,
    required bool includeSalesRegister,
    required bool includePurchaseRegister,
    required bool includePdfSummary,
  }) async {
    final salesBills = allBills
        .where(
          (b) =>
              b.partyType == 'customer' &&
              !b.date.isBefore(from) &&
              !b.date.isAfter(to),
        )
        .toList();
    final purchaseBills = allBills
        .where(
          (b) =>
              b.partyType == 'supplier' &&
              !b.date.isBefore(from) &&
              !b.date.isAfter(to),
        )
        .toList();

    List<XFile> files = [];

    if (includeSalesRegister) {
      final path = await exportSalesRegisterToFile(salesBills);
      files.add(XFile(path));
    }

    if (includePurchaseRegister) {
      final path = await exportPurchaseRegisterToFile(purchaseBills);
      files.add(XFile(path));
    }

    if (includePdfSummary) {
      final path = await generateTaxSummaryPDF(
        businessName: businessName,
        gstin: gstin,
        salesBills: salesBills,
        purchaseBills: purchaseBills,
        from: from,
        to: to,
      );
      files.add(XFile(path));
    }

    if (files.isEmpty) return;

    final periodLabel =
        '${DateFormat('MMMyyyy').format(from)}_${DateFormat('MMMyyyy').format(to)}';
    await Share.shareXFiles(
      files,
      text: 'CA Export Bundle — $businessName ($periodLabel)',
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  Future<void> _shareCSV(List<List<dynamic>> rows, String filename) async {
    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path =
        "${directory.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([
      XFile(path),
    ], text: 'Here is your $filename export (CSV)');
  }

  Future<String> _writeCSVToFile(
    List<List<dynamic>> rows,
    String filename,
  ) async {
    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path =
        "${directory.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    return path;
  }
}
