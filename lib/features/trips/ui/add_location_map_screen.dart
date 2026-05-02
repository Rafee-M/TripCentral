import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart' as places;

/// ADAPTER PATTERN: Unifies the difference between Google Place API data
/// and manual form input into a single database-ready payload.
class LocationPayloadAdapter {
  static Map<String, dynamic> fromGooglePlace({
    required String tripListId,
    required String userId,
    required places.Place place,
    int orderIndex = 0,
  }) {
    return {
      'trip_list_id': tripListId,
      'added_by': userId,
      'is_manual': false,
      'name': place.name ?? place.displayName?.text,
      'address': place.address ?? place.shortFormattedAddress,
      'latitude': place.latLng?.lat,
      'longitude': place.latLng?.lng,
      'place_id': place.id,
      'place_type': place.primaryType,
      'phone_number': place.phoneNumber ?? place.nationalPhoneNumber ?? place.internationalPhoneNumber,
      'website_url': place.websiteUri?.toString(),
      'order_index': orderIndex,
      'metadata': {
        'rating': place.rating,
        'priceLevel': place.priceLevel?.name,
        'openingHours': place.currentOpeningHours?.weekdayText ?? place.openingHours?.weekdayText,
        'photoReferences': place.photoMetadatas?.map((photo) => {
          'photoReference': photo.photoReference,
          'width': photo.width,
          'height': photo.height,
        }).toList() ?? [],
      },
    };
  }

  static Map<String, dynamic> fromManual({
    required String tripListId,
    required String userId,
    required String name,
    required String address,
    required String description,
    required String phone,
    required String website,
    double? lat,
    double? lng,
    int orderIndex = 0,
  }) {
    return {
      'trip_list_id': tripListId,
      'added_by': userId,
      'is_manual': true,
      'name': name,
      'address': address,
      'description': description,
      'phone_number': phone,
      'website_url': website,
      'latitude': lat,
      'longitude': lng,
      'order_index': orderIndex,
      'metadata': {},
    };
  }
}

enum LocationInputMode { maps, manual }

class AddLocationMapScreen extends StatefulWidget {
  final String tripListId;

  const AddLocationMapScreen({Key? key, required this.tripListId})
    : super(key: key);

  @override
  State<AddLocationMapScreen> createState() => _AddLocationMapScreenState();
}

class _AddLocationMapScreenState extends State<AddLocationMapScreen> {
  LocationInputMode _inputMode = LocationInputMode.maps;

  // Google Maps State
  GoogleMapController? mapController;
  LatLng? _selectedLocation;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late places.FlutterGooglePlacesSdk _placesSdk;
  List<places.AutocompletePrediction> _predictions = [];
  String? _selectedPlaceId;
  places.Place? _selectedPlace; // Hold full Google Place details object

  // Manual Form State
  final _manualAddressController = TextEditingController();
  final _manualDescController = TextEditingController();
  final _manualPhoneController = TextEditingController();
  final _manualWebsiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _placesSdk = places.FlutterGooglePlacesSdk(dotenv.get('GOOGLE_MAPS_API_KEY') ?? '');
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
          fields: [
            places.PlaceField.Id,
            places.PlaceField.DisplayName,
            places.PlaceField.FormattedAddress,
            places.PlaceField.Location,
            places.PlaceField.NationalPhoneNumber,
            places.PlaceField.WebsiteUri,
            places.PlaceField.Rating,
            places.PlaceField.PriceLevel,
            places.PlaceField.PrimaryType,
            places.PlaceField.Photos,
            places.PlaceField.CurrentOpeningHours,
          ],
        );
        final place = placeResult.place;
        if (place != null && place.latLng != null) {
          final latLng = LatLng(
            place.latLng!.lat,
            place.latLng!.lng
          );

          setState(() {
            _selectedLocation = latLng;
            _selectedPlace = place;
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
      _selectedPlace = null;
      _nameController.text = 'Selected Location';
      _searchController.text = '';
    });
  }

  Future<void> _saveLocation() async {
    if (_inputMode == LocationInputMode.maps && _selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid place from the map/search')),
      );
      return;
    }

    if (_inputMode == LocationInputMode.manual && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location Name is required')),
      );
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      Map<String, dynamic> payload;

      if (_inputMode == LocationInputMode.maps) {
        // Utilize the Adapter
        payload = LocationPayloadAdapter.fromGooglePlace(
          tripListId: widget.tripListId,
          userId: userId,
          place: _selectedPlace!,
        );
      } else {
        // Utilize the Adapter for manual
        payload = LocationPayloadAdapter.fromManual(
          tripListId: widget.tripListId,
          userId: userId,
          name: _nameController.text.trim(),
          address: _manualAddressController.text.trim(),
          description: _manualDescController.text.trim(),
          phone: _manualPhoneController.text.trim(),
          website: _manualWebsiteController.text.trim(),
          lat: _selectedLocation?.latitude,
          lng: _selectedLocation?.longitude,
        );
      }

      await Supabase.instance.client.from('trip_locations').insert(payload);

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Location'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _inputMode = _inputMode == LocationInputMode.maps
                      ? LocationInputMode.manual
                      : LocationInputMode.maps;
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _inputMode == LocationInputMode.maps ? 'Maps' : 'Manual',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.check), onPressed: _saveLocation),
        ],
      ),
      body: _inputMode == LocationInputMode.maps ? _buildMapsMode() : _buildManualMode(theme),
    );
  }

  Widget _buildMapsMode() {
    return Column(
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
                  filled: true,
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
            ],
          ),
        ),
        if (_selectedPlace != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(_selectedPlace!.name ?? _selectedPlace!.displayName?.text ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
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
    );
  }

  Widget _buildManualMode(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Location Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manualDescController,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manualAddressController,
            decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualPhoneController,
                  decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _manualWebsiteController,
                  decoration: const InputDecoration(labelText: 'Website / URL', border: OutlineInputBorder()),
                  keyboardType: TextInputType.url,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
