import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/premium_health_ui.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _loading = true;
  bool _publishing = false;
  String? _error;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get(
        '/community/posts',
        query: {'page': '0', 'size': '20'},
      );
      if (!mounted) return;
      setState(() {
        _posts = _extractList(res).map(_asMap).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '社区内容加载失败';
        _loading = false;
      });
    }
  }

  Future<void> _createPost() async {
    final ctrl = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '发布新帖子',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '分享今天的控糖经验、饮食搭配或运动感受…',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          FocusScope.of(ctx).unfocus();
                          Navigator.of(
                            ctx,
                            rootNavigator: true,
                          ).pop(ctrl.text.trim());
                        },
                        child: const Text('发布'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.dispose();
    });
    if (content == null || content.isEmpty) return;

    setState(() => _publishing = true);
    try {
      await ApiService.post('/community/posts', {'content': content});
      await _loadPosts();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppToast.success(context, '帖子发布成功');
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _openComments(Map<String, dynamic> post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CommentSheet(post: post),
    );
    await _loadPosts();
  }

  List<dynamic> _extractList(Map<String, dynamic> res) {
    if (res['content'] is List) return res['content'] as List;
    if (res['data'] is List) return res['data'] as List;
    final data = res['data'];
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List;
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    return const <String, dynamic>{};
  }

  String _fmtTime(dynamic value) {
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) {
        return DateFormat('MM-dd HH:mm').format(dt.toLocal());
      }
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社区'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadPosts,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: GlassActionButton(
          onTap: _publishing ? null : _createPost,
          icon: Icons.edit_rounded,
          label: '发帖',
        ),
      ),
      body: HealthPageBackground(
        topTint: const Color(0xFFDCEFFC),
        bottomTint: const Color(0xFFF6F8FB),
        accent: const Color(0xFFFFE8D8),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: FrostPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 42,
                        color: Color(0xFFC53A2E),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFC53A2E)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadPosts,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadPosts,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4677C8),
                            Color(0xFF6A98E5),
                            Color(0xFF97B8F3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x224677C8),
                            blurRadius: 28,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '病友社区',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '分享控糖经验、交流饮食和运动心得，让每天的管理不再是一个人面对。',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FrostPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle(
                            title: '社区动态',
                            subtitle: '可以发帖，也可以在评论区继续讨论。',
                            trailing: SurfaceButton(
                              icon: Icons.edit_rounded,
                              label: '立即发帖',
                              onTap: _publishing ? () {} : _createPost,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              SoftStatPill(text: '经验分享'),
                              SoftStatPill(
                                text: '饮食交流',
                                bg: Color(0xFFFFF1E8),
                                fg: Color(0xFF7A4C2C),
                              ),
                              SoftStatPill(
                                text: '运动互助',
                                bg: Color(0xFFEAF1FF),
                                fg: Color(0xFF355EA0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_posts.isEmpty)
                      FrostPanel(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              const Text(
                                '还没有帖子，来发第一条吧',
                                style: TextStyle(color: Color(0xFF5A7673)),
                              ),
                              const SizedBox(height: 14),
                              SurfaceButton(
                                icon: Icons.rate_review_rounded,
                                label: '发布第一条帖子',
                                onTap: _publishing ? () {} : _createPost,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._posts.map((post) {
                        final author = '${post['authorName'] ?? '病友'}';
                        final role = '${post['authorRole'] ?? 'PATIENT'}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FrostPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: const Color(0xFFEAF1FF),
                                      ),
                                      child: const Icon(
                                        Icons.forum_rounded,
                                        color: Color(0xFF4677C8),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            author,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF173836),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$role · ${_fmtTime(post['createdAt'])}',
                                            style: const TextStyle(
                                              color: Color(0xFF6D8481),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '${post['content'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.45,
                                    color: Color(0xFF203A38),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    SoftStatPill(
                                      text: '评论 ${post['commentCount'] ?? 0}',
                                      bg: const Color(0xFFEAF1FF),
                                      fg: const Color(0xFF355EA0),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => _openComments(post),
                                      icon: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                      ),
                                      label: const Text('进入讨论'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.post});

  final Map<String, dynamic> post;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final res = await ApiService.get(
        '/community/posts/${widget.post['id']}/comments',
        query: {'page': '0', 'size': '100'},
      );
      final list = res['content'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _comments = list.map((e) {
          if (e is Map<String, dynamic>) return e;
          if (e is Map) return e.map((k, v) => MapEntry('$k', v));
          return const <String, dynamic>{};
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService.post('/community/posts/${widget.post['id']}/comments', {
        'content': text,
      });
      _ctrl.clear();
      await _loadComments();
      if (!mounted) return;
      AppToast.success(context, '评论已发送');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmtTime(dynamic value) {
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) {
        return DateFormat('MM-dd HH:mm').format(dt.toLocal());
      }
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  Text(
                    '${widget.post['content'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('还没有评论，来聊聊吧')),
                    )
                  else
                    ..._comments.map((comment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FrostPanel(
                          radius: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${comment['authorName'] ?? '病友'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _fmtTime(comment['createdAt']),
                                style: const TextStyle(
                                  color: Color(0xFF6D8481),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${comment['content'] ?? ''}',
                                style: const TextStyle(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: '写下你的回复'),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saving ? null : _sendComment,
                    child: const Text('发送'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
