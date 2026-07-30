import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/db_service.dart';
import 'package:uuid/uuid.dart';

class NewEntryScreen extends StatefulWidget {
  final String? initialTranscript;

  const NewEntryScreen({super.key, this.initialTranscript});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _prosController = TextEditingController();
  final _consController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();

  String _selectedType = 'place';
  final List<String> _types = ['place', 'person', 'website', 'generic'];

  @override
  void initState() {
    super.initState();
    if (widget.initialTranscript?.isNotEmpty == true) {
      _notesController.text = widget.initialTranscript!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _prosController.dispose();
    _consController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final entry = Entry(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      type: _selectedType,
      pros: _prosController.text.trim().isEmpty
          ? null
          : _prosController.text.trim(),
      cons: _consController.text.trim().isEmpty
          ? null
          : _consController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await DbService().insertEntry(entry);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${entry.title}"')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving entry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Entry'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Joe\'s Diner, AB, example.com',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Type selector
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: _types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(type.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),

            // URL field (show only for website type)
            if (_selectedType == 'website') ...[
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
            ],

            // Pros field
            TextFormField(
              controller: _prosController,
              decoration: const InputDecoration(
                labelText: 'Pros / Advantages',
                hintText: 'What are the good things?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.thumb_up, color: Colors.green),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Cons field
            TextFormField(
              controller: _consController,
              decoration: const InputDecoration(
                labelText: 'Cons / Disadvantages',
                hintText: 'What are the issues or problems?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.thumb_down, color: Colors.red),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: _selectedType == 'person'
                    ? 'Notes (kids names, etc.)'
                    : 'Notes',
                hintText: _selectedType == 'person'
                    ? 'Kids: Anna, Ben'
                    : 'Additional information...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save),
              label: const Text('Save Entry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'place':
        return Icons.place;
      case 'person':
        return Icons.person;
      case 'website':
        return Icons.language;
      default:
        return Icons.note;
    }
  }
}
