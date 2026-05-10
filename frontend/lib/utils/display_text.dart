class DisplayText {
  static const Map<String, String> _labels = {
    'ALL': '全部',
    'FASTING': '空腹',
    'POST_MEAL': '餐后',
    'BEFORE_SLEEP': '睡前',
    'RANDOM': '随机',
    'BREAKFAST': '早餐',
    'LUNCH': '午餐',
    'DINNER': '晚餐',
    'SNACK': '加餐',
    'GLUCOSE_TEST': '血糖提醒',
    'MEDICINE': '用药提醒',
    'EXERCISE': '运动提醒',
    'DIET': '饮食提醒',
    '血糖提醒': '血糖提醒',
    '用药提醒': '用药提醒',
    '运动提醒': '运动提醒',
    '饮食提醒': '饮食提醒',
    'DAILY': '每天',
    'WORKDAY': '工作日',
    'CUSTOM': '自定义',
    'WEEKLY': '每周',
    'ONCE': '仅一次',
    '每天': '每天',
    '工作日': '工作日',
    '自定义': '自定义',
    'MALE': '男',
    'FEMALE': '女',
    'OTHER': '1.5型',
    'UNKNOWN': '不透露',
    'TYPE1': '一型',
    'TYPE_1': '一型',
    'TYPE2': '二型',
    'TYPE_2': '二型',
    'TYPE_1_5': '1.5型',
    'LADA': '1.5型',
    'GESTATIONAL': '妊娠型',
    'PATIENT': '病友',
    'DOCTOR': '医生',
    'FAMILY': '家属',
    'ADMIN': '官方',
    '病友': '病友',
    '医生': '医生',
    '家属': '家属',
    '官方': '官方',
    'HIGH': '偏高',
    'LOW': '偏低',
    'OK': '合适',
    'NORMAL': '正常',
    'PASSWORD': '密码登录',
    'SMS': '短信登录',
    'REGISTER': '注册',
    'LOGIN': '登录',
  };

  static String label(dynamic value, {String fallback = '未设置'}) {
    final raw = _raw(value);
    if (raw.isEmpty) return fallback;
    final normalized = _normalize(raw);
    return _labels[normalized] ?? _labels[raw] ?? _safeUnknown(raw, fallback);
  }

  static String glucoseMeasure(dynamic value) {
    return label(value, fallback: '随机');
  }

  static String meal(dynamic value) {
    return label(value, fallback: '餐次');
  }

  static String reminderType(dynamic value) {
    return label(value, fallback: '提醒');
  }

  static String repeatType(dynamic value) {
    return label(value, fallback: '每天');
  }

  static String diabetesType(dynamic value) {
    return label(value, fallback: '未设置');
  }

  static String gender(dynamic value) {
    final raw = _normalize(_raw(value));
    if (raw == 'MALE') return '男';
    if (raw == 'FEMALE') return '女';
    return '不透露';
  }

  static String role(dynamic value, {bool adminCanSeeRaw = false}) {
    final raw = _raw(value);
    if (raw.isEmpty) return '病友';
    if (adminCanSeeRaw) return _labels[_normalize(raw)] ?? raw;
    return _labels[_normalize(raw)] ?? _labels[raw] ?? '病友';
  }

  static String text(dynamic value, {String fallback = '未填写'}) {
    final raw = _raw(value);
    if (raw.isEmpty) return fallback;
    return _safeUnknown(raw, fallback);
  }

  static String userError(dynamic error) {
    final raw = _raw(error);
    if (raw.isEmpty) return '操作失败，请稍后重试';

    var message = raw
        .replaceAll(RegExp(r'https?://[^\s,，。]+'), '')
        .replaceAll(RegExp(r'\b\d{1,3}(\.\d{1,3}){3}(:\d+)?\b'), '')
        .replaceAll(RegExp(r'package:[^\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = message.toLowerCase();
    if (message == 'Request failed' ||
        lower.contains('backend') ||
        lower.contains('stacktrace') ||
        lower.contains('failed assertion') ||
        lower.contains('socketexception') ||
        lower.contains('httpexception') ||
        lower.contains('clientexception') ||
        lower.contains('nullpointerexception') ||
        message.contains('已尝试：') ||
        message.contains('候选') ||
        message.contains('adb reverse') ||
        message.contains('API_BASE_URL')) {
      return '服务暂时不可用，请稍后重试';
    }

    message = message.replaceFirst(RegExp(r'[:：]\s*[A-Z0-9_./-]+$'), '');
    message = _replaceKnownCodes(message);

    if (_looksLikeCode(message) || _looksMojibake(message)) {
      return '操作失败，请稍后重试';
    }

    if (message.length > 80) {
      return '${message.substring(0, 80)}...';
    }
    return message;
  }

  static bool isAdmin(dynamic value) {
    final normalized = _normalize(_raw(value));
    return normalized == 'ADMIN' || normalized == '官方';
  }

  static String _raw(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _normalize(String value) {
    return value.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
  }

  static String _replaceKnownCodes(String message) {
    var result = message;
    for (final entry in _labels.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  static String _safeUnknown(String raw, String fallback) {
    final normalized = _normalize(raw);
    if (_labels.containsKey(normalized)) return _labels[normalized]!;
    if (_looksLikeCode(raw) || _looksMojibake(raw) || _looksSensitive(raw)) {
      return fallback;
    }
    return raw;
  }

  static bool _looksLikeCode(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return false;
    return RegExp(r'^[A-Z0-9_./:-]{3,}$').hasMatch(raw) ||
        RegExp(r'\b[A-Z]{2,}_[A-Z0-9_]+\b').hasMatch(raw);
  }

  static bool _looksMojibake(String value) {
    return RegExp(r'[�绌椁鐫鎻鏈鏃愬悗墠啋]').hasMatch(value);
  }

  static bool _looksSensitive(String value) {
    final lower = value.toLowerCase();
    return lower.contains('token') ||
        lower.contains('secret') ||
        lower.contains('password') ||
        lower.contains('debug') ||
        lower.contains('stack') ||
        lower.contains('exception') ||
        lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('/api/');
  }
}
