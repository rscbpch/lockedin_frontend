class ReviewUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatar;

  const ReviewUser({required this.id, required this.username, required this.displayName, this.avatar});

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(id: json['_id']?.toString() ?? '', username: json['username'] ?? '', displayName: json['displayName'] ?? '', avatar: json['avatar']);
  }
}

class BookReview {
  final String id;
  final ReviewUser? user;
  final String userId;
  final int bookId;
  final int rating;
  final String feedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookReview({required this.id, this.user, required this.userId, required this.bookId, required this.rating, required this.feedback, this.createdAt, this.updatedAt});

  factory BookReview.fromJson(Map<String, dynamic> json) {
    // userId can be a populated object or a plain string ID
    final userIdRaw = json['userId'];
    ReviewUser? user;
    String userId;

    if (userIdRaw is Map<String, dynamic>) {
      user = ReviewUser.fromJson(userIdRaw);
      userId = user.id;
    } else {
      userId = userIdRaw?.toString() ?? '';
    }

    return BookReview(
      id: json['_id']?.toString() ?? '',
      user: user,
      userId: userId,
      bookId: (json['bookId'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      feedback: json['feedback'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {'rating': rating, 'feedback': feedback};
}
