import 'package:cloud_firestore/cloud_firestore.dart';

class TreatmentCase {
  final String id;
  final String plantId;
  final String plantName;
  final String diagnosis;

  /// One of: 'Mild', 'Moderate', 'Severe'
  final String severity;

  final DateTime detectedDate;

  /// One of: 'Active', 'Monitoring', 'Resolved'
  final String status;

  final List<String> treatmentSteps;
  final List<DateTime> followUpDates;
  final List<String> progressNotes;
  final DateTime? resolvedDate;
  final String initialPhotoUrl;
  final String latestPhotoUrl;

  TreatmentCase({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.diagnosis,
    required this.severity,
    required this.detectedDate,
    required this.status,
    required this.treatmentSteps,
    required this.followUpDates,
    required this.progressNotes,
    this.resolvedDate,
    required this.initialPhotoUrl,
    required this.latestPhotoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'plantName': plantName,
      'diagnosis': diagnosis,
      'severity': severity,
      'detectedDate': Timestamp.fromDate(detectedDate),
      'status': status,
      'treatmentSteps': treatmentSteps,
      'followUpDates': followUpDates.map((d) => Timestamp.fromDate(d)).toList(),
      'progressNotes': progressNotes,
      'resolvedDate':
          resolvedDate != null ? Timestamp.fromDate(resolvedDate!) : null,
      'initialPhotoUrl': initialPhotoUrl,
      'latestPhotoUrl': latestPhotoUrl,
    };
  }

  factory TreatmentCase.fromMap(Map<String, dynamic> map) {
    DateTime tsToDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    return TreatmentCase(
      id: map['id']?.toString() ?? '',
      plantId: map['plantId']?.toString() ?? '',
      plantName: map['plantName']?.toString() ?? '',
      diagnosis: map['diagnosis']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'Moderate',
      detectedDate: tsToDate(map['detectedDate']),
      status: map['status']?.toString() ?? 'Active',
      treatmentSteps: (map['treatmentSteps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      followUpDates: (map['followUpDates'] as List<dynamic>?)
              ?.map((e) => tsToDate(e))
              .toList() ??
          [],
      progressNotes: (map['progressNotes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      resolvedDate:
          map['resolvedDate'] != null ? tsToDate(map['resolvedDate']) : null,
      initialPhotoUrl: map['initialPhotoUrl']?.toString() ?? '',
      latestPhotoUrl: map['latestPhotoUrl']?.toString() ?? '',
    );
  }
}
