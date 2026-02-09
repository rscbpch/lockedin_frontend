import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class WheelTimePicker extends StatefulWidget {
  final TimeOfDay? initialTime;

  const WheelTimePicker({super.key, this.initialTime});

  static Future<TimeOfDay?> show(BuildContext context, {TimeOfDay? initialTime}) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => WheelTimePicker(initialTime: initialTime),
    );
  }

  @override
  State<WheelTimePicker> createState() => _WheelTimePickerState();
}

class _WheelTimePickerState extends State<WheelTimePicker> {
  late int _selectedHour;   // 1–12
  late int _selectedMinute; // 0–59
  late int _selectedAmPm;   // 0 = AM, 1 = PM

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _amPmController;

  @override
  void initState() {
    super.initState();
    final time = widget.initialTime ?? TimeOfDay.now();

    _selectedAmPm = time.hour >= 12 ? 1 : 0;
    _selectedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    _selectedMinute = time.minute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
    _amPmController = FixedExtentScrollController(initialItem: _selectedAmPm);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _amPmController.dispose();
    super.dispose();
  }

  TimeOfDay _getSelectedTime() {
    int hour = _selectedHour;
    if (_selectedAmPm == 0) {
      // am
      if (hour == 12) hour = 0;
    } else {
      // pm
      if (hour != 12) hour += 12;
    }
    return TimeOfDay(hour: hour, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    const double itemExtent = 44;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _getSelectedTime()),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: itemExtent * 5,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    height: itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // hour (1–12)
                    Expanded(
                      child: _buildWheel(
                        controller: _hourController,
                        itemCount: 12,
                        itemExtent: itemExtent,
                        labelBuilder: (i) => '${i + 1}',
                        onChanged: (i) => setState(() => _selectedHour = i + 1),
                      ),
                    ),
                    // minute (00–59)
                    Expanded(
                      child: _buildWheel(
                        controller: _minuteController,
                        itemCount: 60,
                        itemExtent: itemExtent,
                        labelBuilder: (i) => i.toString().padLeft(2, '0'),
                        onChanged: (i) => setState(() => _selectedMinute = i),
                      ),
                    ),
                    // am/pm
                    Expanded(
                      child: _buildWheel(
                        controller: _amPmController,
                        itemCount: 2,
                        itemExtent: itemExtent,
                        labelBuilder: (i) => i == 0 ? 'AM' : 'PM',
                        onChanged: (i) => setState(() => _selectedAmPm = i),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required double itemExtent,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.6,
      perspective: 0.003,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = _isSelected(controller, index);
          return Center(
            child: Text(
              labelBuilder(index),
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: isSelected ? 22 : 18,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white38,
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSelected(FixedExtentScrollController controller, int index) {
    try {
      return controller.selectedItem == index;
    } catch (_) {
      return false;
    }
  }
}
