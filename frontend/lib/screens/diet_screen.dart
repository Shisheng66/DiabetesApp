import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/photo_food_estimator_service.dart';
import '../widgets/app_toast.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  static const _prefKeySeeded = 'food_lib_seeded_v1';

  static const Map<String, String> _mealLabels = {
    'BREAKFAST': '早餐',
    'LUNCH': '午餐',
    'DINNER': '晚餐',
    'SNACK': '加餐',
  };

  static const List<Map<String, dynamic>> _presetFoods = [
    {'name': '燕麦片', 'category': '主食', 'cal': 389, 'carb': 66.3, 'protein': 16.9, 'fat': 6.9, 'gi': 55},
    {'name': '糙米饭', 'category': '主食', 'cal': 116, 'carb': 25.9, 'protein': 2.6, 'fat': 0.9, 'gi': 55},
    {'name': '全麦面包', 'category': '主食', 'cal': 247, 'carb': 41.0, 'protein': 12.4, 'fat': 4.2, 'gi': 62},
    {'name': '红薯', 'category': '主食', 'cal': 86, 'carb': 20.1, 'protein': 1.6, 'fat': 0.1, 'gi': 61},
    {'name': '玉米', 'category': '主食', 'cal': 96, 'carb': 21.6, 'protein': 3.4, 'fat': 1.2, 'gi': 55},
    {'name': '藜麦', 'category': '主食', 'cal': 368, 'carb': 64.2, 'protein': 14.1, 'fat': 6.1, 'gi': 53},
    {'name': '鸡胸肉', 'category': '蛋白质', 'cal': 165, 'carb': 0, 'protein': 31.0, 'fat': 3.6, 'gi': 0},
    {'name': '鸡蛋', 'category': '蛋白质', 'cal': 143, 'carb': 0.7, 'protein': 12.6, 'fat': 9.5, 'gi': 0},
    {'name': '三文鱼', 'category': '蛋白质', 'cal': 208, 'carb': 0, 'protein': 20.4, 'fat': 13.4, 'gi': 0},
    {'name': '金枪鱼', 'category': '蛋白质', 'cal': 132, 'carb': 0, 'protein': 28.0, 'fat': 1.3, 'gi': 0},
    {'name': '虾仁', 'category': '蛋白质', 'cal': 99, 'carb': 0.2, 'protein': 24.0, 'fat': 0.3, 'gi': 0},
    {'name': '豆腐', 'category': '豆制品', 'cal': 76, 'carb': 1.9, 'protein': 8.1, 'fat': 4.8, 'gi': 15},
    {'name': '无糖酸奶', 'category': '乳制品', 'cal': 63, 'carb': 4.7, 'protein': 5.3, 'fat': 3.0, 'gi': 35},
    {'name': '低脂牛奶', 'category': '乳制品', 'cal': 47, 'carb': 4.9, 'protein': 3.4, 'fat': 1.5, 'gi': 30},
    {'name': '无糖豆浆', 'category': '饮品', 'cal': 31, 'carb': 1.8, 'protein': 3.0, 'fat': 1.6, 'gi': 18},
    {'name': '西兰花', 'category': '蔬菜', 'cal': 34, 'carb': 6.6, 'protein': 2.8, 'fat': 0.4, 'gi': 15},
    {'name': '菠菜', 'category': '蔬菜', 'cal': 23, 'carb': 3.6, 'protein': 2.9, 'fat': 0.4, 'gi': 15},
    {'name': '番茄', 'category': '蔬菜', 'cal': 18, 'carb': 3.9, 'protein': 0.9, 'fat': 0.2, 'gi': 30},
    {'name': '黄瓜', 'category': '蔬菜', 'cal': 16, 'carb': 3.6, 'protein': 0.7, 'fat': 0.1, 'gi': 15},
    {'name': '生菜', 'category': '蔬菜', 'cal': 15, 'carb': 2.9, 'protein': 1.4, 'fat': 0.2, 'gi': 15},
    {'name': '胡萝卜', 'category': '蔬菜', 'cal': 41, 'carb': 9.6, 'protein': 0.9, 'fat': 0.2, 'gi': 35},
    {'name': '苹果', 'category': '水果', 'cal': 52, 'carb': 13.8, 'protein': 0.3, 'fat': 0.2, 'gi': 36},
    {'name': '蓝莓', 'category': '水果', 'cal': 57, 'carb': 14.5, 'protein': 0.7, 'fat': 0.3, 'gi': 53},
    {'name': '草莓', 'category': '水果', 'cal': 32, 'carb': 7.7, 'protein': 0.7, 'fat': 0.3, 'gi': 40},
    {'name': '橙子', 'category': '水果', 'cal': 47, 'carb': 11.8, 'protein': 0.9, 'fat': 0.1, 'gi': 43},
    {'name': '牛油果', 'category': '水果', 'cal': 160, 'carb': 8.5, 'protein': 2.0, 'fat': 14.7, 'gi': 15},
    {'name': '猕猴桃', 'category': '水果', 'cal': 61, 'carb': 14.7, 'protein': 1.1, 'fat': 0.5, 'gi': 39},
    {'name': '杏仁', 'category': '坚果', 'cal': 579, 'carb': 21.6, 'protein': 21.2, 'fat': 49.9, 'gi': 15},
    {'name': '核桃', 'category': '坚果', 'cal': 654, 'carb': 13.7, 'protein': 15.2, 'fat': 65.2, 'gi': 15},
    {'name': '腰果', 'category': '坚果', 'cal': 553, 'carb': 30.2, 'protein': 18.2, 'fat': 43.9, 'gi': 27},
  ];

  final _picker = ImagePicker();
  final _foodKeywordCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _detecting = false;
  String? _error;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _mealPlan;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _foods = [];

  // 防抖计时器
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadAll();
    // 监听输入框变化，防抖 400ms 后自动搜索
    _foodKeywordCtrl.addListener(_onKeywordChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _foodKeywordCtrl.removeListener(_onKeywordChanged);
    _foodKeywordCtrl.dispose();
    super.dispose();
  }

  void _onKeywordChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _loadFoods();
    });
  }

  Future<void> _loadFoods() async {
    try {
      final foodsRes = await ApiService.get(
        '/diet/foods',
        query: {
          'keyword': _foodKeywordCtrl.text.trim(),
          'page': '0',
          'size': '200',
        },
      );
      if (!mounted) return;
      setState(() {
        _foods = _list(foodsRes).map(_map).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final d = DateFormat('yyyy-MM-dd').format(_date);
    try {
      // 使用 SharedPreferences 持久化 seed 标志，避免每次进页面都重复 seed
      final prefs = await SharedPreferences.getInstance();
      final alreadySeeded = prefs.getBool(_prefKeySeeded) ?? false;
      if (!alreadySeeded) {
        final added = await _seedFoodLibrary();
        await prefs.setBool(_prefKeySeeded, true);
        if (added > 0 && mounted) AppToast.info(context, '食物库已扩充：+$added');
      }

      final recordsRes = await ApiService.get('/diet/records', query: {'date': d});
      final summaryRes = await ApiService.get('/diet/summary/daily', query: {'date': d});
      final foodsRes = await ApiService.get(
        '/diet/foods',
        query: {'keyword': _foodKeywordCtrl.text.trim(), 'page': '0', 'size': '200'},
      );
      final planRes = await ApiService.get('/diet/meal-plans', query: {'date': d});

      final rows = _list(recordsRes).map(_map).toList()
        ..sort(
          (a, b) => _dt(b['recordTime'] ?? b['createdAt'])
              .compareTo(_dt(a['recordTime'] ?? a['createdAt'])),
        );

      if (!mounted) return;
      setState(() {
        _records = rows;
        _summary = summaryRes;
        _foods = _list(foodsRes).map(_map).toList();
        _mealPlan = planRes;
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
        _error = '饮食数据加载失败';
        _loading = false;
      });
    }
  }

  Future<int> _seedFoodLibrary() async {
    try {
      final res = await ApiService.get(
        '/diet/foods',
        query: {'keyword': '', 'page': '0', 'size': '500'},
      );
      final exists = _list(res)
          .map((e) => '${_map(e)['name']}'.toLowerCase().trim())
          .toSet();
      var added = 0;
      for (final f in _presetFoods) {
        final n = '${f['name']}'.toLowerCase().trim();
        if (exists.contains(n)) continue;
        try {
          await ApiService.post('/diet/foods', {
            'name': f['name'],
            'category': f['category'],
            'calorieKcalPer100g': f['cal'],
            'carbGPer100g': f['carb'],
            'proteinGPer100g': f['protein'],
            'fatGPer100g': f['fat'],
            'gi': f['gi'],
          });
          exists.add(n);
          added++;
        } on ApiException {}
      }
      return added;
    } catch (_) {
      return 0;
    }
  }

  List<dynamic> _list(Map<String, dynamic> r) {
    if (r['data'] is List) return r['data'] as List;
    if (r['content'] is List) return r['content'] as List;
    if (r['items'] is List) return r['items'] as List;
    final d = r['data'];
    if (d is Map<String, dynamic> && d['content'] is List) return d['content'] as List;
    return const [];
  }

  Map<String, dynamic> _map(dynamic v) => v is Map<String, dynamic>
      ? v
      : (v is Map ? v.map((k, val) => MapEntry('$k', val)) : const <String, dynamic>{});
  double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
  String _fmt(dynamic v, {int p = 1}) => _num(v)?.toStringAsFixed(p) ?? '--';
  DateTime _dt(dynamic v) => v is String && DateTime.tryParse(v) != null
      ? DateTime.parse(v).toLocal()
      : DateTime.fromMillisecondsSinceEpoch(0);
  String _meal(dynamic v) => _mealLabels['$v'] ?? '$v';

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() => _date = d);
    _loadAll();
  }

  Future<void> _showAddRecord({
    int? presetFoodId,
    double? presetAmount,
    String? presetRemark,
    // 编辑模式：传入已有记录
    Map<String, dynamic>? editRecord,
  }) async {
    if (_foods.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('食物库为空，请先新增食物')));
      return;
    }

    final isEdit = editRecord != null;
    var mealType = isEdit
        ? (editRecord['mealType'] ?? 'BREAKFAST').toString()
        : 'BREAKFAST';
    var selectedFood = isEdit
        ? (editRecord['foodId'] as int?)
        : presetFoodId ?? (_foods.first['id'] as int?);
    final amountCtrl = TextEditingController(
      text: isEdit
          ? _fmt(editRecord['amountG'], p: 0)
          : (presetAmount?.toStringAsFixed(0) ?? ''),
    );
    final remarkCtrl = TextEditingController(
      text: isEdit ? (editRecord['remark'] ?? '') : (presetRemark ?? ''),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? '编辑饮食记录' : '记录饮食',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: mealType,
                decoration: const InputDecoration(labelText: '餐次'),
                items: _mealLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => mealType = v ?? mealType,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: selectedFood,
                decoration: const InputDecoration(labelText: '食物'),
                items: _foods
                    .take(120)
                    .map((e) => DropdownMenuItem(
                          value: e['id'] as int?,
                          child: Text('${e['name']}'),
                        ))
                    .toList(),
                onChanged: (v) => selectedFood = v,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '克数'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarkCtrl,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (selectedFood == null || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('请完善食物与克数')));
                    return;
                  }
                  try {
                    if (isEdit) {
                      // 删旧建新（后端无 PATCH，先删再加）
                      await ApiService.delete('/diet/records/${editRecord['id']}');
                      await ApiService.post('/diet/records', {
                        'recordDate': DateFormat('yyyy-MM-dd').format(_date),
                        'recordTime': editRecord['recordTime'] ??
                            DateTime.now().toUtc().toIso8601String(),
                        'mealType': mealType,
                        'foodId': selectedFood,
                        'amountG': amount,
                        'remark': remarkCtrl.text.trim().isEmpty
                            ? null
                            : remarkCtrl.text.trim(),
                      });
                    } else {
                      await ApiService.post('/diet/records', {
                        'recordDate': DateFormat('yyyy-MM-dd').format(_date),
                        'recordTime': DateTime.now().toUtc().toIso8601String(),
                        'mealType': mealType,
                        'foodId': selectedFood,
                        'amountG': amount,
                        'remark': remarkCtrl.text.trim().isEmpty
                            ? null
                            : remarkCtrl.text.trim(),
                      });
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await _loadAll();
                    if (!mounted) return;
                    AppToast.success(
                        context, isEdit ? '饮食记录修改成功' : '饮食记录添加成功');
                  } on ApiException catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
                child: Text(isEdit ? '保存修改' : '保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddFood() async {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('新增食物',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '食物名称')),
              const SizedBox(height: 10),
              TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: '分类（可选）')),
              const SizedBox(height: 10),
              TextField(
                  controller: calCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: '热量 kcal/100g')),
              const SizedBox(height: 10),
              TextField(
                  controller: carbCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '碳水 g/100g')),
              const SizedBox(height: 10),
              TextField(
                  controller: proteinCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: '蛋白质 g/100g')),
              const SizedBox(height: 10),
              TextField(
                  controller: fatCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '脂肪 g/100g')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final cal = double.tryParse(calCtrl.text.trim());
                  final carb = double.tryParse(carbCtrl.text.trim());
                  final protein = double.tryParse(proteinCtrl.text.trim());
                  final fat = double.tryParse(fatCtrl.text.trim());
                  if (nameCtrl.text.trim().isEmpty ||
                      cal == null ||
                      carb == null ||
                      protein == null ||
                      fat == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('请填写完整有效信息')));
                    return;
                  }
                  try {
                    await ApiService.post('/diet/foods', {
                      'name': nameCtrl.text.trim(),
                      'category': catCtrl.text.trim().isEmpty
                          ? null
                          : catCtrl.text.trim(),
                      'calorieKcalPer100g': cal,
                      'carbGPer100g': carb,
                      'proteinGPer100g': protein,
                      'fatGPer100g': fat,
                    });
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await _loadAll();
                    if (!mounted) return;
                    AppToast.success(context, '食物添加成功');
                  } on ApiException catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddMealPlan() async {
    if (_foods.isEmpty) return;
    var mealType = 'BREAKFAST';
    var selectedFood = _foods.first['id'] as int?;
    final amountCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('新增每日食谱',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: mealType,
                decoration: const InputDecoration(labelText: '餐次'),
                items: _mealLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => mealType = v ?? mealType,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: selectedFood,
                decoration: const InputDecoration(labelText: '食物'),
                items: _foods
                    .take(120)
                    .map((e) => DropdownMenuItem(
                          value: e['id'] as int?,
                          child: Text('${e['name']}'),
                        ))
                    .toList(),
                onChanged: (v) => selectedFood = v,
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '建议克数')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (selectedFood == null || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('请填写有效克数')));
                    return;
                  }
                  try {
                    await ApiService.post('/diet/meal-plans', {
                      'planDate': DateFormat('yyyy-MM-dd').format(_date),
                      'mealType': mealType,
                      'foodId': selectedFood,
                      'amountG': amount,
                    });
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await _loadAll();
                    if (!mounted) return;
                    AppToast.success(context, '食谱添加成功');
                  } on ApiException catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _photoEstimate() async {
    if (_detecting) return;
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (image == null) return;
    if (_foods.isEmpty) await _loadAll();
    setState(() => _detecting = true);
    try {
      final est = await PhotoFoodEstimatorService.estimate(
          imagePath: image.path, foods: _foods);
      if (!mounted) return;
      if (est == null) {
        AppToast.info(context, '未识别到匹配食物，请手动添加');
        return;
      }
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('识别结果'),
          content: Text(
              '食物：${est.food['name']}\n估算重量：${est.amountG.toStringAsFixed(0)}g\n估算热量：${est.estimatedKcal.toStringAsFixed(0)}kcal'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('加入记录')),
          ],
        ),
      );
      if (ok == true) {
        await _showAddRecord(
          presetFoodId: est.food['id'] as int?,
          presetAmount: est.amountG,
          presetRemark: '拍照识别自动填充',
        );
      }
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planItems = _mealPlan?['items'] is List
        ? (_mealPlan!['items'] as List).map(_map).toList()
        : <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食管理'),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              onPressed: _pickDate),
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _loadAll),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE4F3F0), Color(0xFFF4F8F7)],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            style:
                                const TextStyle(color: Color(0xFFC53A2E))),
                        const SizedBox(height: 10),
                        FilledButton(
                            onPressed: _loadAll,
                            child: const Text('重试')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      children: [
                        // 头部统计卡片
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0C8D7F), Color(0xFF32A89A)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd').format(_date),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '今日摄入 ${_fmt(_summary?['totalCalorieKcal'], p: 0)} kcal',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _chip('碳水 ${_fmt(_summary?['totalCarbG'])}g'),
                                  _chip('蛋白质 ${_fmt(_summary?['totalProteinG'])}g'),
                                  _chip('脂肪 ${_fmt(_summary?['totalFatG'])}g'),
                                  _chip('记录 ${_records.length} 条'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 操作按钮区
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _qa('记录饮食', Icons.add_task_rounded,
                                    _showAddRecord),
                                _qa('新增食谱', Icons.menu_book_rounded,
                                    _showAddMealPlan),
                                _qa('新增食物', Icons.restaurant_menu_rounded,
                                    _showAddFood),
                                _qa(
                                    _detecting ? '识别中...' : '拍照识别',
                                    Icons.camera_alt_rounded,
                                    _detecting ? null : _photoEstimate),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 每日食谱
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('每日食谱',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                if (planItems.isEmpty)
                                  const Text('暂无食谱，点击"新增食谱"创建')
                                else
                                  ...planItems.map((e) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                            '${_meal(e['mealType'])} · ${e['foodName']}'),
                                        subtitle: Text(
                                            '${_fmt(e['amountG'], p: 0)}g · ${_fmt(e['calorieKcal'], p: 0)} kcal'),
                                        trailing: IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded),
                                          onPressed: () async {
                                            await ApiService.delete(
                                                '/diet/meal-plans/${e['id']}');
                                            await _loadAll();
                                            if (!mounted) return;
                                            AppToast.success(
                                                context, '食谱删除成功');
                                          },
                                        ),
                                      )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 今日记录 — 支持编辑
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('今日记录',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                if (_records.isEmpty)
                                  const Text('暂无记录')
                                else
                                  ..._records.map((r) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                            '${r['foodName']} · ${_meal(r['mealType'])}'),
                                        subtitle: Text(
                                            '${_fmt(r['amountG'], p: 0)}g · ${_fmt(r['calorieKcal'], p: 0)} kcal · ${DateFormat('HH:mm').format(_dt(r['recordTime'] ?? r['createdAt']))}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // 编辑按钮
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 20),
                                              onPressed: () => _showAddRecord(
                                                  editRecord: r),
                                            ),
                                            // 删除按钮
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded),
                                              onPressed: () async {
                                                await ApiService.delete(
                                                    '/diet/records/${r['id']}');
                                                await _loadAll();
                                                if (!mounted) return;
                                                AppToast.success(
                                                    context, '记录删除成功');
                                              },
                                            ),
                                          ],
                                        ),
                                      )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 食物库搜索 — 带防抖
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('食物库',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    Text('共 ${_foods.length} 项'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _foodKeywordCtrl,
                                  decoration: const InputDecoration(
                                    hintText: '输入名称自动搜索',
                                    prefixIcon: Icon(Icons.search_rounded),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._foods.take(20).map((f) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('${f['name']}'),
                                      subtitle: Text(
                                          '${f['category'] ?? '未分类'} · ${_fmt(f['calorieKcalPer100g'], p: 0)} kcal/100g'),
                                      trailing: IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline_rounded),
                                        onPressed: () => _showAddRecord(
                                          presetFoodId: f['id'] as int?,
                                          presetAmount: 100,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
      );

  Widget _qa(String t, IconData i, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: onTap == null
                ? const Color(0xFFF1F1F1)
                : const Color(0xFFE8F6F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(i,
                  size: 18,
                  color: onTap == null
                      ? const Color(0xFF9AA8A6)
                      : const Color(0xFF0B8A7D)),
              const SizedBox(width: 8),
              Text(t,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: onTap == null
                          ? const Color(0xFF9AA8A6)
                          : const Color(0xFF1D4844))),
            ],
          ),
        ),
      );
}
