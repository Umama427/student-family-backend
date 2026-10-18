class FamilyModel {
  final String id;
  final String familyCode;
  final String familyName;
  final String fatherName;
  final String? motherName;
  final String primaryPhone;
  final String? email;
  final String? address;
  final String status;

  FamilyModel({
    required this.id,
    required this.familyCode,
    required this.familyName,
    required this.fatherName,
    this.motherName,
    required this.primaryPhone,
    this.email,
    this.address,
    required this.status,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['_id'] ?? '',
      familyCode: json['familyCode'] ?? '',
      familyName: json['familyName'] ?? '',
      fatherName: json['fatherName'] ?? '',
      motherName: json['motherName'],
      primaryPhone: json['primaryPhone'] ?? '',
      email: json['email'],
      address: json['address'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'familyName': familyName,
      'fatherName': fatherName,
      'motherName': motherName,
      'primaryPhone': primaryPhone,
      'email': email,
      'address': address,
    };
  }
}