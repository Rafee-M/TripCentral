import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddLocationMapScreen extends StatefulWidget {
  final String tripListId;

  const AddLocationMapScreen({Key? key, required this.tripListId})
      : super(key: key);

  @override
  State<AddLocationMapScreen> createState() => _AddLocationMapScreenState();
}

class _AddLocationMapScreenState extends State<AddLocationMapScreen> {
  GoogleMapController? mapController;
  LatLng? _selectedLocation;
  final TextEditingController _nameController = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location and enter a name')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('trip_locations').insert({
        'trip_list_id': widget.tripListId,
        'name': _nameController.text,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'is_manual': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location added successfully!')),
      );
      Navigator.pop(context);
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter place name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 2.0,
              ),
              onTap: _onTap,
              markers: _selectedLocation == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedLocation!,
                      )
                    },
            ),
          ),
        ],
      ),
    );
  }
}

