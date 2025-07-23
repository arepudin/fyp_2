import 'dart:io';

import '../constants/supabase.dart';

class ChatService {
  static Future<String> startConversation() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if there's already an active conversation
      final existingConversation = await supabase
          .from('chat_conversations')
          .select('id')
          .eq('customer_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (existingConversation != null) {
        return existingConversation['id'];
      }

      // Create new conversation
      final response = await supabase
          .from('chat_conversations')
          .insert({
            'customer_id': user.id,
            'status': 'pending', // Will be 'active' when tailor joins
          })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to start conversation: $e');
    }
  }

  static Future<void> sendMessage({
    required String conversationId,
    required String messageText,
    String? fileUrl,
    String? fileName,
    String messageType = 'text',
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'message_text': messageText,
        'message_type': messageType,
        'file_url': fileUrl,
        'file_name': fileName,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  static Stream<List<Map<String, dynamic>>> getConversations() {
    final user = supabase.auth.currentUser;
    if (user == null) return Stream.empty();

    return supabase
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false);
  }

  static Future<String?> uploadFile(String filePath, String fileName) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileExt = fileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'chat_files/${user.id}/$timestamp.$fileExt';

      await supabase.storage
          .from('chat-files')
          .upload(storagePath, filePath as File);

      final publicUrl = supabase.storage
          .from('chat-files')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', user.id);
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }
}