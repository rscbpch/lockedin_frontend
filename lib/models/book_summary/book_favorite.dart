class BookFavorite {
  final String id;
  final String userId;
  final int bookId;
  final DateTime? createdAt;

  const BookFavorite({required this.id, required this.userId, required this.bookId, this.createdAt});

  factory BookFavorite.fromJson(Map<String, dynamic> json) {
    return BookFavorite(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      bookId: (json['bookId'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {'bookId': bookId};
}
