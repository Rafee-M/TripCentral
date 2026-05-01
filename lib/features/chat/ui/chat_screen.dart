import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String tripListId;
  final String title;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.tripListId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  late RealtimeChannel _channel;
  List<dynamic> _messages = [];
  final _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeToRoom();
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await _supabase
          .from('chat_messages')
          .select('*, profiles:user_id(username)')
          .eq('chat_room_id', widget.roomId)
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        _messages = res;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _subscribeToRoom() {
    _channel = _supabase
        .channel('room:${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_room_id',
            value: widget.roomId,
          ),
          callback: (payload) {
            _fetchMessages(); // Simple refresh for now instead of complex merge
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_channel);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      await _supabase.from('chat_messages').insert({
        'chat_room_id': widget.roomId,
        'user_id': _supabase.auth.currentUser!.id,
        'content': text,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true, // New messages at bottom
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['user_id'] == _supabase.auth.currentUser?.id;
                      final username = msg['profiles']?['username'] ?? 'User';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(msg['content'] ?? ''),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
