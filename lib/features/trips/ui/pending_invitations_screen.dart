import 'package:flutter/material.dart';
import 'package:trip_central/features/trips/services/trip_service.dart';

class PendingInvitationsScreen extends StatefulWidget {
  const PendingInvitationsScreen({super.key});

  @override
  State<PendingInvitationsScreen> createState() => _PendingInvitationsScreenState();
}

class _PendingInvitationsScreenState extends State<PendingInvitationsScreen> {
  final TripService _tripService = TripService();
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
      final res = await _tripService.getPendingInvitations(); //Facade

      setState(() {
        _invitations = res;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInvite(String inviteId) async {
    try {
      final success = await _tripService.acceptInvitation(inviteId);
      if (success) {
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
                    final tripTitle = invite['trip_lists']?['title'] ?? 'Unknown Trip';
                    final inviterName = invite['profiles']?['display_name'] ?? invite['profiles']?['username'] ?? 'Someone';

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
