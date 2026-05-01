import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trip_central/features/trips/ui/add_location_map_screen.dart';
import 'package:trip_central/features/chat/ui/chat_screen.dart';
import 'package:trip_central/features/trips/ui/invite_user_dialog.dart';

class TripListDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tripList;

  const TripListDetailScreen({Key? key, required this.tripList}) : super(key: key);

  @override
  State<TripListDetailScreen> createState() => _TripListDetailScreenState();
}

class _TripListDetailScreenState extends State<TripListDetailScreen> {
  List<dynamic> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('trip_locations')
          .select()
          .eq('trip_list_id', widget.tripList['id'])
          .order('created_at', ascending: true);

      setState(() {
        _locations = response as List<dynamic>;
      });
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLocation(String locationId) async {
    try {
      await Supabase.instance.client
          .from('trip_locations')
          .delete()
          .eq('id', locationId);
      _fetchLocations();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete')));
    }
  }

  Future<void> _openChat() async {
    final tripListId = widget.tripList['id'];
    try {
      // 1. Check if there are any collaborators for this trip
      final collabRes = await Supabase.instance.client
          .from('trip_list_collaborators')
          .select('user_id')
          .eq('trip_list_id', tripListId);

      if (collabRes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No collaborators. Please invite users using the + icon first.')));
        return;
      }

      // 2. Check if a chat room already exists
      final res = await Supabase.instance.client
          .from('chat_rooms')
          .select()
          .eq('name', widget.tripList['title']) // Using title to link name
          .maybeSingle();

      String roomId;

      if (res == null) {
        // 3. Create the chat room if it doesn't exist
        final newRoom = await Supabase.instance.client
            .from('chat_rooms')
            .insert({
              'name': widget.tripList['title'],
              'description': tripListId, // Keeping reference
              'created_by': Supabase.instance.client.auth.currentUser!.id
            })
            .select()
            .single();

        roomId = newRoom['id'];

        // Add the creator
        final membersToInsert = <Map<String, dynamic>>[
          {
            'chat_room_id': roomId,
            'user_id': Supabase.instance.client.auth.currentUser!.id,
          }
        ];

        // Add all collaborators
        for (final c in collabRes) {
          if (c['user_id'] != Supabase.instance.client.auth.currentUser!.id) {
            membersToInsert.add({
              'chat_room_id': roomId,
              'user_id': c['user_id'],
            });
          }
        }

        await Supabase.instance.client.from('chat_room_members').insert(membersToInsert);

      } else {
        roomId = res['id'];
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
          roomId: roomId,
          tripListId: tripListId,
          title: '${widget.tripList['title']} Chat',
        )));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripList['title'] ?? 'Trip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite Users',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => InviteUserDialog(tripListId: widget.tripList['id']),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Open Chat',
            onPressed: _openChat,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? const Center(child: Text("No locations added yet."))
              : ListView.builder(
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final loc = _locations[index];
                    return ListTile(
                      title: Text(loc['name'] ?? 'Unknown'),
                      subtitle: Text('Lat: ${loc['latitude']}, Lng: ${loc['longitude']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLocation(loc['id']),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddLocationMapScreen(tripListId: widget.tripList['id']),
            ),
          );
          _fetchLocations(); // Refresh after adding
        },
        label: const Text('Add Location'),
        icon: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
