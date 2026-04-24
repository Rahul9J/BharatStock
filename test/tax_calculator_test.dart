import 'package:flutter_test/flutter_test.dart';
import 'package:bharatstock/core/utils/tax_calculator.dart';

void main() {
  group('7.1 Unit Testing - Tax Calculator Tests', () {

    group('TC.1 GSTIN Validation', () {
      test('TC.1.1 - GSTIN Format Validation – Valid', () {
        // Expected valid format: 29ABCDE1234F1Z5
        final isValid = TaxCalculator.validateGstin('29ABCDE1234F1Z5');
        expect(isValid, true);
      });

      test('TC.1.2 - GSTIN Format Validation – Invalid Length', () {
        final isValid = TaxCalculator.validateGstin('29ABCDE1234F'); // 12 chars
        expect(isValid, false);
      });

      test('TC.1.3 - GSTIN Format Validation – Invalid Pattern', () {
        final isValid = TaxCalculator.validateGstin('99ABCDE1234F1Z5'); 
        expect(isValid, false);
      });
    });

    group('TC.2 Core Math (GST Scenarios)', () {
      test('TC.2.1 - Intra-state 18% GST Back-Calculation', () {
        // Inclusive price: ₹500, Rate: 18%
        // Taxable: ₹423.73, CGST: ₹38.14, SGST: ₹38.14
        final result = TaxCalculator.calculateLineItem(
          unitPrice: 500.0,
          qty: 1.0,
          gstRate: 18.0,
          isTaxInclusive: true,
          interState: false, // Intra-state
        );

        expect(result.taxableValue, closeTo(423.73, 0.01));
        expect(result.cgst, closeTo(38.14, 0.01));
        expect(result.sgst, closeTo(38.14, 0.01));
        expect(result.igst, 0.0);
        expect(result.grandTotal, 500.0);
      });

      test('TC.2.2 - Inter-state 12% GST Calculation', () {
        // Taxable: ₹1000, Rate: 12%, Inter-state
        // IGST: ₹120, Total: ₹1120, CGST: ₹0, SGST: ₹0
        final result = TaxCalculator.calculateLineItem(
          unitPrice: 1000.0,
          qty: 1.0,
          gstRate: 12.0,
          isTaxInclusive: false,
          interState: true, // Inter-state
        );

        expect(result.taxableValue, 1000.0);
        expect(result.igst, 120.0);
        expect(result.cgst, 0.0);
        expect(result.sgst, 0.0);
        expect(result.grandTotal, 1120.0);
      });

      test('TC.2.3 - Zero-Rate GST Product', () {
        // Taxable: ₹750, Rate: 0%
        // Total: ₹750, All tax components: ₹0
        final result = TaxCalculator.calculateLineItem(
          unitPrice: 750.0,
          qty: 1.0,
          gstRate: 0.0,
          isTaxInclusive: false,
          interState: false,
        );

        expect(result.taxableValue, 750.0);
        expect(result.cgst, 0.0);
        expect(result.sgst, 0.0);
        expect(result.igst, 0.0);
        expect(result.grandTotal, 750.0);
      });
    });

    group('TC.3 Billing Aggregation', () {
      test('TC.3.2 - Mixed GST Rate Bill (Multiple Products)', () {
        // Prod A: ₹500 @5%, Prod B: ₹1000 @18% (Exclusive)
        // Total Tax: ₹25+₹180=₹205, Total: ₹1705
        final prodA = TaxCalculator.calculateLineItem(
          unitPrice: 500.0,
          qty: 1.0,
          gstRate: 5.0,
          isTaxInclusive: false,
          interState: false,
        );
        
        final prodB = TaxCalculator.calculateLineItem(
          unitPrice: 1000.0,
          qty: 1.0,
          gstRate: 18.0,
          isTaxInclusive: false,
          interState: false,
        );

        final summary = TaxCalculator.aggregateBill([prodA, prodB]);

        expect(summary.totalTaxableValue, 1500.0);
        expect(summary.totalTax, 205.0);
        expect(summary.grandTotal, 1705.0);
      });
    });

  });
}
