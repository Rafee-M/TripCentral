import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingInvitationsScreen extends StatefulWidget {
  const PendingInvitationsScreen({super.key});

  @override
  State<PendingInvitationsScreen> createState() => _PendingInvitationsScreenState();
}

class _PendingInvitationsScreenState extends State<PendingInvitationsScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _invitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInvitations();
  }

  Future<void> _fetchInvitations() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('trip_list_invitations')
          .select('id, status, trip_list_id, trip:trip_lists(title), inviter:profiles!invited_by(display_name, username)')
          .eq('invited_user_id', _supabase.auth.currentUser!.id)
          .eq('status', 'pending');

      setState(() {
        _invitations = res;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInvite(String inviteId) async {
    try {
      final res = await _supabase.rpc('accept_invitation', params: {'p_invitation_id': inviteId});
      if (res != null && res['success'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation accepted!')));
        _fetchInvitations();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to accept.')));
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
      appBar: AppBar(title: const Text('Pending Invitations')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invitations.isEmpty
              ? const Center(child: Text('No pending invitations.'))
              : ListView.builder(
                  itemCount: _invitations.length,
                  itemBuilder: (context, index) {
                    final invite = _invitations[index];
                    final tripTitle = invite['trip']?['title'] ?? 'Unknown Trip';
                    final inviterName = invite['inviter']?['display_name'] ?? invite['inviter']?['username'] ?? 'Someone';

                    return ListTile(
                      leading: const Icon(Icons.mail),
                      title: Text('Trip: $tripTitle'),
                      subtitle: Text('Invited by $inviterName'),
                      trailing: ElevatedButton(
                        onPressed: () => _acceptInvite(invite['id']),
                        child: const Text('Accept'),
                      ),
                    );
                  },
                ),
    );
  }
}

