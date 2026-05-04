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
      appBar: AppBar(title: const Text('Search Trips'), centerTitle: false),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover trips',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search public, owned, or invited trips with a clean, modern interface.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search by trip title',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _load();
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text('Sort by', style: theme.textTheme.bodyMedium),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
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
                    itemBuilder: (context, index) => _TripCard(
                      card: _results[index],
                      onReviewChanged: _load,
                    ),
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
  const _TripCard({required this.card, this.onReviewChanged});

  final DiscoverTripCard card;
  final VoidCallback? onReviewChanged;

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  final TripDiscoveryService _service = TripDiscoveryService();

  Future<void> _showRatingDialog() async {
    final wasEditMode = widget.card.hasMyReview;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(
        tripTitle: widget.card.title,
        isEditMode: wasEditMode,
        initialRating: widget.card.myRating,
        initialReviewText: widget.card.myReviewText,
        onSubmit: (rating, reviewText) async {
          try {
            await _service.submitRating(
              tripListId: widget.card.id,
              rating: rating,
              reviewText: reviewText,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
            rethrow;
          }
        },
      ),
    );

    if (!mounted || result != true) {
      return;
    }

    widget.onReviewChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasEditMode
              ? 'Review updated successfully'
              : 'Review submitted successfully',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = widget.card.startDate != null
        ? DateFormat('MMM d, yyyy').format(widget.card.startDate!)
        : 'Date not set';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _CoverImage(coverImageUrl: widget.card.coverImageUrl),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.card.isPublic ? 'Public' : 'Private',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.card.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(icon: Icons.event_rounded, label: dateText),
                      if (widget.card.averageRating != null)
                        _MetaChip(
                          icon: Icons.star_rounded,
                          label:
                              '${widget.card.averageRating!.toStringAsFixed(1)} (${widget.card.reviewCount})',
                        )
                      else
                        _MetaChip(
                          icon: Icons.star_border_rounded,
                          label: 'No ratings yet',
                        ),
                      if (widget.card.hasMyReview)
                        _MetaChip(
                          icon: Icons.edit_rounded,
                          label: 'Review saved',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.card.locationNames.isEmpty)
                    Text(
                      'No locations added yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
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
                              child: Text(
                                name,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (widget.card.isPublic) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: widget.card.isOwnedByCurrentUser
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.block_outlined, size: 18),
                              label: const Text('Owner cannot review'),
                            )
                          : FilledButton.tonalIcon(
                              onPressed: _showRatingDialog,
                              icon: Icon(
                                widget.card.hasMyReview
                                    ? Icons.edit_rounded
                                    : Icons.star_rounded,
                                size: 18,
                              ),
                              label: Text(
                                widget.card.hasMyReview
                                    ? 'Edit review'
                                    : 'Rate this trip',
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        child: const Center(child: Icon(Icons.landscape_rounded, size: 36)),
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
          child: const Icon(Icons.broken_image_rounded),
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
