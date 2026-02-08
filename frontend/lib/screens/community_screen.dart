import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../utils/translations.dart';
import '../models/community_post.dart';
import '../services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<CommunityPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    final posts = await CommunityService.getPosts();
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  // Logic to add a new post
  Future<void> _addNewPost(String text) async {
    if (text.isEmpty) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.phone;
    
    // In a real scenario, we'd get actual lat/lng
    final success = await CommunityService.createPost(userId, text, 0.0, 0.0);
    
    if (success) {
      _fetchPosts();
      Navigator.pop(context); // Close the dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create post")),
      );
    }
  }

  // Dialog to write a post
  void _showPostDialog(String langCode) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.getText(langCode, 'ask_community')),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: AppTranslations.getText(langCode, 'write_post'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _addNewPost(_controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text(AppTranslations.getText(langCode, 'post_btn'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppTranslations.getText(langCode, 'community_title')),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPosts,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPosts,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final isLiked = post.likedBy.contains(userProvider.phone);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Author & Time
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: Text(
                                  post.userId.isNotEmpty ? post.userId[0] : 'U', 
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.userId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    "${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}", 
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Content
                          Text(post.content, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          const Divider(),

                          // Actions: Like, Comment, Share
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(
                                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey,
                                label: "${post.likes} ${AppTranslations.getText(langCode, 'like')}",
                                onTap: () async {
                                  final success = await CommunityService.likePost(post.id, userProvider.phone);
                                  if (success) {
                                    _fetchPosts();
                                  }
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.comment_outlined,
                                color: Colors.grey,
                                label: "${post.commentsCount} ${AppTranslations.getText(langCode, 'comment')}",
                                onTap: () {
                                  // Navigate to details screen (to be implemented)
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.share_outlined,
                                color: Colors.grey,
                                label: AppTranslations.getText(langCode, 'share'),
                                onTap: () {}, 
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostDialog(langCode),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: Text(
          AppTranslations.getText(langCode, 'ask_community'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}