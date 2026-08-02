import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/db_service.dart';
import '../services/query_parser.dart';
import '../models/entry.dart';
import 'new_entry_screen.dart';
import 'package:uuid/uuid.dart';
import '../widgets/account_button.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onVoiceTrigger;
  const HomeScreen({super.key, this.onVoiceTrigger});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechService _speech = SpeechService();
  final DbService _db = DbService();
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _transcriptFocusNode = FocusNode();

  String _transcript = '';
  String _partialTranscript = '';
  bool _listening = false;
  List<Entry> _queryResults = [];
  bool _showQueryResults = false;
  bool _keyboardVisible = false;
  String _selectedType = ''; // No default - user must select a type

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeDatabase();
    _transcriptFocusNode.addListener(() {
      setState(() {
        _keyboardVisible = _transcriptFocusNode.hasFocus;
      });
    });
    // Add listener to update button state when text changes
    _transcriptController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _transcriptFocusNode.dispose();
    _transcriptController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _initializeSpeech() async {
    await _speech.init();
    setState(() {}); // Refresh UI after initialization
  }

  void _initializeDatabase() async {
    await _db.init();
  }

  void _toggleListening() async {
    if (!_listening) {
      bool ok = await _speech.startListening(
        onResult: (text) {
          setState(() {
            // Append new text to existing transcript
            if (_transcript.isNotEmpty && !_transcript.endsWith(' ')) {
              _transcript += ' ';
            }
            _transcript += text;
            _transcriptController.text = _transcript;
          });
        },
        onPartialResult: (text) {
          setState(() {
            _partialTranscript = text;
            // Show partial text appended to existing
            String displayText = _transcript;
            if (displayText.isNotEmpty && !displayText.endsWith(' ')) {
              displayText += ' ';
            }
            _transcriptController.text = displayText + text;
          });
        },
        onVoiceTrigger: (intent) {
          // Not needed for simple flow
        },
      );
      if (ok) setState(() => _listening = true);
    } else {
      await _speech.stopListening();
      setState(() {
        _listening = false;
        _partialTranscript = '';
      });
      // Transcript is now displayed in text field for editing
    }
  }

  Future<void> _extractAndSaveEntry(String transcript) async {
    // Extract title, type, pros, cons from transcript
    final lines = transcript
        .split(RegExp(r'[.\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Simple extraction logic
    String title = '';
    String type = _selectedType; // Use the user-selected type
    String pros = '';
    String cons = '';
    String notes = transcript;
    String rawText = transcript; // Store raw input

    // Try to extract title from first line or look for "about/for/of"
    if (lines.isNotEmpty) {
      final firstLine = lines.first;
      // Look for patterns like "pros and cons of New York" or "about Central Park"
      final titleMatch =
          RegExp(r'(?:about|for|of)\s+(.+)', caseSensitive: false)
              .firstMatch(firstLine);
      if (titleMatch != null) {
        title = titleMatch.group(1)!.trim();
      } else {
        // Use first few words as title
        final words = firstLine.split(' ');
        title = words.take(5).join(' ');
      }
    }

    // Extract pros (supports synonyms: pros, good, positive, like, advantages)
    final prosMatch = RegExp(
            r'(?:pros?|good|positive|like|advantages)\s*:?\s*([^.]+)',
            caseSensitive: false,
            dotAll: true)
        .firstMatch(transcript);
    if (prosMatch != null) {
      String prosText = prosMatch.group(1)!;
      // Stop at cons keywords
      final consKeywords = RegExp(
          r'\b(?:cons?|bad|negative|dislike|disadvantages)\b',
          caseSensitive: false);
      final consMatch = consKeywords.firstMatch(prosText);
      if (consMatch != null) {
        prosText = prosText.substring(0, consMatch.start);
      }
      pros = prosText.trim();
    }

    // Extract cons (supports synonyms: cons, bad, negative, dislike, disadvantages)
    final consMatch = RegExp(
            r'(?:cons?|bad|negative|dislike|disadvantages)\s*:?\s*(.+)',
            caseSensitive: false,
            dotAll: true)
        .firstMatch(transcript);
    if (consMatch != null) {
      cons = consMatch.group(1)!.trim();
    }

    // If title is empty, use a default
    if (title.isEmpty) {
      title = 'Voice Note ${DateTime.now().toString().substring(0, 16)}';
    }

    // Create and save entry
    final entry = Entry(
      id: const Uuid().v4(),
      title: title,
      type: type,
      pros: pros.isEmpty ? null : pros,
      cons: cons.isEmpty ? null : cons,
      notes: notes,
      url: null,
      rawText: rawText,
      createdAt: DateTime.now(),
    );

    try {
      await _db.insertEntry(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${entry.title}"'),
            backgroundColor: Colors.lightGreen,
          ),
        );
        _clearTranscript();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _executeQuery(QueryIntent intent) async {
    List<Entry> results = [];

    if (intent.target != null) {
      // First try exact match
      final exactMatch = await _db.findByTitle(intent.target!);
      if (exactMatch != null) {
        results.add(exactMatch);
      } else {
        // Then try partial matches
        results = await _db.findByTitleContains(intent.target!);
      }
    }

    setState(() {
      _queryResults = results;
      _showQueryResults = true;
    });

    // Show result in a dialog or bottom sheet
    if (results.isNotEmpty) {
      _showQueryResultDialog(intent, results.first);
    } else {
      _showNoResultsDialog(intent.target ?? 'unknown');
    }
  }

  void _showQueryResultDialog(QueryIntent intent, Entry entry) {
    String result = '';
    switch (intent.intent) {
      case 'ask_pros':
        result = entry.pros ?? 'No pros recorded for ${entry.title}';
        break;
      case 'ask_cons':
        result = entry.cons ?? 'No cons recorded for ${entry.title}';
        break;
      case 'ask_kids':
        result =
            entry.notes ?? 'No kids information recorded for ${entry.title}';
        break;
      case 'ask_notes':
        result = entry.notes ?? 'No notes recorded for ${entry.title}';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${entry.title}'),
        content: Text(result),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNoResultsDialog(String target) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Results Found'),
        content: Text('No information found for "$target"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchEntries(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _queryResults = [];
        _showQueryResults = false;
      });
      return;
    }

    final results = await _db.search(query);
    setState(() {
      _queryResults = results;
      _showQueryResults = true;
    });
  }

  void _clearTranscript() {
    setState(() {
      _transcript = '';
      _transcriptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: const [AccountButton()],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _queryController,
                decoration: const InputDecoration(
                  hintText: 'Search entries or ask questions...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _searchEntries,
              ),
              const SizedBox(height: 16),

              // Voice icon and transcript area
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Large voice icon (shrink when keyboard visible)
                        GestureDetector(
                          onTap: _toggleListening,
                          child: Container(
                            width: _keyboardVisible ? 60 : 120,
                            height: _keyboardVisible ? 60 : 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _listening
                                  ? Colors.red
                                  : Theme.of(context).primaryColor,
                              boxShadow: _listening
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: _keyboardVisible ? 10 : 20,
                                        spreadRadius: _keyboardVisible ? 2 : 5,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              _listening ? Icons.mic : Icons.mic_none,
                              size: _keyboardVisible ? 30 : 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _listening
                              ? 'Tap to stop recording'
                              : 'Tap to start recording',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_partialTranscript.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Hearing: $_partialTranscript',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Live transcript editor
                        Expanded(
                          child: TextField(
                            controller: _transcriptController,
                            focusNode: _transcriptFocusNode,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              hintText:
                                  'Your voice transcript will appear here...\nSay: "Name of the place [name], pros: [list], cons: [list]"',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _transcript = value;
                              });
                            },
                          ),
                        ),

                        // Type selector buttons
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTypeButton(
                                  'Place', Icons.place, Colors.green),
                              const SizedBox(width: 8),
                              _buildTypeButton(
                                  'Person', Icons.person, Colors.blue),
                              const SizedBox(width: 8),
                              _buildTypeButton(
                                  'Website', Icons.language, Colors.orange),
                              const SizedBox(width: 8),
                              _buildTypeButton(
                                  'Generic', Icons.note, Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons - Always visible and green submit
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _clearTranscript,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Clear', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Submit'),
                      onPressed: () async {
                        if (_transcriptController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter some text first'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        if (_selectedType.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please select a type (Place, Person, Website, or Generic)'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        await _extractAndSaveEntry(_transcriptController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _transcriptController.text.trim().isEmpty
                                ? Colors.grey.shade400
                                : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NewEntryScreen(initialTranscript: _transcript),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Manual', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),

              // Query results (if any) - wrapped to prevent overflow
              if (_showQueryResults && _queryResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                Flexible(
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Search Results (${_queryResults.length})',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => _showQueryResults = false),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _queryResults.length,
                            itemBuilder: (context, index) {
                              final entry = _queryResults[index];
                              return ListTile(
                                title: Text(entry.title),
                                subtitle: Text(entry.getDisplaySnippet()),
                                trailing: Chip(
                                  label: Text(entry.type),
                                  backgroundColor: _getTypeColor(entry.type),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              type.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Place':
        return Colors.green.shade100;
      case 'Person':
        return Colors.blue.shade100;
      case 'Website':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
