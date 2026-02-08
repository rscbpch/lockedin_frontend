import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class TodoTask {
  final String id;
  final String title;
  final String time;
  final DateTime date;
  bool isCompleted;

  TodoTask({required this.id, required this.title, required this.time, required this.date, this.isCompleted = false});
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showCompletedTasks = false;
  late List<TodoTask> _mockTasks;

  @override
  void initState() {
    super.initState();
    _mockTasks = _generateMockTasks();
  }

  List<TodoTask> _generateMockTasks() {
    final today = DateTime.now();
    return [
      // Today's tasks
      TodoTask(id: '1', title: 'Grab a cup of coffee', time: '7:30 am', date: DateTime(today.year, today.month, today.day)),
      TodoTask(id: '2', title: 'Lunch party', time: '12:30 pm', date: DateTime(today.year, today.month, today.day)),
      TodoTask(id: '3', title: 'Team meeting', time: '3:00 pm', date: DateTime(today.year, today.month, today.day)),
      // Tomorrow's tasks
      TodoTask(id: '4', title: 'Morning workout', time: '6:00 am', date: DateTime(today.year, today.month, today.day + 1)),
      TodoTask(id: '5', title: 'Project review', time: '10:00 am', date: DateTime(today.year, today.month, today.day + 1)),
      // Yesterday's tasks
      TodoTask(id: '6', title: 'Read a book', time: '8:00 pm', date: DateTime(today.year, today.month, today.day - 1)),
      TodoTask(id: '7', title: 'Call mom', time: '5:00 pm', date: DateTime(today.year, today.month, today.day - 1), isCompleted: true),
      // 2 days ago
      TodoTask(id: '8', title: 'Grocery shopping', time: '11:00 am', date: DateTime(today.year, today.month, today.day - 2), isCompleted: true),
      // 3 days later
      TodoTask(id: '9', title: 'Dentist appointment', time: '2:00 pm', date: DateTime(today.year, today.month, today.day + 3)),
    ];
  }

  List<TodoTask> _getPendingTasks() {
    return _mockTasks.where((task) =>
      task.date.year == _selectedDate.year &&
      task.date.month == _selectedDate.month &&
      task.date.day == _selectedDate.day &&
      !task.isCompleted
    ).toList();
  }

  List<TodoTask> _getCompletedTasks() {
    return _mockTasks.where((task) =>
      task.date.year == _selectedDate.year &&
      task.date.month == _selectedDate.month &&
      task.date.day == _selectedDate.day &&
      task.isCompleted
    ).toList();
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
          onPressed: () => {},
          icon: Icon(Icons.arrow_back_ios, size: width * 0.06, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
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
                Icon(
                  _showCompletedTasks ? FeatherIcons.chevronDown : FeatherIcons.chevronRight,
                  size: 18,
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  '${completedTasks.length} Completed',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: Responsive.text(context, size: 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_showCompletedTasks)
            ...completedTasks.map((task) => _buildTaskItem(task)),
        ],
      ],
    );
  }

  Widget _buildTaskItem(TodoTask task) {
    final double opacity = task.isCompleted ? 0.4 : 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withOpacity(opacity),
              borderRadius: BorderRadius.circular(2),
            ),
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
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.time,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: Responsive.text(context, size: 14),
                    color: AppColors.textPrimary.withOpacity(task.isCompleted ? 0.3 : 0.6),
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              setState(() {
                task.isCompleted = value ?? false;
              });
            },
            activeColor: AppColors.textPrimary.withOpacity(opacity),
            side: BorderSide(color: AppColors.textPrimary.withOpacity(opacity), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final List<String> weekDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Center selected date in the week view (selected date is at index 3)
    final DateTime startOfWeek = _selectedDate.subtract(const Duration(days: 3));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final DateTime date = startOfWeek.add(Duration(days: index));
        final bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;

        // Get the correct weekday name (weekday is 1-7, Monday-Sunday)
        final String dayName = weekDayNames[date.weekday - 1];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Column(
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: isSelected ? 6 : 0,
                  height: isSelected ? 6 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
