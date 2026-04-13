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
    '米饭': ['rice', 'grain', 'pilaf', 'risotto', 'bowl'],
    '糙米饭': ['brown rice'],
    '燕麦': ['oat', 'oatmeal', 'porridge'],
    '鸡蛋': ['egg', 'omelette'],
    '鸡胸肉': ['chicken', 'meat', 'poultry'],
    '三文鱼': ['salmon', 'fish'],
    '虾仁': ['shrimp', 'prawn'],
    '豆腐': ['tofu', 'soy'],
    '西兰花': ['broccoli'],
    '黄瓜': ['cucumber'],
    '番茄': ['tomato'],
    '苹果': ['apple', 'fruit'],
    '蓝莓': ['blueberry', 'berry'],
    '无糖酸奶': ['yogurt', 'yoghurt'],
    '牛奶': ['milk', 'dairy'],
  };

  static const Map<String, double> _defaultAmount = {
    '米饭': 150,
    '糙米饭': 150,
    '燕麦': 50,
    '鸡蛋': 60,
    '鸡胸肉': 120,
    '三文鱼': 120,
    '虾仁': 100,
    '豆腐': 120,
    '西兰花': 100,
    '黄瓜': 120,
    '番茄': 120,
    '苹果': 150,
    '蓝莓': 80,
    '无糖酸奶': 180,
    '牛奶': 220,
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

