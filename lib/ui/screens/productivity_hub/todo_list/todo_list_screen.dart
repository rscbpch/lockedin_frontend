import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/models/productivity_tools/todo_list/todo_task.dart';
import 'package:lockedin_frontend/services/todo_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/square_button.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showCompletedTasks = false;
  List<TodoTask> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todos = await TodoService.fetchTodos();
      setState(() {
        _tasks = todos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TodoTask> _getPendingTasks() {
    return _tasks.where((task) {
      final taskDate = task.dueDate ?? task.dueDateTime;
      if (taskDate == null) return task.status == Status.pending;
      return taskDate.year == _selectedDate.year && taskDate.month == _selectedDate.month && taskDate.day == _selectedDate.day && task.status == Status.pending;
    }).toList();
  }

  List<TodoTask> _getCompletedTasks() {
    return _tasks.where((task) {
      final taskDate = task.dueDate ?? task.dueDateTime;
      if (taskDate == null) return task.status == Status.completed;
      return taskDate.year == _selectedDate.year && taskDate.month == _selectedDate.month && taskDate.day == _selectedDate.day && task.status == Status.completed;
    }).toList();
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.textPrimary, onPrimary: AppColors.background, surface: AppColors.background, onSurface: AppColors.textPrimary),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'To-do List',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 24), fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go('/productivity-hub'),
          icon: Icon(Icons.arrow_back_ios, size: width * 0.06, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 8),
        child: SquareButton(
          icon: Icons.add,
          onPressed: () {},
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getMonthName(_selectedDate.month),
                    style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 18), fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showDatePicker(context),
                    icon: Icon(FeatherIcons.calendar, size: width * 0.05, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeekCalendar(),
              const SizedBox(height: 24),
              Expanded(child: _buildTaskList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load tasks',
              style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), color: AppColors.textPrimary.withOpacity(0.5)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadTasks,
              child: Text(
                'Retry',
                style: TextStyle(fontFamily: 'Nunito', color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    final pendingTasks = _getPendingTasks();
    final completedTasks = _getCompletedTasks();

    if (pendingTasks.isEmpty && completedTasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks for this day',
          style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), color: AppColors.textPrimary.withOpacity(0.5)),
        ),
      );
    }

    return ListView(
      children: [
        ...pendingTasks.map((task) => _buildTaskItem(task)),
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _showCompletedTasks = !_showCompletedTasks;
              });
            },
            child: Row(
              children: [
                Icon(_showCompletedTasks ? FeatherIcons.chevronDown : FeatherIcons.chevronRight, size: 18, color: AppColors.textPrimary.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  '${completedTasks.length} Completed',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 14), fontWeight: FontWeight.w500, color: AppColors.textPrimary.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_showCompletedTasks) ...completedTasks.map((task) => _buildTaskItem(task)),
        ],
      ],
    );
  }

  Widget _buildTaskItem(TodoTask task) {
    final bool isCompleted = task.status == Status.completed;
    final double opacity = isCompleted ? 0.4 : 1.0;

    String timeText = '';
    if (task.dueTime != null) {
      final hour = task.dueTime!.hourOfPeriod == 0 ? 12 : task.dueTime!.hourOfPeriod;
      final minute = task.dueTime!.minute.toString().padLeft(2, '0');
      final period = task.dueTime!.period == DayPeriod.am ? 'am' : 'pm';
      timeText = '$hour:$minute $period';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: Responsive.text(context, size: 16),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withOpacity(opacity),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 14), color: AppColors.textPrimary.withOpacity(isCompleted ? 0.3 : 0.6)),
                  ),
                ],
              ],
            ),
          ),
          Checkbox(
            value: isCompleted,
            onChanged: (value) async {
              final newStatus = (value ?? false) ? Status.completed : Status.pending;
              setState(() {
                task.status = newStatus;
              });
              try {
                await TodoService.updateTodo(task.id, status: newStatus);
              } catch (_) {
                // Revert on failure
                setState(() {
                  task.status = isCompleted ? Status.completed : Status.pending;
                });
              }
            },
            activeColor: AppColors.textPrimary.withOpacity(opacity),
            side: BorderSide(color: AppColors.textPrimary.withOpacity(opacity), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }

  // row calendar
  Widget _buildWeekCalendar() {
    final List<String> weekDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // center the selected day
    final DateTime startOfWeek = _selectedDate.subtract(const Duration(days: 3));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final DateTime date = startOfWeek.add(Duration(days: index));
        final bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
        final String dayName = weekDayNames[date.weekday - 1];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayName,
                style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 14), fontWeight: FontWeight.w400, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                '${date.day}',
                style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 18), fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppColors.textPrimary : Colors.transparent),
              ),
            ],
          ),
        );
      }),
    );
  }
}
