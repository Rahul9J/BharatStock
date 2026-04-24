import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  final String id;
  final String billNumber;
  final String partyId;
  final String partyName;
  final String partyMobile;
  final DateTime date;
  final List<Map<String, dynamic>>
  items; // {name, qty, price, hsnCode, gstRate, taxableValue, cgst, sgst, igst, total}
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String paymentStatus; // 'paid' or 'credit'
  final String partyType; // 'customer' or 'supplier'

  // GST 2.0 Fields
  final String billType; // 'B2B' or 'B2C'
  final String customerGstin; // Counterparty GSTIN
  final String placeOfSupply; // State name/code
  final String taxType; // 'intra' or 'inter'
  final double totalTaxableValue;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final Map<String, double> hsnSummary;
  final String billingAddress;
  final String shippingAddress;
  final bool reverseCharge;

  BillModel({
    required this.id,
    required this.billNumber,
    required this.partyId,
    required this.partyName,
    required this.partyMobile,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.paymentStatus = 'paid',
    this.dueDate,
    this.partyType = 'customer',
    this.billType = 'B2C',
    this.customerGstin = '',
    this.placeOfSupply = '',
    this.taxType = 'intra',
    this.totalTaxableValue = 0.0,
    this.totalCgst = 0.0,
    this.totalSgst = 0.0,
    this.totalIgst = 0.0,
    this.hsnSummary = const {},
    this.billingAddress = '',
    this.shippingAddress = '',
    this.reverseCharge = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'billNumber': billNumber,
      'partyId': partyId,
      'partyName': partyName,
      'partyMobile': partyMobile,
      'date': Timestamp.fromDate(date),
      'items': items,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentStatus': paymentStatus,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'partyType': partyType,
      'billType': billType,
      'customerGstin': customerGstin,
      'placeOfSupply': placeOfSupply,
      'taxType': taxType,
      'totalTaxableValue': totalTaxableValue,
      'totalCgst': totalCgst,
      'totalSgst': totalSgst,
      'totalIgst': totalIgst,
      'hsnSummary': hsnSummary,
      'billingAddress': billingAddress,
      'shippingAddress': shippingAddress,
      'reverseCharge': reverseCharge,
    };
  }

  factory BillModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillModel(
      id: doc.id,
      billNumber: data['billNumber'] ?? '',
      partyId: data['partyId'] ?? '',
      partyName: data['partyName'] ?? '',
      partyMobile: data['partyMobile'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentStatus: data['paymentStatus'] ?? 'paid',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      partyType: data['partyType'] ?? 'customer',
      billType: data['billType'] ?? 'B2C',
      customerGstin: data['customerGstin'] ?? '',
      placeOfSupply: data['placeOfSupply'] ?? '',
      taxType: data['taxType'] ?? 'intra',
      totalTaxableValue: (data['totalTaxableValue'] ?? 0).toDouble(),
      totalCgst: (data['totalCgst'] ?? 0).toDouble(),
      totalSgst: (data['totalSgst'] ?? 0).toDouble(),
      totalIgst: (data['totalIgst'] ?? 0).toDouble(),
      hsnSummary: Map<String, double>.from(
        (data['hsnSummary'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      billingAddress: data['billingAddress'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      reverseCharge: data['reverseCharge'] ?? false,
    );
  }
}
