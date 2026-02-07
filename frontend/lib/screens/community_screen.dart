import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../models/post.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // --- MOCK DATA: Simulating a live feed ---
  final List<Post> _posts = [
    Post(
      id: '1',
      authorName: 'Ramesh Singh',
      timeAgo: '2 hrs ago',
      content: 'My tomato leaves are turning yellow at the bottom. Is this nitrogen deficiency or blight?',
      likes: 12,
      comments: 4,
    ),
    Post(
      id: '2',
      authorName: 'Anitha K.',
      timeAgo: '5 hrs ago',
      content: 'Found a great price for Urea at the local mandi today! ₹260 per bag.',
      likes: 25,
      comments: 8,
      isLiked: true, // Already liked example
    ),
    Post(
      id: '3',
      authorName: 'Gurpreet Singh',
      timeAgo: '1 day ago',
      content: 'Has anyone tried the new wheat variety HD-3086? How is the yield?',
      likes: 8,
      comments: 2,
    ),
  ];

  // Logic to add a new post
  void _addNewPost(String text) {
    if (text.isEmpty) return;
    setState(() {
      _posts.insert(0, Post(
        id: DateTime.now().toString(),
        authorName: 'You', // In a real app, use UserProvider.name
        timeAgo: 'Just now',
        content: text,
        likes: 0,
        comments: 0,
      ));
    });
    Navigator.pop(context); // Close the dialog
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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppTranslations.getText(langCode, 'community_title')),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
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
                        child: Text(post.authorName[0], style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(post.timeAgo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
                        icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey,
                        label: "${post.likes} ${AppTranslations.getText(langCode, 'like')}",
                        onTap: () {
                          setState(() {
                            post.isLiked = !post.isLiked;
                            post.isLiked ? post.likes++ : post.likes--;
                          });
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.comment_outlined,
                        color: Colors.grey,
                        label: "${post.comments} ${AppTranslations.getText(langCode, 'comment')}",
                        onTap: () {}, // Pending feature
                      ),
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        color: Colors.grey,
                        label: AppTranslations.getText(langCode, 'share'),
                        onTap: () {}, // Pending feature
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
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