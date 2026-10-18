class AuditLogModel {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String module;
  final String description;
  final String? targetId;
  final String? ipAddress;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    required this.description,
    this.targetId,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    String userId = '';
    if (json['user'] is Map) {
      userId = json['user']['_id'] ?? '';
    } else {
      userId = json['user']?.toString() ?? '';
    }

    return AuditLogModel(
      id: json['_id'] ?? '',
      userId: userId,
      userName: json['userName'] ?? 'Unknown',
      action: json['action'] ?? '',
      module: json['module'] ?? '',
      description: json['description'] ?? '',
      targetId: json['targetId']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}