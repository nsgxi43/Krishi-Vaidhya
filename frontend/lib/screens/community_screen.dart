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
  CommunityScreenState createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen> {
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

  Future<void> _addNewPost(String text) async {
    if (text.trim().isEmpty) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await CommunityService.createPost(
      userProvider.phone,
      text.trim(),
      0.0,
      0.0,
      userName: userProvider.name,
    );
    if (success) {
      _fetchPosts();
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to create post"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showPostDialog() {
    final langCode = Provider.of<LanguageProvider>(context, listen: false).currentLocale;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppTranslations.getText(langCode, 'ask_community'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Share a question, concern, or observation with the farming community',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: AppTranslations.getText(langCode, 'write_post'),
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _addNewPost(controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    AppTranslations.getText(langCode, 'post_btn'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context).currentLocale;
    final userProvider = Provider.of<UserProvider>(context);

    return ColoredBox(
      color: const Color(0xFFF4F6F8),
      child: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppTranslations.getText(langCode, 'community_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Farmers helping farmers',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchPosts,
              ),
            ],
          ),

          // ── Ask bar ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: showPostDialog,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        userProvider.name.isNotEmpty
                            ? userProvider.name[0].toUpperCase()
                            : 'F',
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppTranslations.getText(langCode, 'write_post'),
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppTranslations.getText(langCode, 'post_btn'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // ── Posts list / empty / loading ─────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            )
          else if (_posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No posts yet',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    Text('Be the first to share!',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];
                  final isLiked =
                      post.likedBy.contains(userProvider.phone);
                  return _PostCard(
                    post: post,
                    isLiked: isLiked,
                    timeAgo: _timeAgo(post.createdAt),
                    onLike: () async {
                      final ok = await CommunityService.likePost(
                          post.id, userProvider.phone);
                      if (ok) _fetchPosts();
                    },
                    langCode: langCode,
                  );
                },
                childCount: _posts.length,
              ),
            ),
          // Bottom padding so FAB doesn't cover the last card
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Post Card Widget
// ══════════════════════════════════════════════════════════════════════
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isLiked;
  final String timeAgo;
  final VoidCallback onLike;
  final String langCode;

  const _PostCard({
    required this.post,
    required this.isLiked,
    required this.timeAgo,
    required this.onLike,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    // Consistent avatar colour based on the farmer's name
    const avatarColors = [
      Colors.teal,
      Colors.indigo,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.blue,
      Colors.brown,
    ];
    final avatarColor = avatarColors[post.userName.isNotEmpty
        ? post.userName.codeUnitAt(0) % avatarColors.length
        : 0];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: avatarColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      post.userName.isNotEmpty
                          ? post.userName[0].toUpperCase()
                          : 'F',
                      style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + location + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (post.locationDisplay.isNotEmpty) ...[
                            Icon(Icons.location_on,
                                size: 12,
                                color: Colors.grey.shade400),
                            const SizedBox(width: 2),
                            Text(
                              post.locationDisplay,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade500),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('·',
                                  style: TextStyle(
                                      color: Colors.grey.shade400)),
                            ),
                          ],
                          Text(
                            timeAgo,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Post content ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              post.content,
              style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF1A1A1A)),
            ),
          ),

          // ── Analysis chip ──────────────────────────────────────
          if (post.analysisData != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.biotech,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${post.analysisData!['crop'] ?? ''} — ${post.analysisData!['label'] ?? ''}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1B5E20)),
                          ),
                          if (post.analysisData!['confidence'] != null)
                            Text(
                              "Confidence: ${((post.analysisData!['confidence'] as num) * 100).toStringAsFixed(1)}%",
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.green.shade700),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Image ──────────────────────────────────────────────
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  "${CommunityService.baseUrl.replaceAll('/api', '')}${post.imageUrl}",
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey.shade300, size: 40),
                    ),
                  ),
                ),
              ),
            ),

          // ── Actions ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                _ActionBtn(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked ? Colors.redAccent : Colors.grey.shade500,
                  label: post.likes > 0 ? '${post.likes}' : '',
                  onTap: onLike,
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.grey.shade500,
                  label: post.commentsCount > 0
                      ? '${post.commentsCount}'
                      : '',
                  onTap: () {},
                ),
                const Spacer(),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  color: Colors.grey.shade500,
                  label: '',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}