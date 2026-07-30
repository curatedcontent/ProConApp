class QueryIntent {
  final String intent; // ask_pros, ask_cons, ask_kids, ask_notes, show_results
  final String? target;

  QueryIntent(this.intent, [this.target]);
}

class QueryParser {
  static QueryIntent? parseQuery(String query) {
    final normalizedQuery = query.toLowerCase().trim();

    // Show results trigger
    if (normalizedQuery.contains('show results') &&
        normalizedQuery.contains('over')) {
      return QueryIntent('show_results');
    }

    // Extract target entity (everything after "of" or before "kid")
    String? target;

    // Pros queries (supports synonyms)
    if (normalizedQuery.contains('pros of') ||
        normalizedQuery.contains('good about') ||
        normalizedQuery.contains('positive about') ||
        normalizedQuery.contains('like about') ||
        normalizedQuery.contains('advantages of')) {
      target = _extractTarget(normalizedQuery, [
        'pros of',
        'good about',
        'positive about',
        'like about',
        'advantages of'
      ]);
      return QueryIntent('ask_pros', target);
    }

    // Cons queries (supports synonyms)
    if (normalizedQuery.contains('cons of') ||
        normalizedQuery.contains('bad about') ||
        normalizedQuery.contains('negative about') ||
        normalizedQuery.contains('dislike about') ||
        normalizedQuery.contains('disadvantages of')) {
      target = _extractTarget(normalizedQuery, [
        'cons of',
        'bad about',
        'negative about',
        'dislike about',
        'disadvantages of'
      ]);
      return QueryIntent('ask_cons', target);
    }

    // Kids queries
    if (normalizedQuery.contains('kid name') ||
        normalizedQuery.contains('children')) {
      target = _extractPersonTarget(normalizedQuery);
      return QueryIntent('ask_kids', target);
    }

    // Notes queries
    if (normalizedQuery.contains('notes about') ||
        normalizedQuery.contains('info about')) {
      target = _extractTarget(normalizedQuery, ['notes about', 'info about']);
      return QueryIntent('ask_notes', target);
    }

    return null;
  }

  static String? _extractTarget(String query, List<String> patterns) {
    for (String pattern in patterns) {
      int index = query.indexOf(pattern);
      if (index != -1) {
        String afterPattern = query.substring(index + pattern.length).trim();
        // Remove question mark and clean up
        afterPattern = afterPattern.replaceAll('?', '').trim();
        return afterPattern.isEmpty ? null : afterPattern;
      }
    }
    return null;
  }

  static String? _extractPersonTarget(String query) {
    // Look for pattern like "AB person kid name" or "what is [Name] kid name"
    RegExp personPattern = RegExp(
        r'(?:what is |what was )?([a-zA-Z]+)\s*(?:person )?kid',
        caseSensitive: false);
    Match? match = personPattern.firstMatch(query);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    return null;
  }
}
