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

  Future<void> _openComposer() async {
    final content = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _CommunityComposerScreen(),
      ),
    );
    if (content == null || content.trim().isEmpty) return;

    try {
      await ApiService.post('/community/posts', {'content': content.trim()});
      await _loadPosts();
      if (!mounted) return;
      AppToast.success(context, '帖子发布成功');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openDetail(Map<String, dynamic> post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _CommunityPostDetailScreen(post: post)),
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

  String _roleText(String raw) {
    switch (raw) {
      case 'DOCTOR':
        return '医生';
      case 'FAMILY':
        return '家属';
      case 'ADMIN':
        return '管理员';
      default:
        return '病友';
    }
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4375C8),
                            Color(0xFF6A99E5),
                            Color(0xFF99B7F3),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x224677C8),
                            blurRadius: 26,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '病友社区',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '分享控糖经验、交流饮食与运动心得，让每天的管理不再是一个人面对。',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassActionButton(
                            icon: Icons.edit_rounded,
                            label: '发布新帖子',
                            onTap: _openComposer,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const FrostPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle(
                            title: '最新讨论',
                            subtitle: '从饮食、血糖、运动到心态调整，大家都可以在这里继续聊。',
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
                              GlassActionButton(
                                icon: Icons.rate_review_rounded,
                                label: '发布第一条帖子',
                                onTap: _openComposer,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._posts.map((post) {
                        final author = '${post['authorName'] ?? '病友'}';
                        final role = _roleText(
                          '${post['authorRole'] ?? 'PATIENT'}',
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FrostPanel(
                            child: InkWell(
                              onTap: () => _openDetail(post),
                              borderRadius: BorderRadius.circular(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                      const Icon(Icons.chevron_right_rounded),
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
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      SoftStatPill(
                                        text: '评论 ${post['commentCount'] ?? 0}',
                                        bg: const Color(0xFFEAF1FF),
                                        fg: const Color(0xFF355EA0),
                                      ),
                                      const SoftStatPill(text: '点开查看详情'),
                                    ],
                                  ),
                                ],
                              ),
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

class _CommunityComposerScreen extends StatefulWidget {
  const _CommunityComposerScreen();

  @override
  State<_CommunityComposerScreen> createState() =>
      _CommunityComposerScreenState();
}

class _CommunityComposerScreenState extends State<_CommunityComposerScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发布帖子')),
      body: HealthPageBackground(
        topTint: const Color(0xFFDCEFFC),
        bottomTint: const Color(0xFFF6F8FB),
        accent: const Color(0xFFFFE8D8),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const FrostPanel(
              child: SectionTitle(
                title: '写点什么',
                subtitle: '可以分享饮食经验、控糖心得、运动感受，也可以向其他病友请教问题。',
              ),
            ),
            const SizedBox(height: 12),
            FrostPanel(
              child: TextField(
                controller: _controller,
                maxLines: 10,
                minLines: 8,
                decoration: const InputDecoration(
                  hintText: '例如：今天早餐我把白米饭换成了燕麦和鸡蛋，餐后感觉稳定很多…',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final content = _controller.text.trim();
                if (content.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('帖子内容不能为空')));
                  return;
                }
                Navigator.of(context).pop(content);
              },
              child: const Text('确认发布'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPostDetailScreen extends StatefulWidget {
  const _CommunityPostDetailScreen({required this.post});

  final Map<String, dynamic> post;

  @override
  State<_CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends State<_CommunityPostDetailScreen> {
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
      final list = _extractList(res).map(_asMap).toList();
      if (!mounted) return;
      setState(() {
        _comments = list;
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
      FocusScope.of(context).unfocus();
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

  String _roleText(String raw) {
    switch (raw) {
      case 'DOCTOR':
        return '医生';
      case 'FAMILY':
        return '家属';
      case 'ADMIN':
        return '管理员';
      default:
        return '病友';
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = '${widget.post['authorName'] ?? '病友'}';
    final role = _roleText('${widget.post['authorRole'] ?? 'PATIENT'}');
    return Scaffold(
      appBar: AppBar(title: const Text('讨论详情')),
      body: HealthPageBackground(
        topTint: const Color(0xFFDCEFFC),
        bottomTint: const Color(0xFFF6F8FB),
        accent: const Color(0xFFFFE8D8),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                children: [
                  FrostPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          '$role · ${_fmtTime(widget.post['createdAt'])}',
                          style: const TextStyle(color: Color(0xFF6D8481)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${widget.post['content'] ?? ''}',
                          style: const TextStyle(height: 1.5, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FrostPanel(
                    child: SectionTitle(
                      title: '评论区',
                      subtitle: '大家可以继续在这里跟帖讨论。',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    const FrostPanel(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('还没有评论，来聊聊吧')),
                      ),
                    )
                  else
                    ..._comments.map((comment) {
                      final cAuthor = '${comment['authorName'] ?? '病友'}';
                      final cRole = _roleText(
                        '${comment['authorRole'] ?? 'PATIENT'}',
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FrostPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cAuthor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$cRole · ${_fmtTime(comment['createdAt'])}',
                                style: const TextStyle(
                                  color: Color(0xFF6D8481),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('${comment['content'] ?? ''}'),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: const InputDecoration(hintText: '写下你的评论'),
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
            ),
          ],
        ),
      ),
    );
  }
}
