import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String plantName;
  final String taskType;
  final DateTime dueDate;
  final bool isCompleted;
  final String notes;
  final String? repeatType;
  final List<String>? repeatDays;

  Task({
    required this.id,
    required this.plantName,
    required this.taskType,
    required this.dueDate,
    required this.isCompleted,
    required this.notes,
    this.repeatType,
    this.repeatDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantName': plantName,
      'taskType': taskType,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
      'notes': notes,
      'repeatType': repeatType,
      'repeatDays': repeatDays,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      plantName: map['plantName'] ?? '',
      taskType: map['taskType'] ?? '',
      dueDate: map['dueDate'] is Timestamp 
          ? (map['dueDate'] as Timestamp).toDate() 
          : DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'] ?? '',
      repeatType: map['repeatType'],
      repeatDays: map['repeatDays'] != null ? List<String>.from(map['repeatDays']) : null,
    );
  }
}

