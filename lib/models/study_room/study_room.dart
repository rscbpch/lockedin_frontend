class StudyRoom {
  final String name;
  final String roomId;
  final int participantCount;

  const StudyRoom({
    required this.name,
    required this.roomId,
    required this.participantCount,
  });

  bool get isFull => participantCount >= 10;
  double get capacityRatio => participantCount / 10;

  factory StudyRoom.fromJson(Map<String, dynamic> json) => StudyRoom(
        name: json['name']?.toString() ?? '',
        roomId: (json['roomId'] ?? json['_id'])?.toString() ?? '',
        participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      );

  StudyRoom copyWith({int? participantCount}) => StudyRoom(
        name: name,
        roomId: roomId,
        participantCount: participantCount ?? this.participantCount,
      );
}