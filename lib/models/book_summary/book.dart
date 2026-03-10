class Book {
  final int id;
  final String title;
  final List<String> authors;
  final String summary;
  final List<String> categories;
  final int downloadCount;
  final Map<String, String> formats;

  const Book({required this.id, required this.title, required this.authors, required this.summary, required this.categories, required this.downloadCount, required this.formats});

  /// The first author name, or "Unknown Author" if none.
  String get author => authors.isNotEmpty ? authors.first : 'Unknown Author';

  /// Cover image URL extracted from `formats["image/jpeg"]`.
  String? get coverImageUrl => formats['image/jpeg'];

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] ?? '',
      authors: (json['authors'] as List<dynamic>?)?.map((a) => a.toString()).toList() ?? [],
      summary: json['summary'] ?? 'No summary available',
      categories: (json['categories'] as List<dynamic>?)?.map((c) => c.toString()).toList() ?? [],
      downloadCount: (json['downloadCount'] as num?)?.toInt() ?? 0,
      formats: (json['formats'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'authors': authors, 'summary': summary, 'categories': categories, 'downloadCount': downloadCount, 'formats': formats};
}
