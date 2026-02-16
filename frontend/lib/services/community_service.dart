import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  static Future<bool> createPost(String userId, String content, double lat, double lng, {String? imagePath, Map<String, dynamic>? analysisData}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/community/posts'));
      
      request.fields['userId'] = userId;
      request.fields['content'] = content;
      request.fields['lat'] = lat.toString();
      request.fields['lng'] = lng.toString();
      
      if (analysisData != null) {
        request.fields['analysisData'] = jsonEncode(analysisData);
      }

      if (imagePath != null) {
        if (kIsWeb) {
          // Web: Read bytes from blob/url
          final res = await http.get(Uri.parse(imagePath));
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              res.bodyBytes,
              filename: 'upload.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else {
          // Mobile/Desktop: Use file path
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imagePath,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

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
