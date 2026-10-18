class StudentModel {
  final String id;
  final String fullName;
  final String rollNumber;
  final String className;
  final String gender;
  final int siblingOrder;
  final double discountPercentage;
  final double monthlyTuitionFee;
  final String status;
  final dynamic familyId;
  final String? contactNumber; // ✅ ADDED

  StudentModel({
    required this.id,
    required this.fullName,
    required this.rollNumber,
    required this.className,
    required this.gender,
    required this.siblingOrder,
    required this.discountPercentage,
    required this.monthlyTuitionFee,
    required this.status,
    required this.familyId,
    this.contactNumber, // ✅ ADDED
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      className: json['className'] ?? '',
      gender: json['gender'] ?? '',
      siblingOrder: json['siblingOrder'] ?? 1,
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      monthlyTuitionFee: (json['monthlyTuitionFee'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      familyId: json['familyId'],
      contactNumber: json['contactNumber'], // ✅ ADDED
    );
  }

  String get familyName {
    if (familyId is Map) {
      return familyId['familyName'] ?? 'Unknown';
    }
    return 'N/A';
  }

  String get familyIdString {
    if (familyId is Map) {
      return familyId['_id'] ?? '';
    }
    return familyId?.toString() ?? '';
  }
}