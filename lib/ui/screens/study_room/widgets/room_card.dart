import 'package:flutter/material.dart';
import '../../../../models/study_room/study_room.dart';
import '../lobby_screen.dart';
import '../../../theme/app_theme.dart';

class RoomCard extends StatelessWidget {
  final StudyRoom room;
  final int index;
  final VoidCallback onJoin;

  const RoomCard({
    super.key,
    required this.room,
    required this.index,
    required this.onJoin,
  });

  Color _hueColor() {
    final hues = [180, 227, 150, 270, 30, 330];
    final h = hues[index % hues.length].toDouble();
    return HSLColor.fromAHSL(1, h, 0.7, 0.55).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _hueColor();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Top accent line
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, accentColor, Colors.transparent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        room.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(
                    room.roomId,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: room.capacityRatio,
                              backgroundColor: AppColors.backgroundBox,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${room.participantCount}/10',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _JoinButton(isFull: room.isFull, onJoin: onJoin),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool isFull;
  final VoidCallback onJoin;

  const _JoinButton({required this.isFull, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isFull ? null : onJoin,
      style: ElevatedButton.styleFrom(
        backgroundColor: isFull ? AppColors.backgroundBox : AppColors.accent,
        foregroundColor: isFull ? AppColors.grey : Colors.black,
        disabledBackgroundColor: AppColors.backgroundBox,
        disabledForegroundColor: AppColors.grey ,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      child: Text(isFull ? 'Full' : 'Join →'),
    );
  }
}
