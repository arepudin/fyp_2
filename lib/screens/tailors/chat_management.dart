import 'package:flutter/material.dart';
import '../../constants/supabase.dart';
import '../customers/chat.dart';

class TailorChatManagement extends StatefulWidget {
  const TailorChatManagement({super.key});

  @override
  State<TailorChatManagement> createState() => _TailorChatManagementState();
}

class _TailorChatManagementState extends State<TailorChatManagement> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getTailorConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No customer conversations yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _ConversationCard(conversation: conversation);
          },
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getTailorConversations() {
    return supabase
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false);
  }
}

class _ConversationCard extends StatelessWidget {
  final Map<String, dynamic> conversation;

  const _ConversationCard({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final status = conversation['status'] as String;
    final Color statusColor = status == 'active' 
        ? Colors.green 
        : status == 'pending' 
            ? Colors.orange 
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text('Customer Conversation'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            Text(
              'Last activity: ${_formatDate(conversation['last_message_at'])}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: status == 'pending' 
            ? ElevatedButton(
                onPressed: () => _acceptConversation(context),
                child: const Text('Accept'),
              )
            : const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversationId: conversation['id']),
            ),
          );
        },
      ),
    );
  }

  Future<void> _acceptConversation(BuildContext context) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('chat_conversations')
          .update({
            'tailor_id': user.id,
            'status': 'active',
          })
          .eq('id', conversation['id']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else {
      return '${difference.inMinutes} minute(s) ago';
    }
  }
}