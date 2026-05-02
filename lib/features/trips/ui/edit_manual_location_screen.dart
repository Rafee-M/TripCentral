import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditManualLocationScreen extends StatefulWidget {
  final Map<String, dynamic> location;

  const EditManualLocationScreen({Key? key, required this.location}) : super(key: key);

  @override
  State<EditManualLocationScreen> createState() => _EditManualLocationScreenState();
}

class _EditManualLocationScreenState extends State<EditManualLocationScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location['name']?.toString() ?? '');
    _descController = TextEditingController(text: widget.location['description']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.location['address']?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.location['phone_number']?.toString() ?? '');
    _websiteController = TextEditingController(text: widget.location['website_url']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location Name is required')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('trip_locations').update({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'address': _addressController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'website_url': _websiteController.text.trim(),
      }).eq('id', widget.location['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error occurred')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Location'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveLocation),
        ],
      ),
      body: SingleChildScrollView(
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
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _websiteController,
                    decoration: const InputDecoration(labelText: 'Website / URL', border: OutlineInputBorder()),
                    keyboardType: TextInputType.url,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

