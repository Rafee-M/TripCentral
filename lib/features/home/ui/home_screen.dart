import 'package:flutter/material.dart';
import 'package:trip_central/shared/models/trip_list.dart';
import 'package:trip_central/features/trips/services/trip_service.dart';
import 'package:intl/intl.dart';

import '../../trips/ui/create_trip_screen.dart';

enum ViewMode { simpleList, cards, calendar }
enum SortMode { date, name }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TripService _tripService = TripService();

  // Implements State tracking for specific view implementations
  ViewMode _currentViewMode = ViewMode.simpleList;
  SortMode _currentSortMode = SortMode.date;

  List<TripList> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    setState(() => _isLoading = true);
    try {
      final fetchedTrips = await _tripService.getUpcomingTrips();
      // Implementation of Strategy/Builder context: We'll implement different soft-sortings depending on Mode.
      // Currently Supabase sends it sorted by date natively.
      setState(() {
        _trips = fetchedTrips;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load trips: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.flight_takeoff, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () { /* TODO: Implement Search */ },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () { /* TODO: Implement Settings */ },
            tooltip: 'Settings',
          ),
        ],
      ),
      // Elegant minimal UI styling
      body: RefreshIndicator(
        onRefresh: _fetchTrips,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Upcoming Trips',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Dropdowns for view and sort modes natively styled
              Row(
                children: [
                  _buildMinimalDropdown(
                    value: _currentViewMode,
                    items: {
                      ViewMode.simpleList: 'Simple List',
                      ViewMode.cards: 'Cards',
                      ViewMode.calendar: 'Calendar',
                    },
                    icon: Icons.view_agenda_outlined,
                    onChanged: (ViewMode? val) {
                      if (val != null) setState(() => _currentViewMode = val);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildMinimalDropdown(
                    value: _currentSortMode,
                    items: {
                      SortMode.date: 'By Date',
                      SortMode.name: 'By Name',
                    },
                    icon: Icons.sort_rounded,
                    onChanged: (SortMode? val) {
                      if (val != null) setState(() => _currentSortMode = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Implementing Strategy Pattern logic natively via `build` delegations:
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _trips.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildSimpleListView(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: theme.colorScheme.primaryContainer,
        onPressed: () async {
          // Route and wait for result
          final newTrip = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTripScreen()),
          );

          if (newTrip == true) {
            // Trigger UI reload ensuring Home properly maps what Create screen did
            _fetchTrips();
          }
        },
        child: Icon(Icons.add, color: theme.colorScheme.onPrimaryContainer),
        tooltip: 'Create New Trip',
      ),
    );
  }

  // Elegant Empty State
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape, size: 64, color: theme.colorScheme.surfaceContainerHighest),
          const SizedBox(height: 16),
          Text(
            'No trips yet.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to start a new adventure.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Implementation of simple view strategy
  Widget _buildSimpleListView() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _trips.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final trip = _trips[index];
        final dateFormat = DateFormat('MMM d, yyyy');
        final strDate = trip.startDate != null ? dateFormat.format(trip.startDate!) : 'No dates set';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          title: Text(
            trip.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(strDate),
          ),
          trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          onTap: () {
            // TODO: Route to future detailed TripList Screen internally
          },
        );
      },
    );
  }

  // Custom minimalist Dropdown button
  Widget _buildMinimalDropdown<T>({
    required T value,
    required Map<T, String> items,
    required IconData icon,
    required void Function(T?) onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              icon: const SizedBox.shrink(), // Hides default arrow
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              items: items.entries.map((e) {
                return DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
