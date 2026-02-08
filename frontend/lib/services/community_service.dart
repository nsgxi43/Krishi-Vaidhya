import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/community_post.dart';
import 'api_service.dart';

class CommunityService {
  static String get baseUrl => ApiService.baseUrl;

  static Future<List<CommunityPost>> getPosts({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/community/posts?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CommunityPost.fromJson(json)).toList();
      } else {
        print("Failed to load posts: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error loading posts: $e");
      return [];
    }
  }

  static Future<bool> createPost(String userId, String content, double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/community/posts'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "content": content,
          "lat": lat,
          "lng": lng,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error creating post: $e");
      return false;
    }
  }

  static Future<bool> likePost(String postId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/community/posts/$postId/like'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error liking post: $e");
      return false;
    }
  }

  static Future<bool> addComment(String postId, String userId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/community/posts/$postId/comment'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "content": content,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error adding comment: $e");
      return false;
    }
  }
}
