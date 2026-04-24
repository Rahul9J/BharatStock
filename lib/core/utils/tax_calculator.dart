/// GST 2.0 Tax Calculator Utility
///
/// Handles all GST math:
/// - Inclusive (MRP) pricing: Base = (Total × 100) / (100 + Rate)
/// - Exclusive pricing:       Tax  = (Base × Rate) / 100
/// - State split:             CGST = SGST = Rate/2 (Intra), IGST = Rate (Inter)
/// - GSTIN validation (15-char regex)
class TaxCalculator {
  // ---------------------------------------------------------------------------
  // GSTIN Validation
  // ---------------------------------------------------------------------------

  /// Validates a GSTIN string.
  /// Format: 22AAAAA0000A1Z5 (15 chars)
  static bool validateGstin(String gstin) {
    gstin = gstin.toUpperCase().trim();
    if (gstin.length != 15) return false;

    // Check regex: State(01-38) + PAN(5) + Num(4) + Check(1) + 1 + Z + Check(1)
    // Note: Simplified logic for 01-38
    final regex = RegExp(
      r'^(0[1-9]|[1-2][0-9]|3[0-8])[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    );
    return regex.hasMatch(gstin);
  }

  // ---------------------------------------------------------------------------
  // Inter / Intra State
  // ---------------------------------------------------------------------------

  /// Returns true if the transaction is inter-state (IGST applies).
  static bool isInterState(String businessStateCode, String partyStateCode) {
    return businessStateCode.trim() != partyStateCode.trim();
  }

  // ---------------------------------------------------------------------------
  // Core Tax Calculation
  // ---------------------------------------------------------------------------

  /// Calculates taxable value and tax amount from a given [amount].
  ///
  /// [amount]      — The price (MRP if inclusive, base price if exclusive)
  /// [rate]        — GST rate as percentage (e.g., 18.0)
  /// [isInclusive] — true = MRP (tax included), false = exclusive (tax added on top)
  static TaxResult calculateTax({
    required double amount,
    required double rate,
    required bool isInclusive,
  }) {
    if (rate <= 0) {
      return TaxResult(taxableValue: amount, taxAmount: 0);
    }

    if (isInclusive) {
      // Base = (Total × 100) / (100 + Rate)
      final taxableValue = (amount * 100) / (100 + rate);
      final taxAmount = amount - taxableValue;
      return TaxResult(
        taxableValue: _round(taxableValue),
        taxAmount: _round(taxAmount),
      );
    } else {
      // Tax = (Base × Rate) / 100
      final taxAmount = (amount * rate) / 100;
      return TaxResult(
        taxableValue: _round(amount),
        taxAmount: _round(taxAmount),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Tax Split (CGST/SGST vs IGST)
  // ---------------------------------------------------------------------------

  /// Splits [taxAmount] into CGST, SGST, or IGST based on state match.
  static TaxSplit splitTax({
    required double taxAmount,
    required bool isInterState,
  }) {
    if (isInterState) {
      return TaxSplit(cgst: 0, sgst: 0, igst: _round(taxAmount));
    } else {
      final half = _round(taxAmount / 2);
      return TaxSplit(cgst: half, sgst: half, igst: 0);
    }
  }

  // ---------------------------------------------------------------------------
  // Full Line-Item Calculation
  // ---------------------------------------------------------------------------

  /// Computes all GST fields for a single bill line item.
  ///
  /// Returns a [LineItemTax] with taxableValue, cgst, sgst, igst, grandTotal.
  static LineItemTax calculateLineItem({
    required double unitPrice,
    required double qty,
    required double gstRate,
    required bool isTaxInclusive,
    required bool interState,
  }) {
    final lineAmount = unitPrice * qty;
    final taxResult = calculateTax(
      amount: lineAmount,
      rate: gstRate,
      isInclusive: isTaxInclusive,
    );
    final split = splitTax(
      taxAmount: taxResult.taxAmount,
      isInterState: interState,
    );

    return LineItemTax(
      taxableValue: taxResult.taxableValue,
      taxAmount: taxResult.taxAmount,
      cgst: split.cgst,
      sgst: split.sgst,
      igst: split.igst,
      grandTotal: _round(taxResult.taxableValue + taxResult.taxAmount),
    );
  }

  // ---------------------------------------------------------------------------
  // Bill-Level Aggregation
  // ---------------------------------------------------------------------------

  /// Aggregates GST totals across all line items.
  static BillTaxSummary aggregateBill(List<LineItemTax> items) {
    double totalTaxable = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;
    double grandTotal = 0;

    for (final item in items) {
      totalTaxable += item.taxableValue;
      totalCgst += item.cgst;
      totalSgst += item.sgst;
      totalIgst += item.igst;
      grandTotal += item.grandTotal;
    }

    return BillTaxSummary(
      totalTaxableValue: _round(totalTaxable),
      totalCgst: _round(totalCgst),
      totalSgst: _round(totalSgst),
      totalIgst: _round(totalIgst),
      grandTotal: _round(grandTotal),
    );
  }

  // ---------------------------------------------------------------------------
  // ITC Calculation
  // ---------------------------------------------------------------------------

  /// Net GST Payable = Output Tax (collected) - Input Tax Credit (paid on purchases)
  static double calculateNetPayable({
    required double outputTax,
    required double inputTaxCredit,
  }) {
    return _round(outputTax - inputTaxCredit);
  }

  // ---------------------------------------------------------------------------
  // HSN Summary (for GSTR-1)
  // ---------------------------------------------------------------------------

  /// Builds a HSN-wise summary map: { hsnCode: taxableValue }
  static Map<String, double> buildHsnSummary(List<Map<String, dynamic>> items) {
    final Map<String, double> summary = {};
    for (final item in items) {
      final hsn = (item['hsnCode'] ?? '').toString();
      final taxable = (item['taxableValue'] ?? 0).toDouble();
      if (hsn.isNotEmpty) {
        summary[hsn] = (summary[hsn] ?? 0) + taxable;
      }
    }
    return summary;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static double _round(double value) {
    return (value * 100).round() / 100;
  }
}

// ---------------------------------------------------------------------------
// Result Classes
// ---------------------------------------------------------------------------

class TaxResult {
  final double taxableValue;
  final double taxAmount;

  const TaxResult({required this.taxableValue, required this.taxAmount});
}

class TaxSplit {
  final double cgst;
  final double sgst;
  final double igst;

  const TaxSplit({required this.cgst, required this.sgst, required this.igst});
}

class LineItemTax {
  final double taxableValue;
  final double taxAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double grandTotal;

  const LineItemTax({
    required this.taxableValue,
    required this.taxAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.grandTotal,
  });
}

class BillTaxSummary {
  final double totalTaxableValue;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double grandTotal;

  const BillTaxSummary({
    required this.totalTaxableValue,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.grandTotal,
  });

  double get totalTax => totalCgst + totalSgst + totalIgst;
}
