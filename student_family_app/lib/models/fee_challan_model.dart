class FeeChallanModel {
  final String id;
  final String challanNumber;
  final dynamic studentId;
  final dynamic familyId;
  final int month;
  final int year;
  final double tuitionFee;
  final double discountPercentage;
  final double discountAmount;
  final double totalPayable;
  final DateTime dueDate;
  final String status;
  final double paidAmount;
  final String? paymentMethod;

  FeeChallanModel({
    required this.id,
    required this.challanNumber,
    required this.studentId,
    required this.familyId,
    required this.month,
    required this.year,
    required this.tuitionFee,
    required this.discountPercentage,
    required this.discountAmount,
    required this.totalPayable,
    required this.dueDate,
    required this.status,
    required this.paidAmount,
    this.paymentMethod,
  });

  factory FeeChallanModel.fromJson(Map<String, dynamic> json) {
    return FeeChallanModel(
      id: json['_id'] ?? '',
      challanNumber: json['challanNumber'] ?? '',
      studentId: json['studentId'],
      familyId: json['familyId'],
      month: json['month'] ?? 1,
      year: json['year'] ?? 2024,
      tuitionFee: (json['tuitionFee'] ?? 0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalPayable: (json['totalPayable'] ?? 0).toDouble(),
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'Pending',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
    );
  }

  String get studentName {
    if (studentId is Map) return studentId['fullName'] ?? 'Unknown';
    return 'N/A';
  }

  String get studentRoll {
    if (studentId is Map) return studentId['rollNumber'] ?? '';
    return '';
  }

  String get familyName {
    if (familyId is Map) return familyId['familyName'] ?? 'Unknown';
    return 'N/A';
  }

  String get familyPhone {
    if (familyId is Map) return familyId['primaryPhone'] ?? '';
    return '';
  }
}