class StaffModel {
  final String id;
  final String name;
  final String designation;
  final String department;
  final double basicSalary;

  StaffModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.basicSalary,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: (json['_id'] ?? '').toString(),
      name: (json['fullName'] ?? '').toString(),          // Backend field: fullName
      designation: (json['designation'] ?? '').toString(),
      department: (json['department'] ?? 'General').toString(),
      basicSalary: double.tryParse('${json['baseSalary'] ?? 0}') ?? 0, // Backend field: baseSalary
    );
  }
}