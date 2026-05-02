import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trip_central/features/trips/ui/invite_user_dialog.dart';

class TripCollaboratorsScreen extends StatefulWidget {
  final String tripListId;

  const TripCollaboratorsScreen({super.key, required this.tripListId});

  @override
  State<TripCollaboratorsScreen> createState() => _TripCollaboratorsScreenState();
}

class _TripCollaboratorsScreenState extends State<TripCollaboratorsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _collaborators = [];

  @override
  void initState() {
    super.initState();
    _fetchCollaborators();
  }

  Future<void> _fetchCollaborators() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('trip_list_collaborators')
          .select('*, profiles:profiles!trip_list_collaborators_user_id_fkey(username, display_name, avatar_url)')
          .eq('trip_list_id', widget.tripListId);
      if (mounted) {
        setState(() {
          _collaborators = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborators'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite User',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => InviteUserDialog(tripListId: widget.tripListId),
              );
              _fetchCollaborators();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collaborators.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No collaborators for this trip yet.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (_) => InviteUserDialog(tripListId: widget.tripListId),
                          );
                          _fetchCollaborators();
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Collaborator'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _collaborators.length,
                  itemBuilder: (context, index) {
                    final collab = _collaborators[index];
                    final profile = collab['profiles'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile?['avatar_url'] != null
                            ? NetworkImage(profile['avatar_url'])
                            : null,
                        child: profile?['avatar_url'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(profile?['display_name'] ?? profile?['username'] ?? 'Unknown User'),
                      subtitle: Text('Role: ${collab['permission']}'),
                    );
                  },
                ),
    );
  }
}

