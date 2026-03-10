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
        name: json['name'] as String,
        roomId: json['roomId'] as String,
        participantCount: json['participantCount'] as int,
      );

  StudyRoom copyWith({int? participantCount}) => StudyRoom(
        name: name,
        roomId: roomId,
        participantCount: participantCount ?? this.participantCount,
      );
}