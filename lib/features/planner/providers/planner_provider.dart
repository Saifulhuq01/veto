import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Schedule Block model representing a focus slot in the daily planner.
class ScheduleBlock {
  const ScheduleBlock({
    required this.id,
    required this.dateString, // "YYYY-MM-DD"
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    this.tag,
    this.tagType, // 'focus', 'recovery', or null
  });

  final String id;
  final String dateString;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final String? tag;
  final String? tagType;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateString': dateString,
      'startTime': startTime,
      'endTime': endTime,
      'title': title,
      'description': description,
      'tag': tag,
      'tagType': tagType,
    };
  }

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) {
    return ScheduleBlock(
      id: json['id'] as String,
      dateString: json['dateString'] as String? ?? _getTodayDateString(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      tag: json['tag'] as String?,
      tagType: json['tagType'] as String?,
    );
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class PlannerState {
  const PlannerState({
    this.schedules = const [],
    this.isLoading = true,
  });

  final List<ScheduleBlock> schedules;
  final bool isLoading;

  PlannerState copyWith({
    List<ScheduleBlock>? schedules,
    bool? isLoading,
  }) {
    return PlannerState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier() : super(const PlannerState()) {
    _loadSchedules();
  }

  static const _prefsKey = 'veto_planner_schedules';

  /// Load schedules from SharedPreferences, seed defaults if empty
  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);

    if (jsonStr == null) {
      // Seed default mockup schedules for today
      final todayStr = _getTodayDateString();
      final defaults = [
        ScheduleBlock(
          id: 'default_1',
          dateString: todayStr,
          startTime: '09:00 AM',
          endTime: '11:30 AM',
          title: 'Deep Work Protocol',
          description:
              'System architecture review and core logic implementation. No interruptions allowed.',
          tag: 'High Focus',
          tagType: 'focus',
        ),
        ScheduleBlock(
          id: 'default_2',
          dateString: todayStr,
          startTime: '12:00 PM',
          endTime: '01:00 PM',
          title: 'Lunch & Walk',
          description: 'Disconnect from screens. 20 minute outdoor walk.',
          tag: 'Recovery',
          tagType: 'recovery',
        ),
        ScheduleBlock(
          id: 'default_3',
          dateString: todayStr,
          startTime: '02:00 PM',
          endTime: '03:00 PM',
          title: 'Team Sync',
          description: 'Weekly alignment on design system updates.',
        ),
      ];

      state = PlannerState(schedules: defaults, isLoading: false);
      await _saveToPrefs(defaults);
    } else {
      try {
        final decodedList = jsonDecode(jsonStr) as List<dynamic>;
        final schedules = decodedList
            .map((item) => ScheduleBlock.fromJson(item as Map<String, dynamic>))
            .toList();
        state = PlannerState(schedules: schedules, isLoading: false);
      } catch (e) {
        state = const PlannerState(schedules: [], isLoading: false);
      }
    }
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Add a new schedule block
  Future<void> addScheduleBlock(ScheduleBlock block) async {
    final updated = [...state.schedules, block];
    state = state.copyWith(schedules: updated);
    await _saveToPrefs(updated);
  }

  /// Add multiple schedule blocks in bulk (recurrence creation)
  Future<void> addScheduleBlocks(List<ScheduleBlock> blocks) async {
    final updated = [...state.schedules, ...blocks];
    state = state.copyWith(schedules: updated);
    await _saveToPrefs(updated);
  }

  /// Delete an existing schedule block by ID
  Future<void> deleteScheduleBlock(String id) async {
    final updated = state.schedules.where((s) => s.id != id).toList();
    state = state.copyWith(schedules: updated);
    await _saveToPrefs(updated);
  }

  Future<void> _saveToPrefs(List<ScheduleBlock> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await prefs.setString(_prefsKey, jsonStr);
  }
}

final plannerProvider = StateNotifierProvider<PlannerNotifier, PlannerState>(
  (ref) => PlannerNotifier(),
);
