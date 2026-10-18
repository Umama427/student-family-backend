class AttendanceModel {
  final String id;
  final String type; // 'student' | 'staff'
  final dynamic refId; // String id OR populated Student/Staff map
  final String refModel; // 'Student' | 'Staff'
  final DateTime date;
  final String status; // Present | Absent | Leave | Late
  final String remarks;

  AttendanceModel({
    required this.id,
    required this.type,
    required this.refId,
    required this.refModel,
    required this.date,
    required this.status,
    required this.remarks,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'student',
      refId: json['refId'],
      refModel: json['refModel'] ?? 'Student',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      status: json['status'] ?? 'Present',
      remarks: json['remarks'] ?? '',
    );
  }

  String get refIdString {
    if (refId is Map) return refId['_id'] ?? '';
    return refId?.toString() ?? '';
  }

  String get refName {
    if (refId is Map) {
      return refId['fullName'] ?? refId['name'] ?? 'Unknown';
    }
    return 'N/A';
  }

  String get refSubtitle {
    if (refId is Map) {
      if (type == 'student') {
        final roll = refId['rollNumber'] ?? '';
        final cls = refId['className'] ?? '';
        return '$roll  •  Class $cls';
      } else {
        return refId['designation'] ?? refId['role'] ?? '';
      }
    }
    return '';
  }
}