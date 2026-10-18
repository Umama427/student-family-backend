class SubjectResult {
  final String subjectName;
  final double marksObtained;
  final double totalMarks;
  final String grade;

  SubjectResult({
    required this.subjectName,
    required this.marksObtained,
    required this.totalMarks,
    required this.grade,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      subjectName: json['subjectName'] ?? '',
      marksObtained: (json['marksObtained'] ?? 0).toDouble(),
      totalMarks: (json['totalMarks'] ?? 0).toDouble(),
      grade: json['grade'] ?? '',
    );
  }
}

class ResultModel {
  final String id;
  final String examId;
  final String studentId;
  final String studentName;
  final String className;
  final List<SubjectResult> subjects;
  final double totalMarksObtained;
  final double totalMaxMarks;
  final double percentage;
  final String overallGrade;
  final double gpa;
  final String status;
  final String remarks;
  final String? examName;

  ResultModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.subjects,
    required this.totalMarksObtained,
    required this.totalMaxMarks,
    required this.percentage,
    required this.overallGrade,
    required this.gpa,
    required this.status,
    required this.remarks,
    this.examName,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    String studentName = '';
    String studentId = '';
    if (json['studentId'] is Map) {
      studentName = json['studentId']['fullName'] ?? '';
      studentId = json['studentId']['_id'] ?? '';
    } else {
      studentId = json['studentId']?.toString() ?? '';
    }

    String? examName;
    String examId = '';
    if (json['examId'] is Map) {
      examName = json['examId']['examName'];
      examId = json['examId']['_id'] ?? '';
    } else {
      examId = json['examId']?.toString() ?? '';
    }

    return ResultModel(
      id: json['_id'] ?? '',
      examId: examId,
      studentId: studentId,
      studentName: studentName,
      className: json['className'] ?? '',
      subjects: (json['subjects'] as List? ?? [])
          .map((s) => SubjectResult.fromJson(s))
          .toList(),
      totalMarksObtained: (json['totalMarksObtained'] ?? 0).toDouble(),
      totalMaxMarks: (json['totalMaxMarks'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      overallGrade: json['overallGrade'] ?? '',
      gpa: (json['gpa'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pass',
      remarks: json['remarks'] ?? '',
      examName: examName,
    );
  }
}