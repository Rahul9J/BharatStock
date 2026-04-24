import 'package:cloud_firestore/cloud_firestore.dart';

class StockModel {
  final String id;
  final String name;
  final double quantity;
  final double price; // Selling Price (MRP if isTaxInclusive, else excl. tax)
  final double costPrice; // Purchase Price (Subtotal or Total based on ITC)
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  // GST 2.0 Fields
  final String hsnCode;
  final double gstRate; // Selling GST Slab
  final bool isTaxInclusive; // for Selling Price
  final double lowStockNotify; // Threshold for low stock warning

  // Purchase / ITC Specific Fields
  final String supplierInvoiceNo;
  final DateTime? invoiceDate;
  final bool itcEligible;
  final double purchaseGstRate;
  final double itcAmount;
  final bool isVerifiedGstr2b;

  StockModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.costPrice = 0.0,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.hsnCode = '',
    this.gstRate = 0.0,
    this.isTaxInclusive = false,
    this.lowStockNotify = 5.0,
    this.supplierInvoiceNo = '',
    this.invoiceDate,
    this.itcEligible = true,
    this.purchaseGstRate = 0.0,
    this.itcAmount = 0.0,
    this.isVerifiedGstr2b = false,
  });

  factory StockModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockModel(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      price: (data['price'] ?? 0).toDouble(),
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      category: data['category'] ?? 'General',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hsnCode: data['hsnCode'] ?? '',
      gstRate: (data['gstRate'] ?? 0).toDouble(),
      isTaxInclusive: data['isTaxInclusive'] ?? false,
      lowStockNotify: (data['lowStockNotify'] ?? 5.0).toDouble(),
      supplierInvoiceNo: data['supplierInvoiceNo'] ?? '',
      invoiceDate: (data['invoiceDate'] as Timestamp?)?.toDate(),
      itcEligible: data['itcEligible'] ?? true,
      purchaseGstRate: (data['purchaseGstRate'] ?? 0.0).toDouble(),
      itcAmount: (data['itcAmount'] ?? 0.0).toDouble(),
      isVerifiedGstr2b: data['isVerifiedGstr2b'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'costPrice': costPrice,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'hsnCode': hsnCode,
      'gstRate': gstRate,
      'isTaxInclusive': isTaxInclusive,
      'lowStockNotify': lowStockNotify,
      'supplierInvoiceNo': supplierInvoiceNo,
      'invoiceDate': invoiceDate != null
          ? Timestamp.fromDate(invoiceDate!)
          : null,
      'itcEligible': itcEligible,
      'purchaseGstRate': purchaseGstRate,
      'itcAmount': itcAmount,
      'isVerifiedGstr2b': isVerifiedGstr2b,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
