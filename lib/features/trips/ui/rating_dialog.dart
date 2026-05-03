import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  final String tripTitle;
  final Function(int rating, String? reviewText) onSubmit;
  final VoidCallback? onCancel;
  final int? initialRating;
  final String? initialReviewText;
  final bool isEditMode;

  const RatingDialog({
    Key? key,
    required this.tripTitle,
    required this.onSubmit,
    this.onCancel,
    this.initialRating,
    this.initialReviewText,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _rating;
  late final TextEditingController _reviewController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _reviewController = TextEditingController(
      text: widget.initialReviewText ?? '',
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_rating, _reviewController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEditMode ? 'Edit Review' : 'Rate Trip',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            widget.tripTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = _rating >= starIndex;
                  return IconButton(
                    icon: Icon(
                      isSelected ? Icons.star : Icons.star_outline,
                      size: 40,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                    onPressed: () => setState(() => _rating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Review Text (Optional)
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  labelText: widget.isEditMode
                      ? 'Update your review (optional)'
                      : 'Add a review (optional)',
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(widget.isEditMode ? 'Update review' : 'Submit'),
        ),
      ],
    );
  }
}
