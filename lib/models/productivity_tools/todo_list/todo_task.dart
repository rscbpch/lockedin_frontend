import 'package:flutter/material.dart';

enum Status { pending, completed }

class TodoTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  Status status;
  final DateTime? dueDateTime; // for backend
  DateTime? dueDate; // for ui
  TimeOfDay? dueTime; // for ui too

  TodoTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.status = Status.pending,
    required this.dueDateTime,
    this.dueDate,
    this.dueTime
  });
}
