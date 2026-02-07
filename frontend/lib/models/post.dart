class Post {
  final String id;
  final String authorName;
  final String timeAgo;
  final String content;
  int likes;
  int comments;
  bool isLiked; // To track if I liked it

  Post({
    required this.id,
    required this.authorName,
    required this.timeAgo,
    required this.content,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });
}