import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trip_central/features/trips/ui/add_location_map_screen.dart';
import 'package:trip_central/features/trips/ui/location_detail_screen.dart';
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
  List<dynamic> _notes = [];
  bool _isLoading = true;

  // Box Expansion States
  bool _isLocationsExpanded = true;
  bool _isNotesExpanded = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final locResponse = await Supabase.instance.client
          .from('trip_locations')
          .select()
          .eq('trip_list_id', widget.tripList['id'])
          .order('order_index', ascending: true);

      final notesResponse = await Supabase.instance.client
          .from('trip_notes')
          .select()
          .eq('trip_list_id', widget.tripList['id'])
          .order('created_at', ascending: true);

      setState(() {
        _locations = locResponse as List<dynamic>;
        _notes = notesResponse as List<dynamic>;
      });
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLocation(String locationId) async {
    try {
      await Supabase.instance.client
          .from('trip_locations')
          .delete()
          .eq('id', locationId);
      _fetchData();
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

  Future<void> _showLocationDetails(Map<String, dynamic> loc) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationDetailScreen(location: loc),
      ),
    );
    if (result == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic layout Flex allocation logic
    int locFlex = _isLocationsExpanded ? 1 : 0;
    int notesFlex = _isNotesExpanded ? 1 : 0;

    // Safefall to prevent screen crush
    if (!(_isLocationsExpanded || _isNotesExpanded)) {
       locFlex = 1;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildCollapsibleBox(
                    title: 'Locations',
                    isExpanded: _isLocationsExpanded,
                    flex: locFlex,
                    onToggle: () => setState(() => _isLocationsExpanded = !_isLocationsExpanded),
                    theme: theme,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _locations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final loc = _locations[index];
                        return ListTile(
                          leading: Icon(Icons.place, color: theme.colorScheme.primary),
                          title: Text(loc['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(loc['address'] ?? 'Lat: ${loc['latitude']}, Lng: ${loc['longitude']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _showLocationDetails(loc),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteLocation(loc['id']),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCollapsibleBox(
                    title: 'Notes',
                    isExpanded: _isNotesExpanded,
                    flex: notesFlex,
                    onToggle: () => setState(() => _isNotesExpanded = !_isNotesExpanded),
                    theme: theme,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _notes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return ListTile(
                          leading: Icon(Icons.note, color: theme.colorScheme.tertiary),
                          title: Text(note['title'] ?? 'Untitled'),
                          onTap: () { /* Future Note Details Screen */ },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddLocationMapScreen(tripListId: widget.tripList['id']),
            ),
          );
          _fetchData(); // Refresh after adding
        },
        label: const Text('Add Location'),
        icon: const Icon(Icons.add_location_alt),
      ),
    );
  }

  Widget _buildCollapsibleBox({
    required String title,
    required bool isExpanded,
    required int flex,
    required VoidCallback onToggle,
    required ThemeData theme,
    required Widget child,
  }) {
    final header = InkWell(
      onTap: onToggle,
      borderRadius: isExpanded ? const BorderRadius.vertical(top: Radius.circular(16)) : BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );

    final boxDecoration = BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: Border.all(color: theme.colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(16),
    );

    if (!isExpanded) {
      return Container(
        decoration: boxDecoration,
        child: header,
      );
    }

    return Expanded(
      flex: flex,
      child: Container(
        decoration: boxDecoration,
        child: Column(
          children: [
            header,
            const Divider(height: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
