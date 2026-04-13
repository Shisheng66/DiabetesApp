import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class PhotoFoodEstimate {
  PhotoFoodEstimate({
    required this.food,
    required this.amountG,
    required this.estimatedKcal,
    required this.labels,
    required this.confidence,
  });

  final Map<String, dynamic> food;
  final double amountG;
  final double estimatedKcal;
  final List<String> labels;
  final double confidence;
}

class PhotoFoodEstimatorService {
  static const Map<String, List<String>> _keywordMap = {
    '米饭': ['rice', 'grain', 'pilaf', 'risotto', 'bowl', 'fried rice'],
    '糙米饭': ['brown rice', 'whole grain rice'],
    '燕麦片': ['oat', 'oatmeal', 'porridge', 'cereal'],
    '全麦面包': ['bread', 'toast', 'whole wheat'],
    '红薯': ['sweet potato', 'yam'],
    '玉米': ['corn', 'maize'],
    '鸡蛋': ['egg', 'omelette', 'scrambled egg', 'boiled egg'],
    '鸡胸肉': ['chicken', 'meat', 'poultry', 'chicken breast', 'grilled chicken'],
    '三文鱼': ['salmon', 'fish', 'seafood'],
    '虾仁': ['shrimp', 'prawn'],
    '牛肉瘦肉': ['beef', 'steak'],
    '豆腐': ['tofu', 'soy', 'bean curd'],
    '无糖酸奶': ['yogurt', 'yoghurt', 'greek yogurt'],
    '低脂牛奶': ['milk', 'dairy', 'low fat milk'],
    '无糖豆浆': ['soy milk', 'soymilk'],
    '西兰花': ['broccoli'],
    '菠菜': ['spinach', 'leaf vegetable'],
    '番茄': ['tomato'],
    '黄瓜': ['cucumber'],
    '生菜': ['lettuce', 'salad'],
    '胡萝卜': ['carrot'],
    '南瓜': ['pumpkin', 'squash'],
    '苹果': ['apple', 'fruit'],
    '蓝莓': ['blueberry', 'berry'],
    '草莓': ['strawberry'],
    '橙子': ['orange', 'citrus'],
    '牛油果': ['avocado'],
    '猕猴桃': ['kiwi'],
    '香蕉': ['banana'],
    '梨': ['pear'],
    '核桃': ['walnut', 'nuts'],
    '杏仁': ['almond', 'nuts'],
    '腰果': ['cashew', 'nuts'],
  };

  static const Map<String, double> _defaultAmount = {
    '米饭': 150,
    '糙米饭': 150,
    '燕麦片': 50,
    '全麦面包': 70,
    '红薯': 150,
    '玉米': 120,
    '鸡蛋': 60,
    '鸡胸肉': 120,
    '三文鱼': 120,
    '虾仁': 100,
    '牛肉瘦肉': 120,
    '豆腐': 120,
    '西兰花': 100,
    '黄瓜': 120,
    '番茄': 120,
    '菠菜': 100,
    '生菜': 80,
    '胡萝卜': 80,
    '苹果': 150,
    '蓝莓': 80,
    '草莓': 120,
    '橙子': 180,
    '牛油果': 100,
    '猕猴桃': 120,
    '香蕉': 120,
    '梨': 180,
    '无糖酸奶': 180,
    '低脂牛奶': 220,
    '无糖豆浆': 220,
    '核桃': 25,
    '杏仁': 25,
    '腰果': 25,
  };

  static Future<PhotoFoodEstimate?> estimate({
    required String imagePath,
    required List<Map<String, dynamic>> foods,
  }) async {
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.45),
    );
    try {
      final input = InputImage.fromFilePath(imagePath);
      final labels = await labeler.processImage(input);
      if (labels.isEmpty) return null;

      final labelNames = labels.map((e) => e.label.toLowerCase()).toList();
      final confidence = labels
          .map((e) => e.confidence)
          .fold<double>(0, (p, c) => c > p ? c : p);

      final matchedName = _findBestFoodName(labelNames);
      if (matchedName == null) return null;
      final matchedFood = _findFoodByName(foods, matchedName);
      if (matchedFood == null) return null;

      final amount = _defaultAmount[matchedName] ?? 120;
      final kcalPer100 = _toDouble(matchedFood['calorieKcalPer100g']) ?? 0;
      final estimatedKcal = kcalPer100 * amount / 100.0;

      return PhotoFoodEstimate(
        food: matchedFood,
        amountG: amount,
        estimatedKcal: estimatedKcal,
        labels: labels.map((e) => '${e.label} ${(e.confidence * 100).toStringAsFixed(0)}%').toList(),
        confidence: confidence,
      );
    } finally {
      await labeler.close();
    }
  }

  static String? _findBestFoodName(List<String> labels) {
    String? bestFood;
    int bestScore = -1;
    for (final entry in _keywordMap.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        for (final label in labels) {
          if (label.contains(keyword)) {
            score++;
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestFood = entry.key;
      }
    }
    if (bestScore <= 0) return null;
    return bestFood;
  }

  static Map<String, dynamic>? _findFoodByName(
    List<Map<String, dynamic>> foods,
    String target,
  ) {
    final exact = foods.where((f) => (f['name'] ?? '').toString() == target);
    if (exact.isNotEmpty) return exact.first;

    final fuzzy = foods.where(
      (f) => (f['name'] ?? '').toString().contains(target),
    );
    if (fuzzy.isNotEmpty) return fuzzy.first;
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}
