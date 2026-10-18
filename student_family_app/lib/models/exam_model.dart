class ExamSubject {
  final String subjectName;
  final double totalMarks;
  final double passingMarks;

  ExamSubject({
    required this.subjectName,
    required this.totalMarks,
    required this.passingMarks,
  });

  factory ExamSubject.fromJson(Map<String, dynamic> json) {
    return ExamSubject(
      subjectName: json['subjectName'] ?? '',
      totalMarks: (json['totalMarks'] ?? 0).toDouble(),
      passingMarks: (json['passingMarks'] ?? 0).toDouble(),
    );
  }
}

class ExamModel {
  final String id;
  final String examName;
  final String examType;
  final String className;
  final List<ExamSubject> subjects;
  final DateTime examDate;
  final String academicYear;
  final String status;

  ExamModel({
    required this.id,
    required this.examName,
    required this.examType,
    required this.className,
    required this.subjects,
    required this.examDate,
    required this.academicYear,
    required this.status,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['_id'] ?? '',
      examName: json['examName'] ?? '',
      examType: json['examType'] ?? 'Other',
      className: json['className'] ?? '',
      subjects: (json['subjects'] as List? ?? [])
          .map((s) => ExamSubject.fromJson(s))
          .toList(),
      examDate: json['examDate'] != null
          ? DateTime.parse(json['examDate'])
          : DateTime.now(),
      academicYear: json['academicYear']?.toString() ?? '',
      status: json['status'] ?? 'Scheduled',
    );
  }
}