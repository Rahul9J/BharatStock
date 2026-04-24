import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../logic/interaction_service.dart';
import '../data/interaction_message.dart';

class InteractionChatScreen extends StatefulWidget {
  final String otherBusinessId;
  final String otherBusinessName;
  final String myBusinessId;
  final String myBusinessName;

  const InteractionChatScreen({
    super.key,
    required this.otherBusinessId,
    required this.otherBusinessName,
    required this.myBusinessId,
    required this.myBusinessName,
  });

  @override
  State<InteractionChatScreen> createState() => _InteractionChatScreenState();
}

class _InteractionChatScreenState extends State<InteractionChatScreen> {
  late final InteractionService _service;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = InteractionService(
      businessId: widget.myBusinessId,
      businessName: widget.myBusinessName,
    );
    _service.clearUnread(widget.otherBusinessId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFF2F4F8);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFFE0B2),
              radius: 18,
              child: Text(
                widget.otherBusinessName.isNotEmpty
                    ? widget.otherBusinessName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherBusinessName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              if (value == 'send_bill') _showSendBillDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'send_bill',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text("Send Bill"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getMessagesStream(widget.otherBusinessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Start your business conversation",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }
                final messages = snapshot.data!.docs
                    .map((doc) => InteractionMessage.fromSnapshot(doc))
                    .toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderBusinessId == widget.myBusinessId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(InteractionMessage msg, bool isMe) {
    if (msg.type == 'bill') return _buildBillCard(msg, isMe);
    if (msg.type == 'payment_ack') return _buildPaymentAckCard(msg, isMe);
    return _buildTextBubble(msg, isMe);
  }

  Widget _buildTextBubble(InteractionMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFFE0B2) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.content,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMsgTime(msg.timestamp),
              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(InteractionMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ClayCard(
          borderRadius: 16,
          depth: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg.content,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (msg.amount != null) ...[
                const SizedBox(height: 10),
                Text(
                  "₹${msg.amount!.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (!isMe && msg.status != 'acted')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _confirmPayment(msg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Acknowledge Payment",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                )
              else if (msg.status == 'acted')
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Received & Synced",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatMsgTime(msg.timestamp),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentAckCard(InteractionMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 6),
                Text(
                  "Payment Acknowledged",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (msg.amount != null) ...[
              const SizedBox(height: 6),
              Text(
                "₹${msg.amount!.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatMsgTime(msg.timestamp),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.orange),
              onPressed: _showSendBillDialog,
            ),
            Expanded(
              child: ClayContainer(
                color: const Color(0xFFF2F4F8),
                borderRadius: 25,
                depth: -5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 14),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendText,
              child: SizedBox(
                height: 45,
                width: 45,
                child: ClayCard(
                  borderRadius: 25,
                  depth: 8,
                  padding: EdgeInsets.zero,
                  child: const Icon(Icons.send, color: Colors.orange, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendText() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _service.sendTextMessage(
      otherBusinessId: widget.otherBusinessId,
      content: text,
    );
  }

  void _confirmPayment(InteractionMessage msg) async {
    if (msg.amount == null) return;
    await _service.acknowledgePayment(
      otherBusinessId: widget.otherBusinessId,
      amount: msg.amount!,
    );
    if (mounted) showTopToast(context, "Payment Acknowledged!");
  }

  void _showSendBillDialog() {
    final amountCtrl = TextEditingController();
    final billNoCtrl = TextEditingController();
    final billIdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Share Invoice"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: billNoCtrl,
              decoration: const InputDecoration(labelText: "Invoice #"),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount (₹)"),
            ),
            TextField(
              controller: billIdCtrl,
              decoration: const InputDecoration(labelText: "Internal Bill ID"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              final bId = billIdCtrl.text.trim();
              if (amt > 0 && bId.isNotEmpty) {
                _service.sendBill(
                  otherBusinessId: widget.otherBusinessId,
                  billId: bId,
                  amount: amt,
                  billNumber: billNoCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  String _formatMsgTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
