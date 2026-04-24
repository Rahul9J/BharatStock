import 'package:cloud_firestore/cloud_firestore.dart';

class PartyModel {
  final String id;
  final String name;
  final String type; // 'customer' or 'supplier'
  final String mobile;
  final String? photoUrl;
  final double balance; // +ve -> You Receive, -ve -> You Pay
  final DateTime? createdAt;

  // GST 2.0 Fields
  final String registrationType; // 'unregistered', 'regular', 'composition'
  final String gstin; // Mandatory for regular/composition
  final String pan;
  final String stateCode; // 2-digit state code

  // Address - Billing
  final String billingFlatShopNo;
  final String billingArea;
  final String billingCity;
  final String billingPincode;

  // Supplier Specific (Bank Details)
  final String bankAccount;
  final String ifscCode;

  // Address - Shipping
  final bool isShippingSame;
  final String shippingFlatShopNo;
  final String shippingArea;
  final String shippingCity;
  final String shippingPincode;

  // Shadow Profile / B2B Link
  final bool isRegisteredOnApp;
  final String? linkedBusinessId;

  PartyModel({
    required this.id,
    required this.name,
    required this.type,
    required this.mobile,
    this.photoUrl,
    this.balance = 0.0,
    this.createdAt,
    this.registrationType = 'unregistered',
    this.gstin = '',
    this.pan = '',
    this.stateCode = '',
    this.billingFlatShopNo = '',
    this.billingArea = '',
    this.billingCity = '',
    this.billingPincode = '',
    this.isShippingSame = true,
    this.shippingFlatShopNo = '',
    this.shippingArea = '',
    this.shippingCity = '',
    this.shippingPincode = '',
    this.bankAccount = '',
    this.ifscCode = '',
    this.isRegisteredOnApp = false,
    this.linkedBusinessId,
  });

  // Helper getters for backward compatibility or easy display
  String get address => billingAddress;
  String get billingAddress => [
    billingFlatShopNo,
    billingArea,
    billingCity,
    billingPincode,
  ].where((s) => s.isNotEmpty).join(', ');
  String get shippingAddress => isShippingSame
      ? billingAddress
      : [
          shippingFlatShopNo,
          shippingArea,
          shippingCity,
          shippingPincode,
        ].where((s) => s.isNotEmpty).join(', ');

  factory PartyModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartyModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'customer',
      mobile: data['mobile'] ?? '',
      photoUrl: data['photoUrl'],
      balance: (data['balance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      registrationType: data['registrationType'] ?? 'unregistered',
      gstin: data['gstin'] ?? '',
      pan: data['pan'] ?? '',
      stateCode: data['stateCode'] ?? '',
      billingFlatShopNo: data['billingFlatShopNo'] ?? '',
      billingArea: data['billingArea'] ?? '',
      billingCity: data['billingCity'] ?? (data['address'] ?? ''), // Fallback
      billingPincode: data['billingPincode'] ?? '',
      isShippingSame: data['isShippingSame'] ?? true,
      shippingFlatShopNo: data['shippingFlatShopNo'] ?? '',
      shippingArea: data['shippingArea'] ?? '',
      shippingCity: data['shippingCity'] ?? '',
      shippingPincode: data['shippingPincode'] ?? '',
      bankAccount: data['bankAccount'] ?? '',
      ifscCode: data['ifscCode'] ?? '',
      isRegisteredOnApp: data['isRegisteredOnApp'] ?? false,
      linkedBusinessId: data['linkedBusinessId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'mobile': mobile,
      'photoUrl': photoUrl,
      'balance': balance,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'registrationType': registrationType,
      'gstin': gstin,
      'pan': pan,
      'stateCode': stateCode,
      'billingFlatShopNo': billingFlatShopNo,
      'billingArea': billingArea,
      'billingCity': billingCity,
      'billingPincode': billingPincode,
      'isShippingSame': isShippingSame,
      'shippingFlatShopNo': shippingFlatShopNo,
      'shippingArea': shippingArea,
      'shippingCity': shippingCity,
      'shippingPincode': shippingPincode,
      'bankAccount': bankAccount,
      'ifscCode': ifscCode,
      'isRegisteredOnApp': isRegisteredOnApp,
      'linkedBusinessId': linkedBusinessId,
    };
  }
}
