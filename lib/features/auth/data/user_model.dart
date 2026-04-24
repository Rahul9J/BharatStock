class UserModel {
  final String uid;
  final String email;
  final String fullName; // User Name
  final String legalBusinessName; // Replaces shopName

  // Address Components
  final String flatShopNo;
  final String area;
  final String city;
  final String pincode;

  // GWST 2.0 Fields
  final String gstin; // Mandatory, 15-char
  final String businessStateCode; // Critical, 2-digit
  final String pan; // Optional but good for records

  // Bank Details (New 2026 Rule)
  final String bankAccountNo;
  final String bankIfsc;

  // Images
  final String userImageUrl;
  final String signatureImageUrl;

  // Multi-User & Onboarding (New Phase 1)
  final String role; // 'admin' or 'staff'
  final String businessId; // Linked business
  final String phoneNumber; // Added field
  final bool onboardingDone;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.legalBusinessName,
    this.flatShopNo = '',
    this.area = '',
    this.city = '',
    this.pincode = '',
    this.gstin = '',
    this.businessStateCode = '',
    this.pan = '',
    this.bankAccountNo = '',
    this.bankIfsc = '',
    this.userImageUrl = '',
    this.signatureImageUrl = '',
    this.role = 'admin',
    this.businessId = '',
    this.phoneNumber = '',
    this.onboardingDone = false,
  });

  // Helper to get full address for display
  String get fullAddress =>
      [flatShopNo, area, city, pincode].where((s) => s.isNotEmpty).join(', ');

  // Legacy getter for backward compatibility if needed
  String get shopName => legalBusinessName;
  String get address => fullAddress;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'legalBusinessName': legalBusinessName,
      'flatShopNo': flatShopNo,
      'area': area,
      'city': city,
      'pincode': pincode,
      'gstin': gstin,
      'businessStateCode': businessStateCode,
      'pan': pan,
      'bankAccountNo': bankAccountNo,
      'bankIfsc': bankIfsc,
      'userImageUrl': userImageUrl,
      'signatureImageUrl': signatureImageUrl,
      'role': role,
      'businessId': businessId,
      'phoneNumber': phoneNumber,
      'onboardingDone': onboardingDone,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      // Map legacy shopName to legalBusinessName if new key missing
      legalBusinessName: map['legalBusinessName'] ?? map['shopName'] ?? '',

      // Map legacy address to City or Area if new keys missing (simple migration)
      flatShopNo: map['flatShopNo'] ?? '',
      area: map['area'] ?? '',
      city: map['city'] ?? (map['address'] ?? ''), // Fallback for old data
      pincode: map['pincode'] ?? '',

      gstin: map['gstin'] ?? '',
      businessStateCode: map['businessStateCode'] ?? '',
      pan: map['pan'] ?? '',
      bankAccountNo: map['bankAccountNo'] ?? '',
      bankIfsc: map['bankIfsc'] ?? '',
      userImageUrl: map['userImageUrl'] ?? '',
      signatureImageUrl: map['signatureImageUrl'] ?? '',
      role: map['role'] ?? 'admin',
      businessId: map['businessId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      onboardingDone: map['onboardingDone'] ?? false,
    );
  }
}
