import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class DatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const DatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<DatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<DatePicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  final List<String> _months = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + delta,
      );
    });
  }

  List<DateTime> _daysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysBefore = firstDay.weekday % 7; // sunday = 0
    final lastDay =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    return List.generate(
      daysBefore + lastDay.day,
      (index) => index < daysBefore
          ? DateTime(0)
          : DateTime(
              _currentMonth.year,
              _currentMonth.month,
              index - daysBefore + 1,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),

              Row(
                children: [
                  //month dropdown
                  DropdownButton<String>(
                    value: _months[_currentMonth.month - 1],
                    underline: const SizedBox(),
                    items: _months
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m,
                              style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w500,
                              fontSize: Responsive.text(context, size: 16)
                            ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      final index = _months.indexOf(value!);
                      setState(() {
                        _currentMonth =
                            DateTime(_currentMonth.year, index + 1);
                      });
                    },
                    dropdownColor: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  const SizedBox(width: 8),
                  // year dropdown
                  DropdownButton<int>(
                    value: _currentMonth.year,
                    underline: const SizedBox(),
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem(
                        value: 2020 + i,
                        child: Text(
                          '${2020 + i}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                            fontSize: Responsive.text(context, size: 16)
                          ),
                        ),
                      ),
                    ),
                    onChanged: (year) {
                      setState(() {
                        _currentMonth =
                            DateTime(year!, _currentMonth.month);
                      });
                    },
                    dropdownColor: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // month row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                          fontSize: Responsive.text(context, size: 14),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          /// days gird
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              if (date.year == 0) return const SizedBox();

              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  widget.onDateSelected(date);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}