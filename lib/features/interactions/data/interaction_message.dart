import 'package:cloud_firestore/cloud_firestore.dart';

class InteractionMessage {
  final String id;
  final String senderBusinessId;
  final String senderName;
  final String content;
  final String type; // 'text', 'bill', 'payment_req', 'payment_ack'
  final String? billId;
  final double? amount;
  final String status; // 'sent', 'delivered', 'acted'
  final DateTime timestamp;

  InteractionMessage({
    required this.id,
    required this.senderBusinessId,
    required this.senderName,
    required this.content,
    required this.type,
    this.billId,
    this.amount,
    this.status = 'sent',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderBusinessId': senderBusinessId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'billId': billId,
      'amount': amount,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory InteractionMessage.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InteractionMessage(
      id: doc.id,
      senderBusinessId: data['senderBusinessId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      billId: data['billId'],
      amount: (data['amount'] as num?)?.toDouble(),
      status: data['status'] ?? 'sent',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
