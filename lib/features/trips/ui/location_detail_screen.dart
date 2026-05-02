import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trip_central/features/trips/ui/edit_manual_location_screen.dart';

class LocationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> location;

  const LocationDetailScreen({Key? key, required this.location}) : super(key: key);

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  late Map<String, dynamic> _location;

  @override
  void initState() {
    super.initState();
    _location = Map<String, dynamic>.from(widget.location);
  }

  Future<void> _launchMaps() async {
    final url = _location['google_maps_url'] as String?;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (_location['latitude'] != null && _location['longitude'] != null) {
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${_location['latitude']},${_location['longitude']}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _location['metadata'] as Map<String, dynamic>? ?? {};

    // Parse Google Places photos if available
    final photoRefs = meta['photoReferences'] as List<dynamic>?;
    String? firstPhotoRef;
    if (photoRefs != null && photoRefs.isNotEmpty) {
      firstPhotoRef = photoRefs.first['photoReference'];
    }

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final String? photoUrl = firstPhotoRef != null
        ? 'https://places.googleapis.com/v1/places/${_location['place_id']}/photos/${firstPhotoRef}/media?key=$apiKey&maxHeightPx=400&maxWidthPx=400'
        : null;

    final isManual = _location['is_manual'] == true;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_location['name'] ?? 'Location Details'),
        actions: [
          if (isManual)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditManualLocationScreen(location: _location),
                  ),
                );
                if (result == true) {
                  // After editing, we notify parent to fetch by popping with true,
                  // or just let the user go back manually and parent should fetch.
                  // For now, let's pop this screen as well so parent can refresh.
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
              tooltip: 'Edit Manual Location',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Elegant Image Header
            if (photoUrl != null)
              Image.network(
                photoUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackHeader(theme),
              )
            else
              _buildFallbackHeader(theme),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Place Type
                  Text(
                    _location['name'] ?? 'Unknown Name',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (_location['place_type'] != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (_location['place_type'] as String).replaceAll('_', ' ').toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Rating Block (Minimalist)
                  if (meta['rating'] != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${meta['rating']}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (meta['priceLevel'] != null) ...[
                          const SizedBox(width: 8),
                          Text('•  ${meta['priceLevel']}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ]
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Details Block
                  _buildInfoRow(context, Icons.location_on, _location['address']),
                  if (_location['description'] != null && _location['description'].toString().isNotEmpty)
                    _buildInfoRow(context, Icons.description, _location['description']),
                  _buildInfoRow(context, Icons.phone, _location['phone_number']),
                  _buildInfoRow(context, Icons.public, _location['website_url']),

                  // Opening Hours Iteration
                  if (meta['openingHours'] != null && meta['openingHours'] is List) ...[
                    const SizedBox(height: 24),
                    Text('Hours', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (meta['openingHours'] as List).map((hour) {
                           return Padding(
                             padding: const EdgeInsets.only(bottom: 4.0),
                             child: Text(hour.toString(), style: theme.textTheme.bodySmall),
                           );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Primary Deep Link Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _launchMaps,
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Maps'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 150,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.landscape, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, dynamic text) {
    if (text == null || text.toString().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

