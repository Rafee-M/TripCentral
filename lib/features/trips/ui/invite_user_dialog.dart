import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteUserDialog extends StatefulWidget {
  final String tripListId;

  const InviteUserDialog({super.key, required this.tripListId});

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final res = await _supabase
          .from('profiles')
          .select('id, username, display_name')
          .ilike('display_name', '%$query%')
          .neq('id', _supabase.auth.currentUser!.id)
          .limit(10);
      setState(() {
        _searchResults = res;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _inviteUser(String targetUserId) async {
    try {
      // Check if already invited
      final existing = await _supabase
          .from('trip_list_invitations')
          .select()
          .eq('trip_list_id', widget.tripListId)
          .eq('invited_user_id', targetUserId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existing != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already invited.')));
        return;
      }

      await _supabase.from('trip_list_invitations').insert({
        'trip_list_id': widget.tripListId,
        'invited_by': _supabase.auth.currentUser!.id,
        'invited_user_id': targetUserId,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite sent!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to invite: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite User'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search display name...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchUsers(_searchController.text),
                ),
              ),
              onSubmitted: _searchUsers,
            ),
            const SizedBox(height: 10),
            if (_isSearching) const CircularProgressIndicator(),
            if (!_isSearching && _searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      title: Text(user['display_name'] ?? user['username']),
                      subtitle: Text('@${user['username']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () => _inviteUser(user['id']),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

