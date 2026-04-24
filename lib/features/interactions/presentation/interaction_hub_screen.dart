import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../../auth/logic/user_service.dart';
import '../logic/interaction_service.dart';
import 'interaction_chat_screen.dart';

class InteractionHubScreen extends StatefulWidget {
  const InteractionHubScreen({super.key});

  @override
  State<InteractionHubScreen> createState() => _InteractionHubScreenState();
}

class _InteractionHubScreenState extends State<InteractionHubScreen> {
  InteractionService? _service;
  bool _loading = true;
  String _myBusinessId = '';
  String _myBusinessName = '';
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final user = await _userService.getCurrentUser();
    if (user != null && user.businessId.isNotEmpty) {
      _myBusinessId = user.businessId;
      _myBusinessName = user.legalBusinessName;
      _service = InteractionService(
        businessId: _myBusinessId,
        businessName: _myBusinessName,
      );
    } else {
      _service = null; // Ensure service is null if ID is missing
    }
    if (mounted) setState(() => _loading = false);
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
        title: const Text(
          "Business Hub",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF9800),
        onPressed: _showSearchDialog,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _service == null
          ? _buildIncompleteProfileState()
          : StreamBuilder<QuerySnapshot>(
              stream: _service!.getConversationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final conversations = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final data =
                        conversations[index].data() as Map<String, dynamic>;
                    final otherId = conversations[index].id;

                    return _buildConversationCard(
                      otherBusinessId: otherId,
                      otherBusinessName: data['otherBusinessName'] ?? 'Unknown',
                      lastMessage: data['lastMessage'] ?? '',
                      lastMessageTime: data['lastMessageTime'] as Timestamp?,
                      unreadCount: data['unreadCount'] ?? 0,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildIncompleteProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              "Business Profile Incomplete",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Please complete your business profile setup to use the Business Hub and connect with others.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/complete_profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Complete Profile"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_center, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            "No connections yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Connect with other businesses by searching.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard({
    required String otherBusinessId,
    required String otherBusinessName,
    required String lastMessage,
    Timestamp? lastMessageTime,
    int unreadCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        _service?.clearUnread(otherBusinessId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InteractionChatScreen(
              otherBusinessId: otherBusinessId,
              otherBusinessName: otherBusinessName,
              myBusinessId: _myBusinessId,
              myBusinessName: _myBusinessName,
            ),
          ),
        );
      },
      child: ClayCard(
        borderRadius: 18,
        depth: 12,
        child: Row(
          children: [
            SizedBox(
              height: 50,
              width: 50,
              child: ClayCard(
                borderRadius: 15,
                depth: 8,
                padding: EdgeInsets.zero,
                child: Center(
                  child: Text(
                    otherBusinessName.isNotEmpty
                        ? otherBusinessName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherBusinessName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.isNotEmpty ? lastMessage : 'Start chatting...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: unreadCount > 0
                          ? Colors.black87
                          : Colors.grey[600],
                      fontWeight: unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(lastMessageTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: unreadCount > 0 ? Colors.orange : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${date.day}/${date.month}';
  }

  void _showSearchDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Search Business"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter GSTIN or Business ID",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final query = controller.text.trim();
              if (query.isEmpty) return;
              Navigator.pop(ctx);
              await _searchAndConnect(query);
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAndConnect(String query) async {
    final doc = await FirebaseFirestore.instance
        .collection('public_directory')
        .doc(query)
        .get();
    if (!doc.exists || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Business not found")));
      }
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final otherId = data['businessId'] ?? '';
    final otherName = data['businessName'] ?? 'Unknown';

    if (otherId == _myBusinessId) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("That's you!")));
      }
      return;
    }

    await _service?.startConversation(
      otherBusinessId: otherId,
      otherBusinessName: otherName,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractionChatScreen(
            otherBusinessId: otherId,
            otherBusinessName: otherName,
            myBusinessId: _myBusinessId,
            myBusinessName: _myBusinessName,
          ),
        ),
      );
    }
  }
}
