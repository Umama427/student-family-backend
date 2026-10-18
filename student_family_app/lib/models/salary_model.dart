class SalaryModel {
  final String id;
  final dynamic staffId;
  final String month;
  final int year;
  final double bonus;
  final double deductions;
  final double netSalary;
  final String status;

  SalaryModel({
    required this.id,
    required this.staffId,
    required this.month,
    required this.year,
    required this.bonus,
    required this.deductions,
    required this.netSalary,
    required this.status,
  });

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    return SalaryModel(
      id: json['_id'] ?? '',
      staffId: json['staffId'],
      month: json['month']?.toString() ?? '',
      year: json['year'] ?? 2024,
      bonus: (json['bonus'] ?? 0).toDouble(),
      deductions: (json['deductions'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unpaid',
    );
  }

  String get staffName {
    if (staffId is Map) return staffId['name'] ?? 'Unknown';
    return 'N/A';
  }
}