import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/export_import_service.dart';
import '../models/entry.dart';
import 'entry_detail_screen.dart';
import 'dart:io';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final DbService _db = DbService();
  final ExportImportService _exportImport = ExportImportService();
  List<Entry> _entries = [];
  List<Entry> _filteredEntries = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedTypeFilter = 'all'; // all, place, person, website, generic

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _searchController.addListener(_filterEntries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final entries = await _db.queryAll();
    setState(() {
      _entries = entries;
      _filteredEntries = entries;
      _loading = false;
    });
    _filterEntries();
  }

  void _filterEntries() {
    setState(() {
      _filteredEntries = _entries.where((entry) {
        // Filter by search text
        final searchText = _searchController.text.toLowerCase();
        final matchesSearch = searchText.isEmpty ||
            entry.title.toLowerCase().contains(searchText) ||
            (entry.pros?.toLowerCase().contains(searchText) ?? false) ||
            (entry.cons?.toLowerCase().contains(searchText) ?? false) ||
            (entry.notes?.toLowerCase().contains(searchText) ?? false);

        // Filter by type
        final matchesType =
            _selectedTypeFilter == 'all' || entry.type == _selectedTypeFilter;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _deleteEntry(Entry entry) async {
    await _db.deleteEntry(entry.id);
    _loadEntries();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted "${entry.title}"')),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Place':
        return Colors.green;
      case 'Person':
        return Colors.blue;
      case 'Website':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results (${_filteredEntries.length})'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _exportData();
              } else if (value == 'import') {
                _importData();
              } else if (value == 'refresh') {
                _loadEntries();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.save_alt, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Export Backup'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Import Backup'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filter Section
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      // Search Field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search entries...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Filter Dropdown
                      Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20),
                          const SizedBox(width: 8),
                          const Text('Filter by type:',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedTypeFilter,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'all', child: Text('All Types')),
                                DropdownMenuItem(
                                    value: 'Place', child: Text('🏢 Place')),
                                DropdownMenuItem(
                                    value: 'Person', child: Text('👤 Person')),
                                DropdownMenuItem(
                                    value: 'Website',
                                    child: Text('🌐 Website')),
                                DropdownMenuItem(
                                    value: 'Generic',
                                    child: Text('📝 Generic')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedTypeFilter = value!;
                                });
                                _filterEntries();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Results List
                Expanded(
                  child: _filteredEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _entries.isEmpty
                                    ? 'No entries yet'
                                    : 'No matching entries',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                              Text(
                                _entries.isEmpty
                                    ? 'Record your first voice note!'
                                    : 'Try a different search or filter',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEntries,
                          child: ListView.builder(
                            itemCount: _filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredEntries[index];
                              return Dismissible(
                                key: Key(entry.id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Entry'),
                                      content: Text('Delete "${entry.title}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) {
                                  _deleteEntry(entry);
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _getTypeColor(entry.type),
                                      child: Icon(
                                        _getTypeIcon(entry.type),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      entry.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (entry
                                            .getDisplaySnippet()
                                            .isNotEmpty)
                                          Text(
                                            entry.getDisplaySnippet(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(
                                                entry.type,
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              backgroundColor:
                                                  _getTypeColor(entry.type)
                                                      .withOpacity(0.2),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatDate(entry.createdAt),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility),
                                              SizedBox(width: 8),
                                              Text('View'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete,
                                                  color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'view') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EntryDetailScreen(
                                                      entry: entry),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          _showDeleteDialog(entry);
                                        }
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EntryDetailScreen(entry: entry),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Place':
        return Icons.place;
      case 'Person':
        return Icons.person;
      case 'Website':
        return Icons.language;
      default:
        return Icons.note;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      return '$diff days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(Entry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(entry);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final filePath = await _exportImport.exportToICloud();
      final entries = await _db.queryAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Exported ${entries.length} entries to local storage\n\nBackup saved on device'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      // Get list of available backups
      final backups = await _exportImport.getBackupFiles();

      if (backups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No backup files found in iCloud'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Show backup file selection dialog
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index] as File;
                final fileName = backup.path.split('/').last;
                final fileStat = backup.statSync();
                final fileDate = _formatDate(fileStat.modified);
                return ListTile(
                  leading: const Icon(Icons.file_present),
                  title: Text(fileName
                      .replaceAll('ProCon_Backup_', '')
                      .replaceAll('.json', '')),
                  subtitle: Text('Saved $fileDate • Local Storage'),
                  onTap: () => Navigator.pop(context, backup.path),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selected == null) return;

      // Import from selected backup
      final importedCount = await _exportImport.importFromICloud(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Imported $importedCount entries from local backup\n\nList updated'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the list
        _loadEntries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
