import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/premium_health_ui.dart';
import 'glucose_reminder_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Map<String, String> _reminderTypeNames = {
    'GLUCOSE_TEST': '测血糖提醒',
    'MEDICINE': '用药提醒',
    'EXERCISE': '运动提醒',
    'DIET': '饮食提醒',
  };

  static const Map<String, String> _repeatTypeNames = {
    'DAILY': '每天',
    'WORKDAY': '工作日',
    'CUSTOM': '自定义',
  };

  static const Map<String, String> _diabetesTypeNames = {
    'TYPE1': '一型',
    'TYPE2': '二型',
    'OTHER': '1.5型',
    'GESTATIONAL': '妊娠型',
  };

  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/users/me');
      if (!mounted) return;
      setState(() {
        _user = res;
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
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  void _applyLocalUserPatch({
    required String? nickname,
    required String? avatarUrl,
  }) {
    final current = Map<String, dynamic>.from(
      _user ?? const <String, dynamic>{},
    );
    current['nickname'] = nickname;
    current['avatarUrl'] = avatarUrl;

    final healthProfile = _asMap(current['healthProfile']);
    if (healthProfile.isNotEmpty || nickname != null || avatarUrl != null) {
      healthProfile['nickname'] = nickname;
      healthProfile['avatarUrl'] = avatarUrl;
      current['healthProfile'] = healthProfile;
    }

    setState(() {
      _user = current;
      _error = null;
      _loading = false;
    });
  }

  Future<void> _refreshUserSilently() async {
    try {
      final res = await ApiService.get('/users/me');
      if (!mounted) return;
      setState(() {
        _user = res;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      // Keep optimistic local state.
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value.map(_asMap).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String _diabetesTypeText(dynamic value) {
    final key = value?.toString();
    if (key == null || key.isEmpty) return '未设置';
    return _diabetesTypeNames[key] ?? key;
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确认退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _showEditMe() async {
    final user = _user ?? const <String, dynamic>{};
    final result = await Navigator.of(context).push<Map<String, String?>>(
      MaterialPageRoute(
        builder: (_) => _BasicProfileEditScreen(
          initialNickname: '${user['nickname'] ?? ''}',
          initialAvatarUrl: '${user['avatarUrl'] ?? ''}',
        ),
      ),
    );

    if (result == null) return;

    final nickname = result['nickname'];
    final avatarUrl = result['avatarUrl'];
    try {
      await ApiService.put('/users/me', {
        'nickname': nickname,
        'avatarUrl': avatarUrl,
      });
      if (!mounted) return;
      _applyLocalUserPatch(nickname: nickname, avatarUrl: avatarUrl);
      _refreshUserSilently();
      AppToast.success(context, '个人信息修改成功');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showEditHealthProfile() async {
    Map<String, dynamic> profile;
    try {
      profile = await ApiService.get('/users/me/health-profile');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!mounted) return;
    final heightCtrl = TextEditingController(
      text: '${profile['heightCm'] ?? ''}',
    );
    final weightCtrl = TextEditingController(
      text: '${profile['weightKg'] ?? ''}',
    );
    final medCtrl = TextEditingController(
      text: '${profile['medicationStatus'] ?? ''}',
    );
    final remarkCtrl = TextEditingController(
      text: '${profile['remark'] ?? ''}',
    );
    final fbgMinCtrl = TextEditingController(
      text: '${profile['targetFbgMin'] ?? ''}',
    );
    final fbgMaxCtrl = TextEditingController(
      text: '${profile['targetFbgMax'] ?? ''}',
    );
    final pbgMinCtrl = TextEditingController(
      text: '${profile['targetPbgMin'] ?? ''}',
    );
    final pbgMaxCtrl = TextEditingController(
      text: '${profile['targetPbgMax'] ?? ''}',
    );
    var gender = (profile['gender'] ?? 'UNKNOWN').toString();
    var diabetesType = switch ((profile['diabetesType'] ?? 'TYPE2')
        .toString()) {
      'TYPE1' => 'TYPE1',
      'TYPE2' => 'TYPE2',
      'OTHER' => 'OTHER',
      'GESTATIONAL' => 'GESTATIONAL',
      _ => 'TYPE2',
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '编辑健康档案',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: const InputDecoration(labelText: '性别'),
                      items: const [
                        DropdownMenuItem(value: 'MALE', child: Text('男')),
                        DropdownMenuItem(value: 'FEMALE', child: Text('女')),
                        DropdownMenuItem(value: 'UNKNOWN', child: Text('不透露')),
                      ],
                      onChanged: (v) => setModal(() => gender = v ?? gender),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '身高 cm',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '体重 kg',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: diabetesType,
                      decoration: const InputDecoration(labelText: '糖尿病类型'),
                      items: const [
                        DropdownMenuItem(value: 'TYPE1', child: Text('一型')),
                        DropdownMenuItem(value: 'TYPE2', child: Text('二型')),
                        DropdownMenuItem(value: 'OTHER', child: Text('1.5型')),
                        DropdownMenuItem(
                          value: 'GESTATIONAL',
                          child: Text('妊娠型'),
                        ),
                      ],
                      onChanged: (v) =>
                          setModal(() => diabetesType = v ?? diabetesType),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: medCtrl,
                      decoration: const InputDecoration(labelText: '用药情况'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fbgMinCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '空腹最低',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: fbgMaxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '空腹最高',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pbgMinCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '餐后最低',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: pbgMaxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '餐后最高',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: remarkCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: '备注'),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final body = <String, dynamic>{
                          'gender': gender,
                          'heightCm': int.tryParse(heightCtrl.text.trim()),
                          'weightKg': double.tryParse(weightCtrl.text.trim()),
                          'diabetesType': diabetesType,
                          'medicationStatus': medCtrl.text.trim().isEmpty
                              ? null
                              : medCtrl.text.trim(),
                          'targetFbgMin': double.tryParse(
                            fbgMinCtrl.text.trim(),
                          ),
                          'targetFbgMax': double.tryParse(
                            fbgMaxCtrl.text.trim(),
                          ),
                          'targetPbgMin': double.tryParse(
                            pbgMinCtrl.text.trim(),
                          ),
                          'targetPbgMax': double.tryParse(
                            pbgMaxCtrl.text.trim(),
                          ),
                          'remark': remarkCtrl.text.trim().isEmpty
                              ? null
                              : remarkCtrl.text.trim(),
                        };
                        body.removeWhere((_, v) => v == null);
                        try {
                          await ApiService.put(
                            '/users/me/health-profile',
                            body,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          await _load();
                          if (!mounted) return;
                          AppToast.success(context, '健康档案修改成功');
                        } on ApiException catch (e) {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      },
                      child: const Text('保存健康档案'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    heightCtrl.dispose();
    weightCtrl.dispose();
    medCtrl.dispose();
    remarkCtrl.dispose();
    fbgMinCtrl.dispose();
    fbgMaxCtrl.dispose();
    pbgMinCtrl.dispose();
    pbgMaxCtrl.dispose();
  }

  Future<void> _showHealthProfile() async {
    try {
      final profile = await ApiService.get('/users/me/health-profile');
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                '健康档案',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _infoRow('性别', profile['gender']),
              _infoRow(
                '身高',
                profile['heightCm'] == null
                    ? null
                    : '${profile['heightCm']} cm',
              ),
              _infoRow(
                '体重',
                profile['weightKg'] == null
                    ? null
                    : '${profile['weightKg']} kg',
              ),
              _infoRow('糖尿病类型', _diabetesTypeText(profile['diabetesType'])),
              _infoRow('用药情况', profile['medicationStatus']),
              _infoRow(
                '空腹目标',
                '${profile['targetFbgMin'] ?? '--'} ~ ${profile['targetFbgMax'] ?? '--'} mmol/L',
              ),
              _infoRow(
                '餐后目标',
                '${profile['targetPbgMin'] ?? '--'} ~ ${profile['targetPbgMax'] ?? '--'} mmol/L',
              ),
              _infoRow('备注', profile['remark']),
            ],
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showReminders() async {
    try {
      final res = await ApiService.get('/reminders');
      final list = <Map<String, dynamic>>[
        ..._asMapList(res['data']),
        if (res['content'] is List && (res['data'] is! List))
          ..._asMapList(res['content']),
      ];
      await NotificationService.syncFromReminderList(list);

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          if (list.isEmpty) {
            return const SizedBox(
              height: 220,
              child: Center(child: Text('当前没有提醒设置')),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final item = list[i];
              final enabled = item['enabled'] != false;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    _reminderTypeNames[item['type']?.toString()] ??
                        '${item['type'] ?? '提醒'}',
                  ),
                  subtitle: Text(
                    '${item['timeOfDay'] ?? '--:--'} · '
                    '${_repeatTypeNames[item['repeatType']?.toString()] ?? '每天'}'
                    '${item['remark']?.toString().isNotEmpty == true ? ' · ${item['remark']}' : ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        enabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: enabled
                            ? const Color(0xFF0B8A7D)
                            : const Color(0xFFA0A0A0),
                        size: 20,
                      ),
                      Text(
                        enabled ? '已开启' : '已关闭',
                        style: TextStyle(
                          fontSize: 10,
                          color: enabled
                              ? const Color(0xFF0B8A7D)
                              : const Color(0xFFA0A0A0),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showAbnormalEvents() async {
    try {
      final res = await ApiService.get(
        '/blood-glucose/abnormal-events',
        query: {'page': '0', 'size': '100'},
      );
      final list = _asMapList(res['content'] ?? res['data']);

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) {
          if (list.isEmpty) {
            return const SizedBox(
              height: 260,
              child: Center(child: Text('近期没有血糖异常事件记录')),
            );
          }
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            expand: false,
            builder: (_, ctrl) {
              return ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final item = list[i];
                  final isHigh = item['type'] == 'HIGH';
                  final color = isHigh
                      ? const Color(0xFFC53A2E)
                      : const Color(0xFFE08A22);
                  final label = isHigh ? '偏高' : '偏低';
                  final timeStr = item['createdAt'] is String
                      ? DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(DateTime.parse(item['createdAt']).toLocal())
                      : '--';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isHigh
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '血糖$label事件',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(timeStr),
                      trailing: item['handled'] == true
                          ? const Chip(
                              label: Text(
                                '已处理',
                                style: TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Color(0xFFE8F6F3),
                            )
                          : const Chip(
                              label: Text(
                                '未处理',
                                style: TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Color(0xFFFFF4F1),
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openGlucoseReminderSettings() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GlucoseReminderScreen()),
    );
    if (changed == true) {
      _load();
    }
  }

  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('修改密码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: '原密码'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: '新密码'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (newCtrl.text.trim().length < 6) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(const SnackBar(content: Text('新密码至少 6 位')));
                  return;
                }
                try {
                  await ApiService.put('/users/me/password', {
                    'oldPassword': oldCtrl.text,
                    'newPassword': newCtrl.text,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  AppToast.success(context, '密码修改成功');
                } on ApiException catch (e) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
              child: const Text('确认修改'),
            ),
          ],
        );
      },
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FrostPanel(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0B8A7D).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0B8A7D)),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF173836),
            ),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }

  Widget _headerCard() {
    final user = _user ?? const <String, dynamic>{};
    final name = (user['nickname'] ?? user['phone'] ?? '用户').toString();
    final phone = (user['phone'] ?? '').toString();
    final avatarUrl = (user['avatarUrl'] ?? '').toString();
    final profile = _asMap(user['healthProfile']);
    final diabetesType = _diabetesTypeText(profile['diabetesType']);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A887B), Color(0xFF2DA391), Color(0xFF6AC6B2)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240B8A7D),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileAvatarCircle(
                name: name,
                avatarUrl: avatarUrl,
                radius: 30,
                borderColor: Colors.white.withValues(alpha: 0.26),
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                textColor: Colors.white,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(phone, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroPill('账号已登录'),
              _heroPill('糖尿病类型 $diabetesType'),
              _heroPill('可管理提醒与健康档案'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    final text = value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : '未填写';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF5A7673)),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: HealthPageBackground(
        topTint: const Color(0xFFDDF1EE),
        accent: const Color(0xFFFFECDA),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: _ErrorPane(message: _error!, onRetry: _load),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _headerCard(),
                  const SizedBox(height: 14),
                  _menuCard(
                    icon: Icons.edit_outlined,
                    title: '编辑个人信息',
                    subtitle: '昵称、头像等基础资料',
                    onTap: _showEditMe,
                  ),
                  _menuCard(
                    icon: Icons.health_and_safety_outlined,
                    title: '编辑健康档案',
                    subtitle: '身高体重、血糖目标、用药情况',
                    onTap: _showEditHealthProfile,
                  ),
                  _menuCard(
                    icon: Icons.badge_outlined,
                    title: '查看健康档案',
                    subtitle: '查看已保存的档案详情',
                    onTap: _showHealthProfile,
                  ),
                  const SizedBox(height: 10),
                  _menuCard(
                    icon: Icons.alarm_rounded,
                    title: '血糖提醒推送',
                    subtitle: '按空腹、餐后、睡前设置提醒',
                    onTap: _openGlucoseReminderSettings,
                  ),
                  _menuCard(
                    icon: Icons.notifications_active_outlined,
                    title: '提醒列表',
                    subtitle: '查看当前已生效提醒',
                    onTap: _showReminders,
                  ),
                  _menuCard(
                    icon: Icons.warning_amber_rounded,
                    title: '血糖异常记录',
                    subtitle: '查看历次偏高偏低事件',
                    onTap: _showAbnormalEvents,
                  ),
                  _menuCard(
                    icon: Icons.lock_outline_rounded,
                    title: '修改密码',
                    subtitle: '定期更新密码更安全',
                    onTap: _showChangePassword,
                  ),
                  const SizedBox(height: 20),
                  FrostPanel(
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('退出登录'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: const Color(0xFFC53A2E),
                        side: const BorderSide(color: Color(0xFFC53A2E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Color(0xFFC53A2E),
          ),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Color(0xFFC53A2E))),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _BasicProfileEditScreen extends StatefulWidget {
  const _BasicProfileEditScreen({
    required this.initialNickname,
    required this.initialAvatarUrl,
  });

  final String initialNickname;
  final String initialAvatarUrl;

  @override
  State<_BasicProfileEditScreen> createState() =>
      _BasicProfileEditScreenState();
}

class _BasicProfileEditScreenState extends State<_BasicProfileEditScreen> {
  late final TextEditingController _nicknameCtrl;
  late String _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.initialNickname);
    _avatarUrl = widget.initialAvatarUrl.trim();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _editAvatar() async {
    final controller = TextEditingController(text: _avatarUrl);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '修改头像',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '当前后端仍然保存头像地址，因此这里支持直接粘贴图片链接，点头像就能改。',
                style: TextStyle(color: Color(0xFF5A7673), height: 1.45),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '头像地址',
                  hintText: 'https://example.com/avatar.jpg',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(''),
                      child: const Text('清除头像'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(controller.text.trim()),
                      child: const Text('应用头像'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _avatarUrl = result.trim();
    });
  }

  void _submit() {
    Navigator.of(context).pop({
      'nickname': _nicknameCtrl.text.trim().isEmpty
          ? null
          : _nicknameCtrl.text.trim(),
      'avatarUrl': _avatarUrl.trim().isEmpty ? null : _avatarUrl.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _nicknameCtrl.text.trim().isEmpty
        ? widget.initialNickname
        : _nicknameCtrl.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('编辑个人信息')),
      body: HealthPageBackground(
        topTint: const Color(0xFFDDF1EE),
        accent: const Color(0xFFFFECDA),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const FrostPanel(
              child: SectionTitle(
                title: '基础资料',
                subtitle: '头像改为点击头像即可修改，昵称和头像保存后会立即同步到个人中心。',
              ),
            ),
            const SizedBox(height: 12),
            FrostPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: InkWell(
                      onTap: _editAvatar,
                      borderRadius: BorderRadius.circular(999),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _ProfileAvatarCircle(
                                name: previewName,
                                avatarUrl: _avatarUrl,
                                radius: 42,
                                borderColor: const Color(0xFFBFE0DB),
                                backgroundColor: const Color(0xFFEAF5F2),
                                textColor: const Color(0xFF0B8A7D),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B8A7D),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '点击头像修改',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF173836),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _avatarUrl.trim().isEmpty
                                ? '当前使用默认头像'
                                : '当前已设置头像链接',
                            style: const TextStyle(
                              color: Color(0xFF5A7673),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nicknameCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: '昵称'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('保存')),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarCircle extends StatelessWidget {
  const _ProfileAvatarCircle({
    required this.name,
    required this.avatarUrl,
    required this.radius,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
  });

  final String name;
  final String avatarUrl;
  final double radius;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  bool get _hasNetworkAvatar {
    return avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final fallback = name.isEmpty ? 'U' : name.characters.first.toUpperCase();
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: ClipOval(
        child: _hasNetworkAvatar
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(fallback),
              )
            : _buildFallback(fallback),
      ),
    );
  }

  Widget _buildFallback(String fallback) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        fallback,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}
