import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:lockedin_frontend/models/productivity_tools/todo_list/todo_task.dart';
import 'package:lockedin_frontend/services/todo_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/pickers/date_picker.dart';
import 'package:lockedin_frontend/ui/widgets/pickers/wheel_time_picker.dart';

/// unified modal for creating, viewing, and editing task
class TodoTaskModal extends StatefulWidget {
  final TodoTask? task;
  final DateTime? selectedDate;
  final VoidCallback onChanged;

  const TodoTaskModal({
    super.key,
    this.task,
    this.selectedDate,
    required this.onChanged,
  });

  static Future<void> showCreate(
    BuildContext context, {
    required DateTime selectedDate,
    required VoidCallback onChanged,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: TodoTaskModal(
          selectedDate: selectedDate,
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Future<void> showDetail(
    BuildContext context, {
    required TodoTask task,
    required VoidCallback onChanged,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: TodoTaskModal(
          task: task,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  State<TodoTaskModal> createState() => _TodoTaskModalState();
}

class _TodoTaskModalState extends State<TodoTaskModal> {
  late bool _isEditing;
  bool _isSaving = false;

  late TextEditingController _titleController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool get _isCreateMode => widget.task == null;

  @override
  void initState() {
    super.initState();
    _isEditing = _isCreateMode;

    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _selectedDate = widget.task?.dueDate ?? widget.task?.dueDateTime ?? widget.selectedDate;
    _selectedTime = widget.task?.dueTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: DatePicker(
          initialDate: _selectedDate ?? DateTime.now(),
          onDateSelected: (date) {
            setState(() => _selectedDate = date);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await WheelTimePicker.show(context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final dueDate = _buildDueDate();

      if (_isCreateMode) {
        await TodoService.createTodo(title: title, dueDate: dueDate);
      } else {
        await TodoService.updateTodo(widget.task!.id, title: title, dueDate: dueDate);
      }

      widget.onChanged();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isCreateMode ? 'Failed to create task' : 'Failed to update task')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  DateTime? _buildDueDate() {
    if (_selectedDate == null) return null;
    if (_selectedTime != null) {
      return DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }
    return _selectedDate;
  }

  String _formatFullDate(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'am' : 'pm';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: _isEditing ? _buildFormView() : _buildDetailView(),
    );
  }

  Widget _buildDetailView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.task!.title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: Responsive.text(context, size: 18),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Icon(
                FeatherIcons.edit2,
                size: 18,
                color: AppColors.textPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_selectedDate != null) ...[
          _buildInfoRow(
            icon: FeatherIcons.calendar,
            label: 'Date',
            value: _formatFullDate(_selectedDate!),
          ),
          const SizedBox(height: 16),
        ],
        if (_selectedTime != null)
          _buildInfoRow(
            icon: FeatherIcons.clock,
            label: 'Time',
            value: _formatTime(_selectedTime!),
          ),
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: Responsive.text(context, size: 16),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: Responsive.text(context, size: 14),
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          autofocus: true,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 18),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Task name',
            hintStyle: TextStyle(
              fontFamily: 'Nunito',
              fontSize: Responsive.text(context, size: 18),
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary.withOpacity(0.4),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(left: 12),
            prefixIcon: Container(
              width: 3,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 3, minHeight: 28),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildChip(
              icon: FeatherIcons.calendar,
              label: _selectedDate != null ? _formatShortDate(_selectedDate!) : 'Add date',
              onTap: _pickDate,
            ),
            _buildChip(
              icon: FeatherIcons.clock,
              label: _selectedTime != null ? _formatTime(_selectedTime!) : 'Add time',
              onTap: _pickTime,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                    )
                  : Text(
                      _isCreateMode ? 'Add to list' : 'Save',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: Responsive.text(context, size: 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundBox,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
