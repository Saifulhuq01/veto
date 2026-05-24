import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Schedule Block model representing a focus slot in the daily planner.
class ScheduleBlock {
  const ScheduleBlock({
    required this.id,
    required this.dayIndex, // 0 = Mon, 1 = Tue, ..., 6 = Sun
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    this.tag,
    this.tagType, // 'focus', 'recovery', or null
  });

  final String id;
  final int dayIndex;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final String? tag;
  final String? tagType;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayIndex': dayIndex,
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
      dayIndex: json['dayIndex'] as int,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      tag: json['tag'] as String?,
      tagType: json['tagType'] as String?,
    );
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
      // Seed default mockup schedules for Tuesday (dayIndex: 1)
      final defaults = [
        const ScheduleBlock(
          id: 'default_1',
          dayIndex: 1,
          startTime: '09:00 AM',
          endTime: '11:30 AM',
          title: 'Deep Work Protocol',
          description:
              'System architecture review and core logic implementation. No interruptions allowed.',
          tag: 'High Focus',
          tagType: 'focus',
        ),
        const ScheduleBlock(
          id: 'default_2',
          dayIndex: 1,
          startTime: '12:00 PM',
          endTime: '01:00 PM',
          title: 'Lunch & Walk',
          description: 'Disconnect from screens. 20 minute outdoor walk.',
          tag: 'Recovery',
          tagType: 'recovery',
        ),
        const ScheduleBlock(
          id: 'default_3',
          dayIndex: 1,
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

  /// Add a new schedule block
  Future<void> addScheduleBlock(ScheduleBlock block) async {
    final updated = [...state.schedules, block];
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
