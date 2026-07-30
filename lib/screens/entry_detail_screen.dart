import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/db_service.dart';

class EntryDetailScreen extends StatefulWidget {
  final Entry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late Entry _entry;
  final DbService _db = DbService();
  bool _isEditing = false;

  // Controllers for editing
  late TextEditingController _titleController;
  late TextEditingController _prosController;
  late TextEditingController _consController;
  late TextEditingController _notesController;
  late TextEditingController _urlController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _initControllers();
  }

  void _initControllers() {
    _titleController = TextEditingController(text: _entry.title);
    _prosController = TextEditingController(text: _entry.pros ?? '');
    _consController = TextEditingController(text: _entry.cons ?? '');
    _notesController = TextEditingController(text: _entry.notes ?? '');
    _urlController = TextEditingController(text: _entry.url ?? '');
    _selectedType = _entry.type;
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

  Future<void> _saveChanges() async {
    final updatedEntry = _entry.copyWith(
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
    );

    await _db.updateEntry(updatedEntry);

    setState(() {
      _entry = updatedEntry;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancel editing, restore original values
        _initControllers();
      }
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : _entry.title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Save',
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
              tooltip: 'Edit',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEdit,
              tooltip: 'Cancel',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and date
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Type:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['place', 'person', 'website', 'generic']
                                .map((type) {
                              return ChoiceChip(
                                label: Text(type.toUpperCase()),
                                selected: _selectedType == type,
                                selectedColor: _getTypeColor(type),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedType = type);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getTypeColor(_entry.type),
                            child: Icon(
                              _getTypeIcon(_entry.type),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _entry.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(_entry.type.toUpperCase()),
                                      backgroundColor:
                                          _getTypeColor(_entry.type)
                                              .withOpacity(0.2),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _formatDate(_entry.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // URL section
            if (_isEditing || _entry.url?.isNotEmpty == true) ...[
              _buildEditableSection(
                'Website URL',
                _urlController,
                Icons.link,
                Colors.blue,
                _entry.url,
              ),
              const SizedBox(height: 16),
            ],

            // Pros section
            _buildEditableSection(
              'Pros / Advantages',
              _prosController,
              Icons.thumb_up,
              Colors.green,
              _entry.pros,
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Cons section
            _buildEditableSection(
              'Cons / Disadvantages',
              _consController,
              Icons.thumb_down,
              Colors.red,
              _entry.cons,
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Notes section
            _buildEditableSection(
              _entry.type == 'person' ? 'Notes (Kids, etc.)' : 'Notes',
              _notesController,
              Icons.note,
              Colors.orange,
              _entry.notes,
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Location (if available)
            if (_entry.latitude != null && _entry.longitude != null) ...[
              _buildSection(
                'Location',
                'Lat: ${_entry.latitude!.toStringAsFixed(6)}, Lng: ${_entry.longitude!.toStringAsFixed(6)}',
                Icons.location_on,
                Colors.purple,
              ),
              const SizedBox(height: 16),
            ],

            // Raw Text section (always show at bottom if available)
            if (_entry.rawText?.isNotEmpty == true) ...[
              const Divider(thickness: 2),
              const SizedBox(height: 8),
              _buildSection(
                'Original Input (Raw Text)',
                _entry.rawText!,
                Icons.record_voice_over,
                Colors.indigo,
              ),
              const SizedBox(height: 16),
            ],

            // Empty state if no content
            if (_isEmpty() && !_isEditing) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No additional details recorded',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the edit button to add details',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isEmpty() {
    return (_entry.pros?.isEmpty != false) &&
        (_entry.cons?.isEmpty != false) &&
        (_entry.notes?.isEmpty != false) &&
        (_entry.url?.isEmpty != false);
  }

  Widget _buildEditableSection(
    String title,
    TextEditingController controller,
    IconData icon,
    Color color,
    String? displayValue, {
    int maxLines = 1,
  }) {
    if (!_isEditing && (displayValue?.isEmpty != false)) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing)
              TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: 'Enter $title...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: color.withOpacity(0.05),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayValue ?? '',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, String content, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'place':
        return Colors.green;
      case 'person':
        return Colors.blue;
      case 'website':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
