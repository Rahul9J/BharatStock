import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/billing/data/bill_model.dart';
import '../../features/analytics/data/expense_model.dart';
import '../../features/inventory/data/stock_model.dart';

class FirestoreService {
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _businessId;

  // Initialize businessId (should be called after login/onboarding)
  void setBusinessId(String id) {
    _businessId = id;
  }

  // --- GENERIC BUSINESS-COLLECTION HELPERS ---

  // Get reference to a subcollection under the current business
  // e.g., businesses/{businessId}/stocks
  CollectionReference? _businessCollection(String collectionName) {
    if (_businessId == null) return null;
    return _db
        .collection('businesses')
        .doc(_businessId)
        .collection(collectionName);
  }

  // --- STOCKS MANAGEMENT ---

  // Add Stock Item
  Future<void> addStock({
    required String name,
    required double quantity,
    required double price,
    String? category,
    double costPrice = 0.0,
    String hsnCode = '',
    double gstRate = 0.0,
    bool isTaxInclusive = false,
    String supplierInvoiceNo = '',
    DateTime? invoiceDate,
    bool itcEligible = true,
    double purchaseGstRate = 0.0,
    double lowStockNotify = 5.0,
    double itcAmount = 0.0,
    bool isVerifiedGstr2b = false,
  }) async {
    final stocksRef = _businessCollection('stocks');
    if (stocksRef == null) throw Exception("User not logged in");

    await stocksRef.add({
      'name': name,
      'quantity': quantity,
      'price': price,
      'costPrice': costPrice,
      'category': category ?? 'General',
      'hsnCode': hsnCode,
      'gstRate': gstRate,
      'isTaxInclusive': isTaxInclusive,
      'lowStockNotify': lowStockNotify,
      'supplierInvoiceNo': supplierInvoiceNo,
      'invoiceDate': invoiceDate != null
          ? Timestamp.fromDate(invoiceDate)
          : null,
      'itcEligible': itcEligible,
      'purchaseGstRate': purchaseGstRate,
      'itcAmount': itcAmount,
      'isVerifiedGstr2b': isVerifiedGstr2b,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Stocks Stream
  Stream<QuerySnapshot> getStocksStream() {
    final stocksRef = _businessCollection('stocks');
    if (stocksRef == null) return const Stream.empty();

    return stocksRef.orderBy('updatedAt', descending: true).snapshots();
  }

  // Update Stock
  Future<void> updateStock(String id, Map<String, dynamic> data) async {
    final stocksRef = _businessCollection('stocks');
    if (stocksRef == null) throw Exception("User not logged in");

    data['updatedAt'] = FieldValue.serverTimestamp();
    await stocksRef.doc(id).update(data);
  }

  // Delete Stock
  Future<void> deleteStock(String id) async {
    final stocksRef = _businessCollection('stocks');
    if (stocksRef == null) throw Exception("User not logged in");

    await stocksRef.doc(id).delete();
  }

  // Update Stock Quantity (Deduction/Addition)
  Future<void> updateStockQuantity(String id, double change) async {
    final stocksRef = _businessCollection('stocks');
    if (stocksRef == null) throw Exception("User not logged in");

    await stocksRef.doc(id).update({
      'quantity': FieldValue.increment(change),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Stocks Future
  Future<List<StockModel>> getStocksFuture() async {
    final stocksRef = _businessCollection('stocks');
    if (stocksRef == null) return [];
    final snap = await stocksRef.get();
    return snap.docs.map((doc) => StockModel.fromSnapshot(doc)).toList();
  }

  // --- PARTIES (Suppliers / Customers) ---

  // Add Party
  Future<void> addParty({
    required String name,
    required String type, // 'supplier' or 'customer'
    required String mobile,
    String registrationType = 'unregistered',
    String gstin = '',
    String pan = '',
    String stateCode = '',
    String billingFlatShopNo = '',
    String billingArea = '',
    String billingCity = '',
    String billingPincode = '',
    bool isShippingSame = true,
    String shippingFlatShopNo = '',
    String shippingArea = '',
    String shippingCity = '',
    String shippingPincode = '',
    String bankAccount = '',
    String ifscCode = '',
    bool isRegisteredOnApp = false,
    String? linkedBusinessId,
  }) async {
    final partiesRef = _businessCollection('parties');
    if (partiesRef == null) throw Exception("User not logged in");

    await partiesRef.add({
      'name': name,
      'type': type,
      'mobile': mobile,
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
      'balance': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- PUBLIC DIRECTORY SEARCH ---
  Future<List<Map<String, dynamic>>> searchPublicBusiness(String query) async {
    // Search by name or mobile or GSTIN
    final snapshot = await _db
        .collection('public_directory')
        .where('businessName', isGreaterThanOrEqualTo: query)
        .where('businessName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => {...doc.data(), 'businessId': doc.id})
        .toList();
  }

  // Get Parties Stream
  Stream<QuerySnapshot> getPartiesStream({String? type}) {
    final partiesRef = _businessCollection('parties');
    if (partiesRef == null) return const Stream.empty();

    Query query = partiesRef.orderBy('updatedAt', descending: true);
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots();
  }

  // Get Single Party Stream
  Stream<DocumentSnapshot> getPartyStream(String id) {
    final partiesRef = _businessCollection('parties');
    if (partiesRef == null) return const Stream.empty();
    return partiesRef.doc(id).snapshots();
  }

  // Update Party
  Future<void> updateParty(String id, Map<String, dynamic> data) async {
    final partiesRef = _businessCollection('parties');
    if (partiesRef == null) throw Exception("User not logged in");

    data['updatedAt'] = FieldValue.serverTimestamp();
    await partiesRef.doc(id).update(data);
  }

  // Delete Party
  Future<void> deleteParty(String id) async {
    final partiesRef = _businessCollection('parties');
    if (partiesRef == null) throw Exception("User not logged in");

    await partiesRef.doc(id).delete();
  }

  // Add Party Transaction (Payment/Advance)
  Future<void> addPartyTransaction({
    required String partyId,
    required double amount, // Positive = Payment Received (Reduces Balance)
    required String note,
  }) async {
    final partiesRef = _businessCollection('parties');
    if (partiesRef == null) throw Exception("User not logged in");

    final partyDoc = partiesRef.doc(partyId);
    final transactionsRef = partyDoc.collection('transactions');

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(partyDoc);
      if (!snapshot.exists) throw Exception("Party does not exist");

      double currentBalance = (snapshot.data() as Map)['balance'] ?? 0.0;
      String type = (snapshot.data() as Map)['type'] ?? 'customer';

      if (type == 'customer') {
        currentBalance -= amount;
      } else {
        currentBalance += amount;
      }

      transaction.update(partyDoc, {'balance': currentBalance});

      // Record Transaction
      transaction.set(transactionsRef.doc(), {
        'amount': amount,
        'type': 'payment',
        'note': note,
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get Party Transactions Stream
  Stream<QuerySnapshot> getPartyTransactionsStream(String partyId) {
    final partiesRef = _businessCollection('parties');
    if (partiesRef == null) return const Stream.empty();
    return partiesRef
        .doc(partyId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // --- BILLS ---
  Future<void> saveBill(BillModel bill) async {
    if (_businessId == null) return;

    final businessDoc = _db.collection('businesses').doc(_businessId);
    final billRef = businessDoc.collection('bills').doc();

    DocumentReference? partyRef;
    if (bill.partyId.isNotEmpty) {
      partyRef = businessDoc.collection('parties').doc(bill.partyId);
    }

    return _db.runTransaction((transaction) async {
      DocumentSnapshot? partySnapshot;
      if (bill.paymentStatus == 'credit' && partyRef != null) {
        partySnapshot = await transaction.get(partyRef);
      }

      transaction.set(billRef, bill.toMap());

      if (partySnapshot != null && partySnapshot.exists && partyRef != null) {
        double currentBalance = (partySnapshot.data() as Map)['balance'] ?? 0.0;
        double billAmount = bill.totalAmount;

        if (bill.partyType == 'customer') {
          currentBalance += billAmount;
        } else {
          currentBalance -= billAmount;
        }

        transaction.update(partyRef, {'balance': currentBalance});
      }
    });
  }

  Stream<QuerySnapshot> getBillsStream() {
    if (_businessId == null) return const Stream.empty();
    return _db
        .collection('businesses')
        .doc(_businessId)
        .collection('bills')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<List<BillModel>> getBillsFuture() async {
    if (_businessId == null) return [];
    final snap = await _db
        .collection('businesses')
        .doc(_businessId)
        .collection('bills')
        .get();
    return snap.docs.map((doc) => BillModel.fromSnapshot(doc)).toList();
  }

  Stream<QuerySnapshot> getRecentBillsStream() {
    if (_businessId == null) return const Stream.empty();
    return _db
        .collection('businesses')
        .doc(_businessId)
        .collection('bills')
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots();
  }

  Stream<QuerySnapshot> getOverdueBillsStream() {
    if (_businessId == null) return const Stream.empty();
    return _db
        .collection('businesses')
        .doc(_businessId)
        .collection('bills')
        .where('paymentStatus', isEqualTo: 'credit')
        .snapshots();
  }

  // --- EXPENSES ---
  Future<void> addExpense(ExpenseModel expense) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String id = expense.id;
    if (id.isEmpty) {
      id = _businessCollection('expenses')!.doc().id;
    }

    final newExpense = ExpenseModel(
      id: id,
      title: expense.title,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      type: expense.type,
    );

    await _businessCollection('expenses')!.doc(id).set(newExpense.toMap());
  }

  Stream<QuerySnapshot> getExpensesStream() {
    final expensesRef = _businessCollection('expenses');
    if (expensesRef == null) return const Stream.empty();
    return expensesRef.orderBy('date', descending: true).snapshots();
  }

  Future<List<ExpenseModel>> getExpensesFuture() async {
    final expensesRef = _businessCollection('expenses');
    if (expensesRef == null) return [];
    final snap = await expensesRef.get();
    return snap.docs.map((doc) => ExpenseModel.fromSnapshot(doc)).toList();
  }

  Future<void> deleteExpense(String id) async {
    final expensesRef = _businessCollection('expenses');
    if (expensesRef == null) throw Exception("User not logged in");
    await expensesRef.doc(id).delete();
  }
}
