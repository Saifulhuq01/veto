import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../providers/planner_provider.dart';

/// Provider to track currently selected date
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Helper to format date to YYYY-MM-DD
String _formatDateToYYYYMMDD(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Planner (Schedule) screen — daily focus block management.
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late final ScrollController _calendarScrollController;

  @override
  void initState() {
    super.initState();
    _calendarScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday(animate: false);
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _scrollToToday({bool animate = true}) {
    if (!_calendarScrollController.hasClients) return;

    final now = DateTime.now();
    final todayIndex = now.day - 1; // 0-indexed day
    final screenWidth = MediaQuery.of(context).size.width;

    // Item width is 64 + 12 separator = 76.
    const itemWidth = 76.0;
    // Offset calculation: center the item and account for screen margins (padding)
    final targetOffset = (todayIndex * itemWidth) - (screenWidth / 2) + 32.0 + 24.0;

    final maxScroll = _calendarScrollController.position.maxScrollExtent;
    final double offset = targetOffset.clamp(0.0, maxScroll);

    if (animate) {
      _calendarScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _calendarScrollController.jumpTo(offset);
    }
  }

  String _getCurrentFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedDateStr = _formatDateToYYYYMMDD(selectedDate);
    final plannerState = ref.watch(plannerProvider);

    // Filter schedules for the selected calendar date
    final filteredSchedules = plannerState.schedules
        .where((s) => s.dateString == selectedDateStr)
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
            const SizedBox(height: 4),
            Text(
              _getCurrentFormattedDate(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: VetoColors.secondary,
                letterSpacing: 0.5,
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

            // ── Horizontal calendar strip + Today Snap Button ──
            Row(
              children: [
                Expanded(
                  child: _CalendarStrip(scrollController: _calendarScrollController),
                ),
                const SizedBox(width: 10),
                _TodayResetButton(
                  onTap: () {
                    final today = DateTime.now();
                    ref.read(selectedDateProvider.notifier).state =
                        DateTime(today.year, today.month, today.day);
                    _scrollToToday(animate: true);
                  },
                ),
              ],
            ),
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

/// Horizontal day calendar strip for the entire month.
class _CalendarStrip extends ConsumerWidget {
  const _CalendarStrip({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();

    // Generate dates for the current month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final List<DateTime> days = List.generate(
      lastDayOfMonth,
      (index) => DateTime(now.year, now.month, index + 1),
    );

    final weekdaysShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

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
            stops: [0.0, 0.03, 0.97, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstOut,
        child: ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final dayDate = days[index];
            final isToday = dayDate.day == now.day &&
                dayDate.month == now.month &&
                dayDate.year == now.year;
            final isSelected = dayDate.day == selectedDate.day &&
                dayDate.month == selectedDate.month &&
                dayDate.year == selectedDate.year;

            final dayLabel = weekdaysShort[dayDate.weekday - 1];

            return GestureDetector(
              onTap: () {
                ref.read(selectedDateProvider.notifier).state = dayDate;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? VetoColors.glassWhite15
                      : (isToday ? VetoColors.glassWhite10 : VetoColors.glassWhite5),
                  border: Border.all(
                    color: isSelected
                        ? VetoColors.secondary.withValues(alpha: 0.5)
                        : (isToday
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05)),
                  ),
                  boxShadow: isSelected
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
                      dayLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? VetoColors.secondary
                            : (isToday ? Colors.white : VetoColors.onSurfaceVariant),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayDate.day.toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isToday ? VetoColors.secondary : VetoColors.onSurface),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: VetoColors.secondary,
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

/// Mini glassmorphic snap-back-to-today button.
class _TodayResetButton extends StatelessWidget {
  const _TodayResetButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 12,
      blurSigma: 24,
      padding: EdgeInsets.zero,
      child: Tooltip(
        message: 'Back to Today',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
             child: const SizedBox(
              width: 48,
              height: 80, // Matches calendar strip cell height
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.today_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: VetoColors.secondary,
                      letterSpacing: 0.5,
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
  late DateTime _selectedDate;
  bool _repeatUntilMonthEnd = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = ref.read(selectedDateProvider);
    // If selected date is in the past, default to today
    _selectedDate = selected.isBefore(today) ? today : selected;
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

  String _formatDateDisplay(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Clamp initialDate to prevent assertion errors if _selectedDate is in the past
    final initial = _selectedDate.isBefore(today) ? today : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today, // Cannot select past dates
      lastDate: DateTime(now.year, now.month + 2, 0), // Allow selection up to end of next month
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
        _selectedDate = picked;
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

                // Date Selection
                const Text('Schedule Date', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VetoColors.glassBorder),
                      color: VetoColors.glassWhite5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDateDisplay(_selectedDate),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.calendar_month, color: VetoColors.secondary, size: 20),
                      ],
                    ),
                  ),
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
                            color: VetoColors.glassWhite5,
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
                            color: VetoColors.glassWhite5,
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
                const SizedBox(height: 20),

                // Recurrence option
                const Divider(color: VetoColors.glassBorder, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Repeat Daily Until Month End',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Schedule on all upcoming days this month',
                          style: TextStyle(
                            color: VetoColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _repeatUntilMonthEnd,
                      activeColor: VetoColors.secondary,
                      onChanged: (val) {
                        setState(() => _repeatUntilMonthEnd = val);
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

                            if (_repeatUntilMonthEnd) {
                              final List<ScheduleBlock> recurringBlocks = [];
                              final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
                              final startDay = _selectedDate.day;

                              for (int day = startDay; day <= lastDayOfMonth; day++) {
                                final blockDate = DateTime(_selectedDate.year, _selectedDate.month, day);
                                final blockDateStr = _formatDateToYYYYMMDD(blockDate);
                                final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_$day';

                                recurringBlocks.add(ScheduleBlock(
                                  id: uniqueId,
                                  dateString: blockDateStr,
                                  startTime: _formatTime(_startTime),
                                  endTime: _formatTime(_endTime),
                                  title: _titleController.text,
                                  description: _descController.text,
                                  tag: tagStr,
                                  tagType: _selectedTagType,
                                ));
                              }

                              ref.read(plannerProvider.notifier).addScheduleBlocks(recurringBlocks);
                            } else {
                              final blockDateStr = _formatDateToYYYYMMDD(_selectedDate);
                              final newBlock = ScheduleBlock(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                dateString: blockDateStr,
                                startTime: _formatTime(_startTime),
                                endTime: _formatTime(_endTime),
                                title: _titleController.text,
                                description: _descController.text,
                                tag: tagStr,
                                tagType: _selectedTagType,
                              );

                              ref.read(plannerProvider.notifier).addScheduleBlock(newBlock);
                            }

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
