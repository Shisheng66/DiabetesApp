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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openDetail(Map<String, dynamic> post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailScreen(post: post),
      ),
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
        return DateFormat('MM月dd日 HH:mm').format(dt.toLocal());
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

  Color _roleColor(String raw) {
    switch (raw) {
      case 'DOCTOR':
        return const Color(0xFF2B6CB0);
      case 'FAMILY':
        return const Color(0xFF276749);
      case 'ADMIN':
        return const Color(0xFF744210);
      default:
        return const Color(0xFF4A5568);
    }
  }

  Color _roleBg(String raw) {
    switch (raw) {
      case 'DOCTOR':
        return const Color(0xFFEBF8FF);
      case 'FAMILY':
        return const Color(0xFFF0FFF4);
      case 'ADMIN':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFEDF2F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('病友社区'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadPosts,
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDCEFFC), Color(0xFFF6F8FB), Color(0xFFFFE8D8)],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: FrostPanel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.forum_outlined, size: 42, color: Color(0xFFC53A2E)),
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: Color(0xFFC53A2E))),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _loadPosts, child: const Text('重试')),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPosts,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                      children: [
                        // 顶部横幅
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4375C8), Color(0xFF6A99E5), Color(0xFF99B7F3)],
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
                                '分享控糖经验、交流饮食与运动心得，\n让每天的管理不再是一个人面对。',
                                style: TextStyle(color: Colors.white70, height: 1.45),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _statBadge('帖子', '${_posts.length}'),
                                  const SizedBox(width: 10),
                                  GlassActionButton(
                                    icon: Icons.edit_rounded,
                                    label: '发布新帖子',
                                    onTap: _openComposer,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // 最新讨论标题
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
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Column(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF1FF),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: const Icon(Icons.forum_outlined, color: Color(0xFF4375C8), size: 36),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    '还没有帖子',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    '来发第一条帖子，开启社区讨论吧',
                                    style: TextStyle(color: Color(0xFF5A7673)),
                                  ),
                                  const SizedBox(height: 16),
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
                            final authorName = '${post['authorName'] ?? '匿名用户'}';
                            final roleKey = '${post['authorRole'] ?? 'PATIENT'}';
                            final role = _roleText(roleKey);
                            final roleColor = _roleColor(roleKey);
                            final roleBg = _roleBg(roleKey);
                            final content = '${post['content'] ?? ''}';
                            final commentCount = post['commentCount'] ?? 0;
                            final preview = content.length > 80
                                ? '${content.substring(0, 80)}…'
                                : content;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: FrostPanel(
                                child: InkWell(
                                  onTap: () => _openDetail(post),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 作者行
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(0xFFEAF1FF),
                                            child: Text(
                                              authorName.isEmpty ? '?' : authorName.characters.first,
                                              style: const TextStyle(
                                                color: Color(0xFF4375C8),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  authorName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF1A202C),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: roleBg,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        role,
                                                        style: TextStyle(
                                                          color: roleColor,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      _fmtTime(post['createdAt']),
                                                      style: const TextStyle(
                                                        color: Color(0xFF718096),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // 内容预览
                                      Text(
                                        preview,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.55,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // 底部操作栏
                                      Row(
                                        children: [
                                          const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF718096)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$commentCount 条评论',
                                            style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAF1FF),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              '查看详情 →',
                                              style: TextStyle(
                                                color: Color(0xFF4375C8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
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

  Widget _statBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 发帖页
// ─────────────────────────────────────────────────────────────
class _CommunityComposerScreen extends StatefulWidget {
  const _CommunityComposerScreen();

  @override
  State<_CommunityComposerScreen> createState() => _CommunityComposerScreenState();
}

class _CommunityComposerScreenState extends State<_CommunityComposerScreen> {
  final TextEditingController _controller = TextEditingController();
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _charCount = _controller.text.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布帖子'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _charCount == 0
                  ? null
                  : () {
                      final content = _controller.text.trim();
                      if (content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('帖子内容不能为空')),
                        );
                        return;
                      }
                      Navigator.of(context).pop(content);
                    },
              style: FilledButton.styleFrom(minimumSize: const Size(64, 36)),
              child: const Text('发布'),
            ),
          ),
        ],
      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 12,
                    minLines: 8,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: '例如：今天早餐我把白米饭换成了燕麦和鸡蛋，餐后感觉稳定很多，分享给大家…',
                      border: InputBorder.none,
                      filled: false,
                      counterText: '',
                    ),
                  ),
                  Text(
                    '$_charCount / 500',
                    style: TextStyle(
                      fontSize: 12,
                      color: _charCount > 480 ? const Color(0xFFC53A2E) : const Color(0xFF9AA8A6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 话题提示
            FrostPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '可以聊的话题',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2D3748), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '饮食控糖经验',
                      '运动心得',
                      '用药建议',
                      '血糖监测技巧',
                      '心态调整',
                      '求助提问',
                    ].map((tag) => InkWell(
                      onTap: () {
                        final text = _controller.text;
                        _controller.text = text.isEmpty ? '#$tag ' : '$text #$tag ';
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '# $tag',
                          style: const TextStyle(
                            color: Color(0xFF4375C8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )).toList(),
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

// ─────────────────────────────────────────────────────────────
// 帖子详情页（完整 UI）
// ─────────────────────────────────────────────────────────────
class CommunityPostDetailScreen extends StatefulWidget {
  const CommunityPostDetailScreen({super.key, required this.post});

  final Map<String, dynamic> post;

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
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
      _focusNode.unfocus();
      await _loadComments();
      if (!mounted) return;
      AppToast.success(context, '评论已发送');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        return DateFormat('yyyy年MM月dd日 HH:mm').format(dt.toLocal());
      }
    }
    return '--';
  }

  String _fmtShort(dynamic value) {
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) {
        return DateFormat('MM月dd日 HH:mm').format(dt.toLocal());
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

  Color _roleColor(String raw) {
    switch (raw) {
      case 'DOCTOR':
        return const Color(0xFF2B6CB0);
      case 'FAMILY':
        return const Color(0xFF276749);
      case 'ADMIN':
        return const Color(0xFF744210);
      default:
        return const Color(0xFF4A5568);
    }
  }

  Color _roleBg(String raw) {
    switch (raw) {
      case 'DOCTOR':
        return const Color(0xFFEBF8FF);
      case 'FAMILY':
        return const Color(0xFFF0FFF4);
      case 'ADMIN':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFEDF2F7);
    }
  }

  Color _avatarBg(String raw) {
    switch (raw) {
      case 'DOCTOR':
        return const Color(0xFFBEE3F8);
      case 'FAMILY':
        return const Color(0xFFC6F6D5);
      case 'ADMIN':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authorName = '${widget.post['authorName'] ?? '匿名用户'}';
    final roleKey = '${widget.post['authorRole'] ?? 'PATIENT'}';
    final role = _roleText(roleKey);
    final roleColor = _roleColor(roleKey);
    final roleBg = _roleBg(roleKey);
    final avatarBg = _avatarBg(roleKey);
    final content = '${widget.post['content'] ?? ''}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('讨论详情'),
        centerTitle: true,
      ),
      body: HealthPageBackground(
        topTint: const Color(0xFFDCEFFC),
        bottomTint: const Color(0xFFF6F8FB),
        accent: const Color(0xFFFFE8D8),
        child: Column(
          children: [
            // ── 帖子内容 + 评论列表 ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                children: [
                  // 帖子主体卡片
                  FrostPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 作者信息
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: avatarBg,
                              child: Text(
                                authorName.isEmpty ? '?' : authorName.characters.first,
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF1A202C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: roleBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          role,
                                          style: TextStyle(
                                            color: roleColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _fmtTime(widget.post['createdAt']),
                                        style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 分割线
                        Container(
                          height: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(height: 16),
                        // 正文
                        SelectableText(
                          content,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.75,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 底部统计
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF718096)),
                            const SizedBox(width: 4),
                            Text(
                              '${_comments.length} 条评论',
                              style: const TextStyle(color: Color(0xFF718096), fontSize: 13),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _focusNode.requestFocus(),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF1FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4375C8)),
                                    SizedBox(width: 4),
                                    Text(
                                      '写评论',
                                      style: TextStyle(
                                        color: Color(0xFF4375C8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 评论区标题
                  Row(
                    children: [
                      const Icon(Icons.forum_rounded, size: 18, color: Color(0xFF4375C8)),
                      const SizedBox(width: 6),
                      Text(
                        '评论区 (${_comments.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 评论列表
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_comments.isEmpty)
                    FrostPanel(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF1FF),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Color(0xFF4375C8),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '还没有评论',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '来第一个发表评论吧',
                              style: TextStyle(color: Color(0xFF718096), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._comments.asMap().entries.map((entry) {
                      final i = entry.key;
                      final comment = entry.value;
                      final cAuthorName = '${comment['authorName'] ?? '匿名用户'}';
                      final cRoleKey = '${comment['authorRole'] ?? 'PATIENT'}';
                      final cRole = _roleText(cRoleKey);
                      final cRoleColor = _roleColor(cRoleKey);
                      final cRoleBg = _roleBg(cRoleKey);
                      final cAvatarBg = _avatarBg(cRoleKey);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FrostPanel(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 楼层序号 + 头像
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: cAvatarBg,
                                    child: Text(
                                      cAuthorName.isEmpty ? '?' : cAuthorName.characters.first,
                                      style: TextStyle(
                                        color: cRoleColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '#${i + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          cAuthorName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF1A202C),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: cRoleBg,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            cRole,
                                            style: TextStyle(
                                              color: cRoleColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${comment['content'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.55,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _fmtShort(comment['createdAt']),
                                      style: const TextStyle(
                                        color: Color(0xFF9AA8A6),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── 底部评论输入栏 ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.of(context).viewInsets.bottom > 0
                    ? MediaQuery.of(context).viewInsets.bottom + 10
                    : MediaQuery.of(context).padding.bottom + 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '写下你的看法或建议…',
                          hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          filled: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: FilledButton(
                      onPressed: _saving ? null : _sendComment,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(52, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        backgroundColor: const Color(0xFF4375C8),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
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
