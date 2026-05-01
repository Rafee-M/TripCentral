import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trip_central/features/trips/ui/add_location_map_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripList['title'] ?? 'Trip Details'),
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

