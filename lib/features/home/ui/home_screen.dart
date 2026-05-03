import 'package:flutter/material.dart';
import 'package:trip_central/shared/models/trip_list.dart';
import 'package:trip_central/features/trips/services/trip_service.dart';
import 'package:trip_central/features/trips/ui/trip_list_detail_screen.dart';
import 'package:trip_central/features/trips/ui/trip_discovery_screen.dart';
import 'package:intl/intl.dart';

import '../../trips/ui/create_trip_screen.dart';

// --- Strategy Pattern for Sorting ---
// Abstract strategy interface defining the contract for executing a sort
abstract class TripSortStrategy {
  void sort(List<TripList> trips);
}

// Concrete Strategy: Sorting alphabetically by Name
class NameSortStrategy implements TripSortStrategy {
  @override
  void sort(List<TripList> trips) {
    trips.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }
}

// Concrete Strategy: Sorting by Date (nearest upcoming first, nulls at end sorted by name)
class DateSortStrategy implements TripSortStrategy {
  @override
  void sort(List<TripList> trips) {
    trips.sort((a, b) {
      if (a.startDate == null && b.startDate == null) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else if (a.startDate == null) {
        return 1; // Push trips with no date to the bottom
      } else if (b.startDate == null) {
        return -1;
      } else {
        final dateCompare = a.startDate!.compareTo(b.startDate!);
        if (dateCompare == 0) {
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
        return dateCompare;
      }
    });
  }
}
// ------------------------------------

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
      _applySort(); // Apply the default or selected strategy immediately after fetching
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load trips: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  // Applies the current sorting strategy to the state via Strategy Pattern
  void _applySort() {
    TripSortStrategy strategy;
    switch (_currentSortMode) {
      case SortMode.name:
        strategy = NameSortStrategy();
        break;
      case SortMode.date:
        strategy = DateSortStrategy();
        break;
    }

    setState(() {
      strategy.sort(_trips);
    });
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
            child: Icon(
              Icons.flight_takeoff,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TripDiscoveryScreen()),
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              /* TODO: Implement Settings */
            },
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
                  if (_currentViewMode != ViewMode.calendar) ...[
                    const SizedBox(width: 16),
                    _buildMinimalDropdown(
                      value: _currentSortMode,
                      items: {
                        SortMode.date: 'By Date',
                        SortMode.name: 'By Name',
                      },
                      icon: Icons.sort_rounded,
                      onChanged: (SortMode? val) {
                        if (val != null) {
                          setState(() => _currentSortMode = val);
                          _applySort(); // Trigger strategy re-evaluation on change
                        }
                      },
                    ),
                  ],
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
        tooltip: 'Create New Trip',
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
      ),
    );
  }

  // Elegant Empty State
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape,
            size: 64,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
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

  // Strategy Pattern Delegate
  Widget _buildCurrentView() {
    switch (_currentViewMode) {
      case ViewMode.calendar:
        return _buildCalendarView();
      case ViewMode.cards:
        // TODO: cards view, fallback to simple list for now
        return _buildSimpleListView();
      case ViewMode.simpleList:
        return _buildSimpleListView();
    }
  }

  // Custom minimal logic for elegant Calendar view
  Widget _buildCalendarView() {
    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDate.year, _focusedDate.month);
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    // get short weekday (1 = Monday, 7 = Sunday)
    final firstDayOffset = firstDayOfMonth.weekday % 7;

    // Create map of days to trips mapping for fast lookups
    final Map<int, List<TripList>> dailyTrips = {};
    for (var trip in _trips) {
      if (trip.startDate != null &&
          trip.startDate!.year == _focusedDate.year &&
          trip.startDate!.month == _focusedDate.month) {

        // Populate days between start and end date, or just start date
        int startDay = trip.startDate!.day;
        int endDay = trip.endDate != null && trip.endDate!.month == _focusedDate.month ? trip.endDate!.day : startDay;

        for (int i = startDay; i <= endDay; i++) {
          dailyTrips.putIfAbsent(i, () => []).add(trip);
        }
      }
    }

    final monthName = DateFormat('MMMM').format(firstDayOfMonth);

    return Column(
      children: [
        // Month / Year Selector Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _focusedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  setState(() => _focusedDate = picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '$monthName ${_focusedDate.year}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Weekdays Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Calendar Grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 days in a week
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink(); // Empty offset blocks
              }

              int day = index - firstDayOffset + 1;
              final dayTrips = dailyTrips[day] ?? [];
              final isToday = day == DateTime.now().day &&
                              _focusedDate.year == DateTime.now().year &&
                              _focusedDate.month == DateTime.now().month;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (dayTrips.isEmpty) return;
                  if (dayTrips.length == 1) {
                    // Navigate directly to exact list
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripListDetailScreen(
                          tripList: {
                            'id': dayTrips.first.id,
                            'title': dayTrips.first.title,
                          },
                        ),
                      ),
                    );
                  } else {
                    // Show a bottom sheet or a temporary List Screen
                    _showDayTripsModal(context, dayTrips, day);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday ? Border.all(color: theme.colorScheme.primary) : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? theme.colorScheme.primary : null,
                        ),
                      ),
                      // Dot or count indicator if there are events
                      if (dayTrips.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          child: dayTrips.length == 1
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF2B8B5), // Elegant pastel red
                                  shape: BoxShape.circle,
                                ),
                              )
                            : Text(
                                '${dayTrips.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF2B8B5), // Elegant pastel red
                                ),
                              ),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDayTripsModal(BuildContext context, List<TripList> dayTrips, int day) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trips on $day ${DateFormat('MMMM').format(_focusedDate)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: dayTrips.length,
                  separatorBuilder: (context, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final trip = dayTrips[index];
                    return ListTile(
                      title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () {
                        Navigator.pop(context); // close modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripListDetailScreen(
                              tripList: {
                                'id': trip.id,
                                'title': trip.title,
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
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
        final strDate = trip.startDate != null
            ? dateFormat.format(trip.startDate!)
            : 'No dates set';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
          title: Text(
            trip.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(strDate),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 16,
            color: Colors.grey,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripListDetailScreen(
                  tripList: {'id': trip.id, 'title': trip.title},
                ),
              ),
            );
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
                return DropdownMenuItem<T>(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
