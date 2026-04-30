import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_central/features/trips/services/trip_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripService = TripService();

  bool _isLoading = false;

  // Data models
  String _title = '';
  String? _description;
  bool _isPublic = false;
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          // Minimalist picker styling overridden here or via Main app theme
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      if (mounted) {
        setState(() {
          _startDate = range.start;
          _endDate = range.end;
        });
      }
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // Connect to the Facade wrapper saving user inputted values back to DB schema format seamlessly wrapper.
      await _tripService.createTrip(
        title: _title,
        description: _description,
        isPublic: _isPublic,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created successfully!')),
      );

      // Pop true to instruct HomeScreen to cleanly refresh list
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save trip: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('New Adventure'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Let\'s build your next trip',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Minimalist Input Text Form
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Trip Title',
                  hintText: 'e.g. Summer in Kyoto',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                onSaved: (val) => _title = val!.trim(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'What are you planning?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                maxLines: 3,
                onSaved: (val) => _description = val?.trim(),
              ),
              const SizedBox(height: 24),

              // Date Range Button Card format wrapper pattern essentially
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _startDate != null && _endDate != null
                              ? '${dateFormat.format(_startDate!)}  -  ${dateFormat.format(_endDate!)}'
                              : 'Select Dates (Optional)',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Is Public switch natively elegant mapping DB constraint
              SwitchListTile(
                title: const Text('Make Trip Public'),
                subtitle: const Text('Allow others to view and review this trip.'),
                value: _isPublic,
                onChanged: (val) => setState(() => _isPublic = val),
                activeColor: theme.colorScheme.primary, // using directly, it falls back inside switch correctly
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 48),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _saveTrip,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


