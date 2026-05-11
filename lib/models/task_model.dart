import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String plantId;
  final String plantName;
  final String taskType;
  final DateTime dueDate;
  final bool isCompleted;
  final String notes;
  final String repeatType;
  final int repeatDays;

  Task({
    required this.id,
    this.plantId = '',
    required this.plantName,
    required this.taskType,
    required this.dueDate,
    required this.isCompleted,
    required this.notes,
    this.repeatType = 'none',
    this.repeatDays = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
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
      id: map['id']?.toString() ?? '',
      plantId: map['plantId']?.toString() ?? '',
      plantName: map['plantName']?.toString() ?? '',
      taskType: map['taskType']?.toString() ?? '',
      dueDate: map['dueDate'] is Timestamp 
          ? (map['dueDate'] as Timestamp).toDate() 
          : (map['dueDate'] is DateTime ? map['dueDate'] as DateTime : DateTime.now()),
      isCompleted: map['isCompleted'] == true,
      notes: map['notes']?.toString() ?? '',
      repeatType: map['repeatType']?.toString() ?? 'none',
      repeatDays: (map['repeatDays'] as num?)?.toInt() ?? 0,
    );
  }
}

