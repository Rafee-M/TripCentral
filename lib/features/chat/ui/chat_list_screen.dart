import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trip_central/features/chat/ui/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('chat_room_members')
          .select('chat_rooms(*)')
          .eq('user_id', _supabase.auth.currentUser!.id);

      final mappedRooms = response.map((e) => e['chat_rooms']).where((e) => e != null).toList();

      setState(() {
        _chatRooms = mappedRooms;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chats: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? const Center(child: Text('No active chat rooms found.'))
              : ListView.builder(
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = _chatRooms[index];
                    final title = room['name'] ?? 'Chat Group';
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.chat)),
                      title: Text(title),
                      subtitle: const Text('Tap to open chat...'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              roomId: room['id'],
                              tripListId: room['id'], // using room id as placeholder if it is generic
                              title: title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

