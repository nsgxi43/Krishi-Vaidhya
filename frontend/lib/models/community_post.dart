class CommunityPost {
  final String id;
  final String userId;
  final String content;
  final Map<String, dynamic> location;
  final int likes;
  final int commentsCount;
  final DateTime createdAt;
  final List<String> likedBy;
  final String? imageUrl;
  final Map<String, dynamic>? analysisData;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.content,
    required this.location,
    required this.likes,
    required this.commentsCount,
    required this.createdAt,
    this.likedBy = const [],
    this.imageUrl,
    this.analysisData,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      location: json['location'] ?? {},
      likes: json['likes'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      createdAt: _parseDate(json['createdAt']),
      likedBy: List<String>.from(json['likedBy'] ?? []),
      imageUrl: json['imageUrl'],
      analysisData: json['analysisData'] is Map<String, dynamic> ? json['analysisData'] : null,
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.parse(date);
    if (date is Map && date.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(date['_seconds'] * 1000);
    }
    return DateTime.now();
  }
}

class PostComment {
  final String userId;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      createdAt: CommunityPost._parseDate(json['createdAt']),
    );
  }
}
