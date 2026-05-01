import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart' as places;

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
  final TextEditingController _searchController = TextEditingController();

  late places.FlutterGooglePlacesSdk _placesSdk;
  List<places.AutocompletePrediction> _predictions = [];
  String? _selectedPlaceId;

  @override
  void initState() {
    super.initState();
    _placesSdk = places.FlutterGooglePlacesSdk(dotenv.get('GOOGLE_MAPS_API_KEY'));
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }


    try {
      final result = await _placesSdk.findAutocompletePredictions(query);
      setState(() {
        _predictions = result.predictions;
      });
    } catch (e) {
      setState(() => _predictions = []);
    }
  }

  Future<void> _selectPrediction(places.AutocompletePrediction prediction) async {
    setState(() {
      _predictions = [];
      _searchController.text = prediction.primaryText ?? '';
      _nameController.text = prediction.primaryText ?? '';
      _selectedPlaceId = prediction.placeId;
    });

    FocusScope.of(context).unfocus();

    if (prediction.placeId != null) {
      try {
        final placeResult = await _placesSdk.fetchPlace(
          prediction.placeId!,
          fields: [places.PlaceField.Location, places.PlaceField.DisplayName],
        );
        final place = placeResult.place;
        if (place != null && place.latLng != null) {
          final latLng = LatLng(
            place.latLng!.lat,
            place.latLng!.lng
          );

          setState(() {
            _selectedLocation = latLng;
          });

          mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, 15.0),
          );
        }
      } catch (e) {
        // Handle error implicitly
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _selectedPlaceId = null; // Clear place ID if manually tapped
      _nameController.text = 'Selected Location';
      _searchController.text = '';
    });
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location and enter a name'),
        ),
      );
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('trip_locations').insert({
        'trip_list_id': widget.tripListId,
        'added_by': userId,
        'name': _nameController.text,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'is_manual': _selectedPlaceId == null,
        if (_selectedPlaceId != null) 'place_id': _selectedPlaceId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location added successfully!')),
      );
      Navigator.pop(context);
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Location'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveLocation),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search places...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return ListTile(
                          title: Text(prediction.primaryText ?? ''),
                          subtitle: Text(prediction.secondaryText ?? ''),
                          onTap: () => _selectPrediction(prediction),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Custom name (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
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
                      ),
                    },
            ),
          ),
        ],
      ),
    );
  }
}

