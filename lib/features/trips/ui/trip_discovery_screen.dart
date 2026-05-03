import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/discover_trip_card.dart';
import '../services/discovery/trip_discovery_service.dart';
import '../services/discovery/trip_discovery_service_types.dart';
import 'trip_list_detail_screen.dart';
import 'rating_dialog.dart';

class TripDiscoveryScreen extends StatefulWidget {
  const TripDiscoveryScreen({super.key});

  @override
  State<TripDiscoveryScreen> createState() => _TripDiscoveryScreenState();
}

class _TripDiscoveryScreenState extends State<TripDiscoveryScreen> {
  final TripDiscoveryService _service = TripDiscoveryService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  TripDiscoveryFilter _filter = TripDiscoveryFilter.public;
  TripDiscoverySort _sort = TripDiscoverySort.rating;

  bool _isLoading = true;
  String? _errorMessage;
  List<DiscoverTripCard> _results = <DiscoverTripCard>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cards = await _service.searchTripLists(
        filter: _filter,
        sort: _sort,
        query: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _results = cards;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load trip lists. Please try again.';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _onFilterChanged(TripDiscoveryFilter newFilter) {
    setState(() {
      _filter = newFilter;
      if (_filter != TripDiscoveryFilter.public &&
          _sort == TripDiscoverySort.rating) {
        _sort = TripDiscoverySort.date;
      }
    });
    _load();
  }

  void _onSortChanged(TripDiscoverySort? value) {
    if (value == null) return;
    setState(() => _sort = value);
    _load();
  }

  List<DropdownMenuItem<TripDiscoverySort>> _sortItems() {
    final items = <DropdownMenuItem<TripDiscoverySort>>[
      const DropdownMenuItem(
        value: TripDiscoverySort.title,
        child: Text('Title'),
      ),
      const DropdownMenuItem(
        value: TripDiscoverySort.date,
        child: Text('Date'),
      ),
    ];

    if (_filter == TripDiscoveryFilter.public) {
      items.add(
        const DropdownMenuItem(
          value: TripDiscoverySort.rating,
          child: Text('Rating'),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Trips')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by trip title',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _load();
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Public'),
                            selected: _filter == TripDiscoveryFilter.public,
                            onSelected: (_) =>
                                _onFilterChanged(TripDiscoveryFilter.public),
                          ),
                          ChoiceChip(
                            label: const Text('Own'),
                            selected: _filter == TripDiscoveryFilter.own,
                            onSelected: (_) =>
                                _onFilterChanged(TripDiscoveryFilter.own),
                          ),
                          ChoiceChip(
                            label: const Text('Invited'),
                            selected: _filter == TripDiscoveryFilter.invited,
                            onSelected: (_) =>
                                _onFilterChanged(TripDiscoveryFilter.invited),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Sort by', style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<TripDiscoverySort>(
                                value: _sort,
                                items: _sortItems(),
                                onChanged: _onSortChanged,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorView(message: _errorMessage!, onRetry: _load),
                )
              else if (_results.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  sliver: SliverList.separated(
                    itemCount: _results.length,
                    itemBuilder: (context, index) =>
                        _TripCard(card: _results[index]),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatefulWidget {
  const _TripCard({required this.card});

  final DiscoverTripCard card;

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  final TripDiscoveryService _service = TripDiscoveryService();
  bool _isRating = false;

  void _showRatingDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => RatingDialog(
        tripTitle: widget.card.title,
        onSubmit: (rating, reviewText) async {
          setState(() => _isRating = true);
          try {
            await _service.submitRating(
              tripListId: widget.card.id,
              rating: rating,
              reviewText: reviewText,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rating submitted!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
            rethrow;
          } finally {
            if (mounted) {
              setState(() => _isRating = false);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = widget.card.startDate != null
        ? DateFormat('MMM d, yyyy').format(widget.card.startDate!)
        : 'Date not set';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripListDetailScreen(
              tripList: {'id': widget.card.id, 'title': widget.card.title},
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverImage(coverImageUrl: widget.card.coverImageUrl),
              const SizedBox(height: 10),
              Text(
                widget.card.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(dateText, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 10),
                  if (widget.card.averageRating != null) ...[
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.card.averageRating!.toStringAsFixed(1)} (${widget.card.reviewCount})',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (widget.card.locationNames.isEmpty)
                Text('No locations added yet', style: theme.textTheme.bodySmall)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.card.locationNames
                      .map(
                        (name) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(name, style: theme.textTheme.labelMedium),
                        ),
                      )
                      .toList(),
                ),
              // Rate button for public trips
              if (widget.card.isPublic) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isRating ? null : _showRatingDialog,
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('Rate this trip'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (coverImageUrl == null || coverImageUrl!.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: const Center(child: Icon(Icons.landscape, size: 36)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        coverImageUrl!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 140,
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.travel_explore, size: 48),
            SizedBox(height: 12),
            Text('No trip lists found'),
            SizedBox(height: 6),
            Text(
              'Try another search or change the filter.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
