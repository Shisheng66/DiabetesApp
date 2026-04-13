import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_toast.dart';

class GlucoseReminderScreen extends StatefulWidget {
  const GlucoseReminderScreen({super.key});

  @override
  State<GlucoseReminderScreen> createState() => _GlucoseReminderScreenState();
}

class _GlucoseReminderScreenState extends State<GlucoseReminderScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final Map<String, _ReminderSlot> _slots = {
    'FASTING': _ReminderSlot(
      tag: 'FASTING',
      label: '绌鸿吂鎻愰啋',
      enabled: true,
      time: const TimeOfDay(hour: 7, minute: 0),
    ),
    'POST_MEAL': _ReminderSlot(
      tag: 'POST_MEAL',
      label: '椁愬悗鎻愰啋',
      enabled: true,
      time: const TimeOfDay(hour: 13, minute: 0),
    ),
    'BEFORE_SLEEP': _ReminderSlot(
      tag: 'BEFORE_SLEEP',
      label: '鐫″墠鎻愰啋',
      enabled: true,
      time: const TimeOfDay(hour: 21, minute: 0),
    ),
  };

  final Map<String, Map<String, dynamic>> _existingByTag = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _existingByTag.clear();
    });

    try {
      final res = await ApiService.get('/reminders');
      final list = (res['data'] is List) ? (res['data'] as List) : const [];
      for (final raw in list) {
        final item = _asMap(raw);
        final type = (item['type'] ?? '').toString().toUpperCase();
        final tag = (item['remark'] ?? '').toString().toUpperCase();
        if (type != 'GLUCOSE_TEST' || !_slots.containsKey(tag)) continue;
        _existingByTag[tag] = item;

        final slot = _slots[tag]!;
        slot.enabled = item['enabled'] == true;
        final parsed = _parseTime(item['timeOfDay']?.toString() ?? '');
        if (parsed != null) {
          slot.time = parsed;
        }
      }

      setState(() => _loading = false);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = '鍔犺浇澶辫触锛岃绋嶅悗閲嶈瘯';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (final entry in _slots.entries) {
        final tag = entry.key;
        final slot = entry.value;
        final existing = _existingByTag[tag];
        final body = {
          'timeOfDay': _timeToApi(slot.time),
          'repeatType': 'DAILY',
          'enabled': slot.enabled,
          'remark': tag,
        };

        if (existing != null) {
          final id = existing['id'];
          await ApiService.put('/reminders/$id', body);
        } else if (slot.enabled) {
          await ApiService.post('/reminders', {
            'type': 'GLUCOSE_TEST',
            ...body,
          });
        }
      }

      await NotificationService.syncFromBackend();
      if (!mounted) return;
      AppToast.success(context, '提醒设置保存成功');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('淇濆瓨澶辫触锛岃绋嶅悗閲嶈瘯')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickTime(_ReminderSlot slot) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: slot.time,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => slot.time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Glucose Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: (_loading || _saving) ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorPane(message: _error!, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'When enabled, reminders will notify you at selected times every day.',
                      style: TextStyle(color: Color(0xFF5A7673), height: 1.35),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ..._slots.values.map((slot) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '鏃堕棿 ${_format(slot.time)}',
                                  style: const TextStyle(
                                    color: Color(0xFF5A7673),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: slot.enabled,
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => slot.enabled = v),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : () => _pickTime(slot),
                            icon: const Icon(Icons.schedule_rounded, size: 16),
                            label: const Text('Change'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('淇濆瓨鎻愰啋璁剧疆'),
        ),
      ),
    );
  }

  String _format(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _timeToApi(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  TimeOfDay? _parseTime(String text) {
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    return const <String, dynamic>{};
  }
}

class _ReminderSlot {
  _ReminderSlot({
    required this.tag,
    required this.label,
    required this.enabled,
    required this.time,
  });

  final String tag;
  final String label;
  bool enabled;
  TimeOfDay time;
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
          FilledButton(onPressed: onRetry, child: const Text('閲嶈瘯')),
        ],
      ),
    );
  }
}
