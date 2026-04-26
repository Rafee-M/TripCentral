import 'package:flutter/material.dart';
import '../../core/patterns/singleton/supabase_service.dart';
import 'list_details_page.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  List<dynamic> _tripLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    try {
      final response = await SupabaseService.instance.client
          .from('trip_lists')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _tripLists = response as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      // Assuming table might not exist yet or auth issue
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteList(String listId, int index) async {
    try {
      await SupabaseService.instance.client
          .from('trip_lists')
          .delete()
          .eq('id', listId);

      setState(() {
        _tripLists.removeAt(index);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting list: $e')),
        );
      }
    }
  }

  Future<void> _showCreateListDialog() async {
    String newListName = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New List'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter list name'),
            onChanged: (value) {
              newListName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, newListName),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        final response = await SupabaseService.instance.client
            .from('trip_lists')
            .insert({'name': result})
            .select()
            .single();
        
        setState(() {
          _tripLists.insert(0, response);
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListDetailsPage(
                listId: response['id'].toString(),
                listName: response['name'],
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating list: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lists'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _showCreateListDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'create new list',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tripLists.isEmpty
                    ? const Center(child: Text('No lists found.'))
                    : ListView.builder(
                        itemCount: _tripLists.length,
                        itemBuilder: (context, index) {
                          final list = _tripLists[index];
                          return ListTile(
                            leading: const Icon(Icons.list_alt),
                            title: Text(list['name'] ?? 'Unnamed List'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteList(
                                      list['id'].toString(), index),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListDetailsPage(
                                    listId: list['id'].toString(),
                                    listName: list['name'] ?? 'Unnamed',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
