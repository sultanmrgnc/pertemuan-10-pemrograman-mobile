class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int? targetId;
  final String? deviceToken;
  final String? createdAt;
  final String? updatedAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.targetId,
    this.deviceToken,
    this.createdAt,
    this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      targetId: json['target_id'] != null
          ? (json['target_id'] is String
              ? int.parse(json['target_id'])
              : json['target_id'])
          : null,
      deviceToken: json['device_token'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead ? 1 : 0,
    };

    if (id > 0) {
      data['id'] = id;
    }

    if (targetId != null) {
      data['target_id'] = targetId;
    }

    if (deviceToken != null && deviceToken!.isNotEmpty) {
      data['device_token'] = deviceToken;
    }

    return data;
  }

  // Helper untuk mendapatkan icon berdasarkan tipe notifikasi
  String get iconName {
    switch (type) {
      case 'berita_baru':
        return 'newspaper';
      case 'update':
        return 'refresh';
      case 'info':
        return 'info';
      default:
        return 'notifications';
    }
  }
}
