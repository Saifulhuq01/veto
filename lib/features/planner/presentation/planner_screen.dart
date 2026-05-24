import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../providers/planner_provider.dart';

/// Provider to track currently selected day index (0 = Mon, ..., 6 = Sun)
final selectedDayProvider = StateProvider<int>((ref) => 1); // Tue selected by default

/// Planner (Schedule) screen — daily focus block management.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final plannerState = ref.watch(plannerProvider);

    // Filter schedules for the selected day index
    final filteredSchedules = plannerState.schedules
        .where((s) => s.dayIndex == selectedDay)
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 104, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your daily focus blocks.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: VetoColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // ── Horizontal calendar strip ──
            const _CalendarStrip(),
            const SizedBox(height: 32),

            // ── Schedule timeline ──
            if (plannerState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (filteredSchedules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: GlassPanel(
                    borderRadius: 16,
                    blurSigma: 24,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No focus blocks scheduled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "+ New Schedule" below to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...List.generate(filteredSchedules.length, (index) {
                final block = filteredSchedules[index];
                return _ScheduleCard(
                  block: block,
                  isFirst: index == 0,
                  isLast: index == filteredSchedules.length - 1,
                );
              }),

            const SizedBox(height: 32),

            // ── New Schedule FAB ──
            Center(
              child: _NewScheduleButton(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal day calendar strip.
class _CalendarStrip extends ConsumerWidget {
  const _CalendarStrip();

  static const _days = [
    _DayData(label: 'MON', date: '12', index: 0),
    _DayData(label: 'TUE', date: '13', index: 1),
    _DayData(label: 'WED', date: '14', index: 2),
    _DayData(label: 'THU', date: '15', index: 3),
    _DayData(label: 'FRI', date: '16', index: 4),
    _DayData(label: 'SAT', date: '17', index: 5),
    _DayData(label: 'SUN', date: '18', index: 6),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);

    return SizedBox(
      height: 80,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            colors: [
              VetoColors.canvasBase,
              Colors.transparent,
              Colors.transparent,
              VetoColors.canvasBase,
            ],
            stops: [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstOut,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final day = _days[index];
            final isActive = day.index == selectedDay;

            return GestureDetector(
              onTap: () => ref.read(selectedDayProvider.notifier).state = day.index,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isActive
                      ? VetoColors.glassWhite10
                      : VetoColors.glassWhite5,
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: isActive
                      ? [
                          const BoxShadow(
                            color: VetoColors.glassInnerGlow,
                            blurRadius: 1,
                            offset: Offset(0, 1),
                            blurStyle: BlurStyle.inner,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : VetoColors.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.date,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : VetoColors.onSurface,
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DayData {
  const _DayData({required this.label, required this.date, required this.index});
  final String label;
  final String date;
  final int index;
}

/// Schedule timeline card with dot, connector line and delete option.
class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({
    required this.block,
    this.isFirst = false,
    this.isLast = false,
  });

  final ScheduleBlock block;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color? tagColor;
    Color? tagTextColor;

    if (block.tagType == 'focus') {
      tagColor = VetoColors.fuchsiaTag;
      tagTextColor = VetoColors.fuchsiaTagText;
    } else if (block.tagType == 'recovery') {
      tagColor = VetoColors.emeraldTag;
      tagTextColor = VetoColors.emeraldTagText;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline indicator ──
          SizedBox(
            width: 20,
            child: Column(
              children: [
                // Dot
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ── Card ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassPanel(
                borderRadius: 12,
                blurSigma: 48,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${block.startTime} - ${block.endTime}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: VetoColors.onSurfaceVariant,
                            height: 20 / 14,
                          ),
                        ),
                        Row(
                          children: [
                            if (block.tag != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9999),
                                  color: tagColor ?? VetoColors.glassWhite10,
                                  border: Border.all(
                                    color: (tagTextColor ?? Colors.white)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  block.tag!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: tagTextColor ?? Colors.white,
                                    height: 16 / 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: VetoColors.error,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                ref
                                    .read(plannerProvider.notifier)
                                    .deleteScheduleBlock(block.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      block.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      block.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: VetoColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating "+ New Schedule" button.
class _NewScheduleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddScheduleBottomSheet(context, ref),
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                color: VetoColors.glassWhite10,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: VetoColors.glassInnerGlow,
                    blurRadius: 1,
                    offset: Offset(0, 1),
                    blurStyle: BlurStyle.inner,
                  ),
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 32,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'New Schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddScheduleBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const _AddScheduleSheet(),
    );
  }
}

/// Sheet component to add a new schedule block
class _AddScheduleSheet extends ConsumerStatefulWidget {
  const _AddScheduleSheet();

  @override
  ConsumerState<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends ConsumerState<_AddScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _selectedTagType; // 'focus', 'recovery', or null
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    // Default day index to currently selected day on screen
    _selectedDayIndex = ref.read(selectedDayProvider);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$min $period';
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: VetoColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        margin: const EdgeInsets.only(top: 80),
        decoration: const BoxDecoration(
          color: Color(0xD905050A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: VetoColors.glassBorder, width: 1),
          ),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Focus Block',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Block Title',
                    labelStyle: const TextStyle(color: Colors.white60),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VetoColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter a title';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Input
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.white60),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VetoColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Day Selection
                const Text('Day of Week', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (idx) {
                    final daysShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    final isSel = _selectedDayIndex == idx;
                    return ChoiceChip(
                      label: Text(daysShort[idx]),
                      selected: isSel,
                      selectedColor: Colors.white12,
                      backgroundColor: Colors.transparent,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: isSel ? Colors.white : Colors.white38),
                      side: BorderSide(
                        color: isSel ? Colors.white38 : VetoColors.glassBorder,
                      ),
                      onSelected: (_) => setState(() => _selectedDayIndex = idx),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VetoColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(_formatTime(_startTime), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VetoColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(_formatTime(_endTime), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tag Picker
                const Text('Category Tag', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('High Focus'),
                      selected: _selectedTagType == 'focus',
                      selectedColor: VetoColors.fuchsiaTag,
                      backgroundColor: Colors.transparent,
                      labelStyle: const TextStyle(color: VetoColors.fuchsiaTagText),
                      side: const BorderSide(color: VetoColors.glassBorder),
                      onSelected: (sel) {
                        setState(() => _selectedTagType = sel ? 'focus' : null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Recovery'),
                      selected: _selectedTagType == 'recovery',
                      selectedColor: VetoColors.emeraldTag,
                      backgroundColor: Colors.transparent,
                      labelStyle: const TextStyle(color: VetoColors.emeraldTagText),
                      side: const BorderSide(color: VetoColors.glassBorder),
                      onSelected: (sel) {
                        setState(() => _selectedTagType = sel ? 'recovery' : null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Cancel',
                        variant: GlassButtonVariant.secondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        label: 'Create',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final tagStr = _selectedTagType == 'focus'
                                ? 'High Focus'
                                : (_selectedTagType == 'recovery' ? 'Recovery' : null);

                            final newBlock = ScheduleBlock(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              dayIndex: _selectedDayIndex ?? 1,
                              startTime: _formatTime(_startTime),
                              endTime: _formatTime(_endTime),
                              title: _titleController.text,
                              description: _descController.text,
                              tag: tagStr,
                              tagType: _selectedTagType,
                            );

                            ref.read(plannerProvider.notifier).addScheduleBlock(newBlock);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
