import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'community_answer_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, this.onItemTapped, this.selectedIndex});

  final Function(int)? onItemTapped;
  final int? selectedIndex;

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref('questions');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _questionTitleController =
      TextEditingController();
  final TextEditingController _questionDescriptionController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'Most Recent';
  bool _isLoading = false;
  bool _isPosting = false;

  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> original) {
    return original
        .map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
  }

  @override
  void dispose() {
    _questionTitleController.dispose();
    _questionDescriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Stream<DatabaseEvent> getQuestionsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    Query query;
    switch (_selectedFilter) {
      case 'Most Recent':
        query = _database.orderByChild('timestamp');
        break;
      case 'Oldest':
        query = _database.orderByChild('timestamp');
        break;
      case 'Most Likes':
        query = _database.orderByChild('likes');
        break;
      case 'Most Dislikes':
        query = _database.orderByChild('dislikes');
        break;
      default:
        query = _database.orderByChild('timestamp');
    }
    return query.onValue;
  }

  Future<void> _incrementViews(String questionId, int currentViews) async {
    try {
      await _database.child(questionId).update({
        'views': currentViews + 1,
        'viewedBy/${_auth.currentUser?.uid}': true,
      });
    } catch (e) {
      debugPrint('Error incrementing views: $e');
      _showErrorSnackbar('Failed to update views');
    }
  }

  Future<void> _toggleLike(String questionId, bool currentLiked,
      int currentLikes, bool currentDisliked) async {
    if (_auth.currentUser == null) return;

    try {
      final Map<String, Object?> updates = {};
      if (currentDisliked) {
        updates['dislikes'] = ServerValue.increment(-1);
        updates['dislikedBy/${_auth.currentUser?.uid}'] = null;
      }
      updates['likes'] =
          currentLiked ? ServerValue.increment(-1) : ServerValue.increment(1);
      updates['likedBy/${_auth.currentUser?.uid}'] = currentLiked ? null : true;
      await _database.child(questionId).update(updates);
    } catch (e) {
      debugPrint('Error toggling like: $e');
      _showErrorSnackbar('Failed to update like');
    }
  }

  Future<void> _toggleDislike(String questionId, bool currentDisliked,
      int currentDislikes, bool currentLiked) async {
    if (_auth.currentUser == null) return;

    try {
      final Map<String, Object?> updates = {};
      if (currentLiked) {
        updates['likes'] = ServerValue.increment(-1);
        updates['likedBy/${_auth.currentUser?.uid}'] = null;
      }
      updates['dislikes'] = currentDisliked
          ? ServerValue.increment(-1)
          : ServerValue.increment(1);
      updates['dislikedBy/${_auth.currentUser?.uid}'] =
          currentDisliked ? null : true;
      await _database.child(questionId).update(updates);
    } catch (e) {
      debugPrint('Error toggling dislike: $e');
      _showErrorSnackbar('Failed to update dislike');
    }
  }

  Future<void> _postQuestion() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorSnackbar('Please sign in to post a question');
      return;
    }

    final title = _questionTitleController.text.trim();
    final description = _questionDescriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      _showErrorSnackbar('Please fill out all fields');
      return;
    }

    setState(() => _isPosting = true);
    try {
      final newQuestionRef = _database.push();
      await newQuestionRef.set({
        'author': user.email ?? user.uid,
        'title': title,
        'description': description,
        'timestamp': ServerValue.timestamp,
        'likes': 0,
        'dislikes': 0,
        'comments': 0,
        'views': 0,
        'authorId': user.uid,
      });
      _questionTitleController.clear();
      _questionDescriptionController.clear();
      _showSuccessSnackbar('Question posted successfully!');

      if (_selectedFilter == 'Most Recent') {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error posting question: $e');
      _showErrorSnackbar('Failed to post question');
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _reportQuestion(String questionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorSnackbar('Please sign in to report a question');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final reportsRef = FirebaseDatabase.instance.ref('reported_questions');
      final reportData = {
        'questionId': questionId,
        'reportedBy': user.uid,
        'reportedAt': ServerValue.timestamp,
        'status': 'pending',
      };
      await reportsRef.push().set(reportData);
      _showSuccessSnackbar('Question reported successfully!');
    } catch (e) {
      debugPrint('Error reporting question: $e');
      _showErrorSnackbar('Failed to report question');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    try {
      await _database.child(questionId).remove();
      _showSuccessSnackbar('Question deleted');
    } catch (e) {
      debugPrint('Error deleting question: $e');
      _showErrorSnackbar('Failed to delete question');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF58CC02),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return PopupMenuButton<String>(
      onSelected: (filter) {
        setState(() => _selectedFilter = filter);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Most Recent', child: Text('Most Recent')),
        const PopupMenuItem(value: 'Oldest', child: Text('Oldest')),
        const PopupMenuItem(value: 'Most Likes', child: Text('Most Likes')),
        const PopupMenuItem(
            value: 'Most Dislikes', child: Text('Most Dislikes')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _selectedFilter,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    return StreamBuilder<DatabaseEvent>(
      stream: getQuestionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF58CC02)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
              child: Text('No questions yet', style: TextStyle(fontSize: 18)));
        }

        final dynamic data = snapshot.data!.snapshot.value;
        if (data is! Map) {
          return const Center(child: Text('Invalid data format'));
        }

        final questions = <String, dynamic>{};
        (data).forEach((key, value) {
          questions[key.toString()] =
              value is Map<dynamic, dynamic> ? _convertMap(value) : value;
        });

        final questionsList = questions.entries.toList();
        if (_selectedFilter == 'Most Recent' ||
            _selectedFilter == 'Most Likes' ||
            _selectedFilter == 'Most Dislikes') {
          questionsList.sort((a, b) {
            final aValue = _selectedFilter == 'Most Recent'
                ? a.value['timestamp'] ?? 0
                : _selectedFilter == 'Most Likes'
                    ? a.value['likes'] ?? 0
                    : a.value['dislikes'] ?? 0;
            final bValue = _selectedFilter == 'Most Recent'
                ? b.value['timestamp'] ?? 0
                : _selectedFilter == 'Most Likes'
                    ? b.value['likes'] ?? 0
                    : b.value['dislikes'] ?? 0;
            return bValue.compareTo(aValue);
          });
        } else {
          questionsList.sort((a, b) {
            final aValue = a.value['timestamp'] ?? 0;
            final bValue = b.value['timestamp'] ?? 0;
            return aValue.compareTo(bValue);
          });
        }

        return ListView.builder(
          controller: _scrollController,
          padding:
              const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
          itemCount: questionsList.length,
          itemBuilder: (context, index) {
            final questionId = questionsList[index].key;
            final question = questionsList[index].value;
            return _buildQuestionCard(questionId, question);
          },
        );
      },
    );
  }

  Widget _buildQuestionCard(String questionId, Map<String, dynamic> question) {
    final userId = _auth.currentUser?.uid;
    final likedBy = question['likedBy'] is Map
        ? _convertMap(question['likedBy'])
        : <String, dynamic>{};
    final dislikedBy = question['dislikedBy'] is Map
        ? _convertMap(question['dislikedBy'])
        : <String, dynamic>{};
    final hasLiked = likedBy[userId] == true;
    final hasDisliked = dislikedBy[userId] == true;
    final isAuthor = userId != null && question['authorId'] == userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          _incrementViews(questionId, (question['views'] ?? 0) as int);
          _navigateToDiscussion(questionId);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionHeader(question, questionId, isAuthor),
              const SizedBox(height: 12),
              Text(
                question['title'] ?? 'No Title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                question['description'] ?? 'No Description',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuestionFooter(questionId, question, hasLiked, hasDisliked),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(
      Map<String, dynamic> question, String questionId, bool isAuthor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF1CB0F6),
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question['author'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                _formatTimestamp(question['timestamp']),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) =>
              _handleQuestionAction(value, questionId, isAuthor),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'report', child: Text('Report')),
            if (isAuthor)
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          icon: const Icon(Icons.more_vert, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildQuestionFooter(String questionId, Map<String, dynamic> question,
      bool hasLiked, bool hasDisliked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  key: ValueKey(hasLiked),
                  size: 24,
                  color: hasLiked ? const Color(0xFF58CC02) : Colors.grey,
                ),
              ),
              onPressed: () => _toggleLike(questionId, hasLiked,
                  (question['likes'] ?? 0) as int, hasDisliked),
            ),
            Text(
              '${question['likes'] ?? 0}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  hasDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                  key: ValueKey(hasDisliked),
                  size: 24,
                  color: hasDisliked ? Colors.redAccent : Colors.grey,
                ),
              ),
              onPressed: () => _toggleDislike(questionId, hasDisliked,
                  (question['dislikes'] ?? 0) as int, hasLiked),
            ),
            Text(
              '${question['dislikes'] ?? 0}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.comment, size: 24, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${question['comments'] ?? 0}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.visibility, size: 24, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${question['views'] ?? 0}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostQuestionButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ElevatedButton.icon(
        onPressed: _showQuestionDialog,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Ask a Question',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1CB0F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF58CC02)),
      ),
    );
  }

  void _showQuestionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Ask a Question',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _questionTitleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isPosting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _isPosting
                      ? null
                      : () async {
                          setState(() => _isPosting = true);
                          await _postQuestion();
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Post',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToDiscussion(String questionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DiscussionScreen(questionId: questionId)),
    );
  }

  void _handleQuestionAction(String value, String questionId, bool isAuthor) {
    switch (value) {
      case 'report':
        _reportQuestion(questionId);
        break;
      case 'delete':
        if (isAuthor) _deleteQuestion(questionId);
        break;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.7),
                Colors.teal.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Community'),
        actions: [
          _buildFilterDropdown(),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.teal.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: _buildQuestionsList(),
          ),
          _buildPostQuestionButton(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}
