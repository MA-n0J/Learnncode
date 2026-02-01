import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnncode/screens/level/widgets/navigation_bar_widget.dart';

class DiscussionScreen extends StatefulWidget {
  final String questionId;

  const DiscussionScreen({super.key, required this.questionId});

  @override
  _DiscussionScreenState createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? replyingToId;

  @override
  void dispose() {
    _answerController.dispose();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  DatabaseReference getQuestionRef() {
    return _database.child('questions').child(widget.questionId);
  }

  Future<void> postAnswer() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to post an answer')),
      );
      return;
    }
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer')),
      );
      return;
    }

    try {
      final answerId = DateTime.now().millisecondsSinceEpoch.toString();
      final answerRef = getQuestionRef().child('answers').child(answerId);

      await answerRef.set({
        'id': answerId,
        'author': user.email ?? user.uid,
        'text': _answerController.text.trim(),
        'time': ServerValue.timestamp,
        'likes': 0,
        'dislikes': 0,
        'likedBy': <String, bool>{},
        'dislikedBy': <String, bool>{},
      });

      await getQuestionRef().child('comments').set(ServerValue.increment(1));

      _answerController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post answer: ${e.toString()}')),
      );
    }
  }

  Future<void> postReply(String parentId, bool isTopLevel) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to post a reply')),
      );
      return;
    }

    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply')),
      );
      return;
    }

    try {
      final replyId = DateTime.now().millisecondsSinceEpoch.toString();
      final replyPath = isTopLevel
          ? 'questions/${widget.questionId}/answers/$parentId/replies/$replyId'
          : 'questions/${widget.questionId}/answers/${parentId.split('-')[0]}/replies/$parentId/replies/$replyId';

      await _database.child(replyPath).set({
        'id': replyId,
        'author': user.email ?? user.uid,
        'text': _replyController.text.trim(),
        'time': ServerValue.timestamp,
        'likes': 0,
        'dislikes': 0,
        'likedBy': <String, bool>{},
        'dislikedBy': <String, bool>{},
      });

      if (isTopLevel) {
        await getQuestionRef().child('comments').set(ServerValue.increment(1));
      }

      _replyController.clear();
      setState(() => replyingToId = null);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post reply: ${e.toString()}')),
      );
    }
  }

  Future<void> toggleLike(
      String id, bool isTopLevel, bool currentLiked, int currentLikes) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to react')),
      );
      return;
    }

    try {
      final path = isTopLevel
          ? 'questions/${widget.questionId}/answers/$id'
          : 'questions/${widget.questionId}/answers/${id.split('-')[0]}/replies/$id';

      final snapshot = await _database.child(path).get();
      final hasDisliked =
          (snapshot.child('dislikedBy').value as Map?)?[userId] ?? false;

      final Map<String, Object?> updates = {};

      if (hasDisliked) {
        updates['$path/dislikedBy/$userId'] = null;
        updates['$path/dislikes'] = ServerValue.increment(-1);
      }

      updates['$path/likedBy/$userId'] = currentLiked ? null : true;
      updates['$path/likes'] =
          currentLiked ? ServerValue.increment(-1) : ServerValue.increment(1);

      await _database.update(updates);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: ${e.toString()}')),
      );
    }
  }

  Future<void> toggleDislike(String id, bool isTopLevel, bool currentDisliked,
      int currentDislikes) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to react')),
      );
      return;
    }

    try {
      final path = isTopLevel
          ? 'questions/${widget.questionId}/answers/$id'
          : 'questions/${widget.questionId}/answers/${id.split('-')[0]}/replies/$id';

      final snapshot = await _database.child(path).get();
      final hasLiked =
          (snapshot.child('likedBy').value as Map?)?[userId] ?? false;

      final Map<String, Object?> updates = {};

      if (hasLiked) {
        updates['$path/likedBy/$userId'] = null;
        updates['$path/likes'] = ServerValue.increment(-1);
      }

      updates['$path/dislikedBy/$userId'] = currentDisliked ? null : true;
      updates['$path/dislikes'] = currentDisliked
          ? ServerValue.increment(-1)
          : ServerValue.increment(1);

      await _database.update(updates);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update dislike: ${e.toString()}')),
      );
    }
  }

  Future<void> deleteAnswer(String answerId, bool isTopLevel) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final path = isTopLevel
          ? 'questions/${widget.questionId}/answers/$answerId'
          : 'questions/${widget.questionId}/answers/${answerId.split('-')[0]}/replies/$answerId';

      final snapshot = await _database.child(path).get();
      if (!snapshot.exists) return;

      final author = snapshot.child('author').value.toString();
      if (author == user.email || author == user.uid) {
        await _database.child(path).remove();
        if (isTopLevel) {
          await getQuestionRef()
              .child('comments')
              .set(ServerValue.increment(-1));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only delete your own content')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Comments', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildQuestionCard(),
                    const SizedBox(height: 16),
                    _buildAnswerSection(),
                    const SizedBox(height: 16),
                    StreamBuilder<DatabaseEvent>(
                      stream: getQuestionRef()
                          .child('answers')
                          .orderByChild('time')
                          .onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.snapshot.value == null) {
                          return const Text('No answers yet');
                        }

                        final answersMap = snapshot.data!.snapshot.value
                                as Map<dynamic, dynamic>? ??
                            {};
                        final answers = answersMap.entries.toList()
                          ..sort((a, b) => ((a.value as Map)['time'] ?? 0)
                              .compareTo((b.value as Map)['time'] ?? 0));

                        return Column(
                          children: answers.map((entry) {
                            final answer = entry.value as Map<dynamic, dynamic>;
                            final likedBy =
                                answer['likedBy'] as Map<dynamic, dynamic>? ??
                                    {};
                            final dislikedBy = answer['dislikedBy']
                                    as Map<dynamic, dynamic>? ??
                                {};
                            return _buildCommentCard(
                              answerId: answer['id']?.toString() ??
                                  entry.key.toString(),
                              author:
                                  answer['author']?.toString() ?? 'Anonymous',
                              timeAgo: _formatTimeAgo(answer['time']),
                              text: answer['text']?.toString() ?? '',
                              likes: (answer['likes'] ?? 0).toInt(),
                              dislikes: (answer['dislikes'] ?? 0).toInt(),
                              hasLiked: _auth.currentUser?.uid != null
                                  ? likedBy.containsKey(_auth.currentUser!.uid)
                                  : false,
                              hasDisliked: _auth.currentUser?.uid != null
                                  ? dislikedBy
                                      .containsKey(_auth.currentUser!.uid)
                                  : false,
                              level: 0,
                              isTopLevel: true,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const NavigationBarWidget(currentIndex: 1),
    );
  }

  Widget _buildQuestionCard() {
    return StreamBuilder<DatabaseEvent>(
      stream: getQuestionRef().onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
          return const Text('Question not found');
        }

        final data =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title']?.toString() ?? 'No title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['description']?.toString() ?? 'No description',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _answerController,
                    decoration: InputDecoration(
                      hintText: 'Add your answer...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _answerController.clear(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: postAnswer,
                  child: const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard({
    required String answerId,
    required String author,
    required String timeAgo,
    required String text,
    required int likes,
    required int dislikes,
    required bool hasLiked,
    required bool hasDisliked,
    required int level,
    required bool isTopLevel,
  }) {
    final isOwnAnswer =
        _auth.currentUser?.email == author || _auth.currentUser?.uid == author;
    final fullId = isTopLevel ? answerId : '$answerId-$level';

    return Padding(
      padding: EdgeInsets.only(left: level * 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                          radius: 16, child: Icon(Icons.person, size: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          author,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isOwnAnswer)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              deleteAnswer(answerId, isTopLevel);
                            } else if (value == 'reply') {
                              setState(() => replyingToId = fullId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'reply', child: Text('Reply')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                hasLiked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                key: ValueKey(hasLiked),
                                color: hasLiked ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                            ),
                            onPressed: () => toggleLike(
                                answerId, isTopLevel, hasLiked, likes),
                          ),
                          Text('$likes', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                hasDisliked
                                    ? Icons.thumb_down
                                    : Icons.thumb_down_outlined,
                                key: ValueKey(hasDisliked),
                                color: hasDisliked ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                            ),
                            onPressed: () => toggleDislike(
                                answerId, isTopLevel, hasDisliked, dislikes),
                          ),
                          Text('$dislikes',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(timeAgo,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (replyingToId == fullId)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                          radius: 16, child: Icon(Icons.person, size: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: InputDecoration(
                            hintText: 'Write a reply...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (replyingToId == fullId)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => replyingToId = null);
                      _replyController.clear();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => postReply(fullId, isTopLevel),
                    child: const Text('Post'),
                  ),
                ],
              ),
            ),
          StreamBuilder<DatabaseEvent>(
            stream: _database
                .child(
                    'questions/${widget.questionId}/answers/$answerId/replies')
                .orderByChild('time')
                .onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.snapshot.value == null) {
                return const SizedBox.shrink();
              }

              final repliesMap =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
              final replies = repliesMap.entries.toList()
                ..sort((a, b) => ((a.value as Map)['time'] ?? 0)
                    .compareTo((b.value as Map)['time'] ?? 0));

              return Column(
                children: replies.map((entry) {
                  final reply = entry.value as Map<dynamic, dynamic>;
                  final likedBy =
                      reply['likedBy'] as Map<dynamic, dynamic>? ?? {};
                  final dislikedBy =
                      reply['dislikedBy'] as Map<dynamic, dynamic>? ?? {};
                  final replyId =
                      reply['id']?.toString() ?? entry.key.toString();
                  return _buildCommentCard(
                    answerId: '$answerId-$replyId',
                    author: reply['author']?.toString() ?? 'Anonymous',
                    timeAgo: _formatTimeAgo(reply['time']),
                    text: reply['text']?.toString() ?? '',
                    likes: (reply['likes'] ?? 0).toInt(),
                    dislikes: (reply['dislikes'] ?? 0).toInt(),
                    hasLiked: _auth.currentUser?.uid != null
                        ? likedBy.containsKey(_auth.currentUser!.uid)
                        : false,
                    hasDisliked: _auth.currentUser?.uid != null
                        ? dislikedBy.containsKey(_auth.currentUser!.uid)
                        : false,
                    level: level + 1,
                    isTopLevel: false,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
