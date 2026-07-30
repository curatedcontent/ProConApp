class Entry {
  final String id;
  final String title;
  final String type; // place, website, person, generic
  final String? pros;
  final String? cons;
  final String? notes;
  final String? url;
  final String? rawText; // Original voice/typed input
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  Entry({
    required this.id,
    required this.title,
    required this.type,
    this.pros,
    this.cons,
    this.notes,
    this.url,
    this.rawText,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'pros': pros,
      'cons': cons,
      'notes': notes,
      'url': url,
      'rawText': rawText,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      pros: map['pros'],
      cons: map['cons'],
      notes: map['notes'],
      url: map['url'],
      rawText: map['rawText'],
      createdAt: DateTime.parse(map['createdAt']),
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }

  // Create a copy with updated fields
  Entry copyWith({
    String? id,
    String? title,
    String? type,
    String? pros,
    String? cons,
    String? notes,
    String? url,
    String? rawText,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return Entry(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      notes: notes ?? this.notes,
      url: url ?? this.url,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String getDisplaySnippet() {
    List<String> parts = [];
    if (pros?.isNotEmpty == true)
      parts.add(
          'Pros: ${pros!.substring(0, pros!.length > 50 ? 50 : pros!.length)}...');
    if (cons?.isNotEmpty == true)
      parts.add(
          'Cons: ${cons!.substring(0, cons!.length > 50 ? 50 : cons!.length)}...');
    if (notes?.isNotEmpty == true)
      parts.add(
          'Notes: ${notes!.substring(0, notes!.length > 50 ? 50 : notes!.length)}...');
    return parts.join(' | ');
  }
}
