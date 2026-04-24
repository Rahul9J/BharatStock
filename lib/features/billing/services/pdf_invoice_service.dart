import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../auth/data/user_model.dart';
import '../data/bill_model.dart';

class PdfInvoiceService {
  Future<Uint8List> generateInvoice(BillModel bill, UserModel user) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            // Header: Tax Invoice Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "TAX INVOICE",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.Text(
                      bill.billType == 'B2B'
                          ? "(Original for Recipient)"
                          : "(Retail Invoice)",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      user.legalBusinessName.isNotEmpty
                          ? user.legalBusinessName
                          : "BharatStock User",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      user.address,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    if (user.gstin.isNotEmpty)
                      pw.Text(
                        "GSTIN: ${user.gstin}",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 15),

            // Party & Invoice Details
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Buyer Details
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Bill To:",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        bill.partyName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (bill.billingAddress.isNotEmpty)
                        pw.Text(
                          bill.billingAddress,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      if (bill.customerGstin.isNotEmpty)
                        pw.Text(
                          "GSTIN: ${bill.customerGstin}",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      pw.Text(
                        "Mobile: ${bill.partyMobile}",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                // Invoice Stats
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildInfoRow("Invoice #", bill.billNumber),
                    _buildInfoRow(
                      "Date",
                      DateFormat('dd-MMM-yyyy').format(bill.date),
                    ),
                    _buildInfoRow("POS", bill.placeOfSupply),
                    _buildInfoRow("Status", bill.paymentStatus.toUpperCase()),
                    if (bill.paymentStatus == 'credit' && bill.dueDate != null)
                      _buildInfoRow(
                        "Due Date",
                        DateFormat('dd-MMM-yyyy').format(bill.dueDate!),
                      ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Item Table
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo900,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Item
                1: const pw.FlexColumnWidth(1), // HSN
                2: const pw.FlexColumnWidth(1), // Qty
                3: const pw.FlexColumnWidth(1.5), // Price
                4: const pw.FlexColumnWidth(1.5), // Taxable
                5: const pw.FlexColumnWidth(1.5), // GST
                6: const pw.FlexColumnWidth(2), // Total
              },
              headers: [
                'Product/Service',
                'HSN',
                'Qty',
                'Rate',
                'Taxable',
                'GST%',
                'Total',
              ],
              data: bill.items.map((item) {
                return [
                  item['name'],
                  item['hsnCode'] ?? '-',
                  item['qty'].toString(),
                  item['price'].toStringAsFixed(2),
                  item['taxableValue'].toStringAsFixed(2),
                  "${item['gstRate'].toInt()}%",
                  item['total'].toStringAsFixed(2),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 15),

            // Totals & Tax Breakdown
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Tax Summary (Small Box)
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Tax Summary",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.TableHelper.fromTextArray(
                        context: context,
                        border: pw.TableBorder.all(
                          color: PdfColors.grey100,
                          width: 0.2,
                        ),
                        headerStyle: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        cellStyle: const pw.TextStyle(fontSize: 8),
                        headers: ['Slab', 'Taxable', 'CGST', 'SGST', 'IGST'],
                        data: _generateTaxRows(bill),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                // Final Amounts
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    children: [
                      _buildAmountRow(
                        "Sub-Total",
                        "Rs. ${bill.totalTaxableValue.toStringAsFixed(2)}",
                      ),
                      if (bill.taxType == 'intra') ...[
                        _buildAmountRow(
                          "CGST Total",
                          "Rs. ${bill.totalCgst.toStringAsFixed(2)}",
                        ),
                        _buildAmountRow(
                          "SGST Total",
                          "Rs. ${bill.totalSgst.toStringAsFixed(2)}",
                        ),
                      ] else
                        _buildAmountRow(
                          "IGST Total",
                          "Rs. ${bill.totalIgst.toStringAsFixed(2)}",
                        ),
                      pw.Divider(),
                      pw.Container(
                        color: PdfColors.grey200,
                        padding: const pw.EdgeInsets.all(5),
                        child: _buildAmountRow(
                          "Grand Total",
                          "Rs. ${bill.totalAmount.toStringAsFixed(2)}",
                          isBold: true,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Footer
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Terms & Conditions:",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "1. Goods once sold will not be taken back.",
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      "2. Interest @ 18% p.a. will be charged if not paid within due date.",
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text(
                      "For ${user.legalBusinessName}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      "Authorised Signatory",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
        footer: (context) {
          return pw.Center(
            child: pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount} | Powered by BharatStock",
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  List<List<String>> _generateTaxRows(BillModel bill) {
    // Group by slab
    Map<double, Map<String, double>> slabs = {};
    for (var item in bill.items) {
      final rate = (item['gstRate'] as num).toDouble();
      if (!slabs.containsKey(rate)) {
        slabs[rate] = {'taxable': 0, 'cgst': 0, 'sgst': 0, 'igst': 0};
      }
      slabs[rate]!['taxable'] =
          slabs[rate]!['taxable']! + (item['taxableValue'] as num).toDouble();
      slabs[rate]!['cgst'] =
          slabs[rate]!['cgst']! + (item['cgst'] as num).toDouble();
      slabs[rate]!['sgst'] =
          slabs[rate]!['sgst']! + (item['sgst'] as num).toDouble();
      slabs[rate]!['igst'] =
          slabs[rate]!['igst']! + (item['igst'] as num).toDouble();
    }
    return slabs.entries.map((e) {
      return [
        "${e.key.toInt()}%",
        e.value['taxable']!.toStringAsFixed(2),
        e.value['cgst']!.toStringAsFixed(2),
        e.value['sgst']!.toStringAsFixed(2),
        e.value['igst']!.toStringAsFixed(2),
      ];
    }).toList();
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            "$label: ",
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildAmountRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> shareOrPrint(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
  }
}
