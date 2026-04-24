import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/interaction_message.dart';

class InteractionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _myBusinessId;
  final String _myBusinessName;

  InteractionService({required String businessId, required String businessName})
    : _myBusinessId = businessId,
      _myBusinessName = businessName;

  // --- REFERENCES ---

  DocumentReference _myInteractionDoc(String otherBusinessId) {
    return _db
        .collection('businesses')
        .doc(_myBusinessId)
        .collection('interactions')
        .doc(otherBusinessId);
  }

  DocumentReference _otherInteractionDoc(String otherBusinessId) {
    return _db
        .collection('businesses')
        .doc(otherBusinessId)
        .collection('interactions')
        .doc(_myBusinessId);
  }

  // --- CONVERSATIONS LIST ---

  Stream<QuerySnapshot> getConversationsStream() {
    return _db
        .collection('businesses')
        .doc(_myBusinessId)
        .collection('interactions')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // --- MESSAGES ---

  Stream<QuerySnapshot> getMessagesStream(String otherBusinessId) {
    return _myInteractionDoc(
      otherBusinessId,
    ).collection('messages').orderBy('timestamp', descending: true).snapshots();
  }

  // --- START CONVERSATION ---

  Future<void> startConversation({
    required String otherBusinessId,
    required String otherBusinessName,
  }) async {
    final batch = _db.batch();

    batch.set(_myInteractionDoc(otherBusinessId), {
      'otherBusinessName': otherBusinessName,
      'otherBusinessId': otherBusinessId,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': 0,
    }, SetOptions(merge: true));

    batch.set(_otherInteractionDoc(otherBusinessId), {
      'otherBusinessName': _myBusinessName,
      'otherBusinessId': _myBusinessId,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': 0,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // --- SEND TEXT ---

  Future<void> sendTextMessage({
    required String otherBusinessId,
    required String content,
  }) async {
    final message = InteractionMessage(
      id: '',
      senderBusinessId: _myBusinessId,
      senderName: _myBusinessName,
      content: content,
      type: 'text',
      timestamp: DateTime.now(),
    );

    await _mirrorWrite(
      otherBusinessId: otherBusinessId,
      message: message,
      previewText: content,
    );
  }

  // --- SEND BILL (B2B Sharing) ---

  Future<void> sendBill({
    required String otherBusinessId,
    required String billId,
    required double amount,
    required String billNumber,
  }) async {
    final message = InteractionMessage(
      id: '',
      senderBusinessId: _myBusinessId,
      senderName: _myBusinessName,
      content: 'Invoice #$billNumber — ₹${amount.toStringAsFixed(2)}',
      type: 'bill',
      billId: billId,
      amount: amount,
      timestamp: DateTime.now(),
    );

    await _mirrorWrite(
      otherBusinessId: otherBusinessId,
      message: message,
      previewText: '📄 Invoice #$billNumber',
    );
  }

  // --- PAYMENT ACKNOWLEDGEMENT & SYNC ---

  Future<void> acknowledgePayment({
    required String otherBusinessId,
    required double amount,
  }) async {
    final message = InteractionMessage(
      id: '',
      senderBusinessId: _myBusinessId,
      senderName: _myBusinessName,
      content: 'Payment confirmed: ₹${amount.toStringAsFixed(2)}',
      type: 'payment_ack',
      amount: amount,
      timestamp: DateTime.now(),
    );

    await _mirrorWrite(
      otherBusinessId: otherBusinessId,
      message: message,
      previewText: '✅ Payment: ₹${amount.toStringAsFixed(2)}',
    );

    // Update balances on both sides automatically
    await _syncLedgerBalance(otherBusinessId, amount);
  }

  // --- INTERNAL: MIRROR WRITE ---

  Future<void> _mirrorWrite({
    required String otherBusinessId,
    required InteractionMessage message,
    required String previewText,
  }) async {
    final batch = _db.batch();
    final messageData = message.toMap();

    final myMsgRef = _myInteractionDoc(
      otherBusinessId,
    ).collection('messages').doc();
    batch.set(myMsgRef, messageData);

    final theirMsgRef = _otherInteractionDoc(
      otherBusinessId,
    ).collection('messages').doc();
    batch.set(theirMsgRef, messageData);

    batch.update(_myInteractionDoc(otherBusinessId), {
      'lastMessage': previewText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    batch.update(_otherInteractionDoc(otherBusinessId), {
      'lastMessage': previewText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // --- INTERNAL: LEDGER SYNC ---

  Future<void> _syncLedgerBalance(String otherBusinessId, double amount) async {
    // 1. My side: find the party linked to otherBusinessId
    final myParties = await _db
        .collection('businesses')
        .doc(_myBusinessId)
        .collection('parties')
        .where('linkedBusinessId', isEqualTo: otherBusinessId)
        .limit(1)
        .get();

    if (myParties.docs.isNotEmpty) {
      final doc = myParties.docs.first;
      final type = doc.data()['type'] ?? 'customer';
      double change = type == 'customer' ? -amount : amount;
      await doc.reference.update({'balance': FieldValue.increment(change)});
    }

    // 2. Their side: find the party linked to myBusinessId
    final theirParties = await _db
        .collection('businesses')
        .doc(otherBusinessId)
        .collection('parties')
        .where('linkedBusinessId', isEqualTo: _myBusinessId)
        .limit(1)
        .get();

    if (theirParties.docs.isNotEmpty) {
      final doc = theirParties.docs.first;
      final type = doc.data()['type'] ?? 'supplier';
      double change = type == 'supplier' ? amount : -amount;
      await doc.reference.update({'balance': FieldValue.increment(change)});
    }
  }

  Future<void> clearUnread(String otherBusinessId) async {
    await _myInteractionDoc(otherBusinessId).update({'unreadCount': 0});
  }
}
