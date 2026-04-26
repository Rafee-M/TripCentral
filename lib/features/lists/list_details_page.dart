import 'package:flutter/material.dart';
import '../../core/patterns/singleton/supabase_service.dart';

class ListDetailsPage extends StatefulWidget {
  final String listId;
  final String listName;

  const ListDetailsPage({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ListDetailsPage> createState() => _ListDetailsPageState();
}

class _ListDetailsPageState extends State<ListDetailsPage> {
  final TextEditingController _locationController = TextEditingController();
  List<dynamic> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await SupabaseService.instance.client
          .from('trip_locations')
          .select()
          .eq('list_id', widget.listId)
          .order('created_at', ascending: true);

      setState(() {
        _locations = response as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }
  }

  Future<void> _addLocation() async {
    final locationName = _locationController.text.trim();
    if (locationName.isEmpty) return;

    _locationController.clear();
    try {
      final response = await SupabaseService.instance.client
          .from('trip_locations')
          .insert({
            'list_id': widget.listId,
            'location_name': locationName,
          })
          .select()
          .single();

      setState(() {
        _locations.add(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding location: $e')),
        );
      }
    }
  }

  Future<void> _deleteLocation(String locationId, int index) async {
    try {
      await SupabaseService.instance.client
          .from('trip_locations')
          .delete()
          .eq('id', locationId);

      setState(() {
        _locations.removeAt(index);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Enter location name...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addLocation(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addLocation,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _locations.isEmpty
                    ? const Center(child: Text('No locations added yet.'))
                    : ListView.builder(
                        itemCount: _locations.length,
                        itemBuilder: (context, index) {
                          final location = _locations[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(location['location_name']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteLocation(
                                  location['id'].toString(), index),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}
