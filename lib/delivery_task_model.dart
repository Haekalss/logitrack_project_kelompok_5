class DeliveryTask {
  final String id; // Ubah dari int ke String
  final String title;
  final bool isCompleted;
  final String? description; // Tambahkan field description
  final String? imagePath; // Path foto bukti
  final double? latitude; // GPS latitude
  final double? longitude; // GPS longitude
  final DateTime? completedAt; // Waktu diselesaikan

  // Constructor
  const DeliveryTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    this.description,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.completedAt,
  });
  // Factory constructor untuk membuat instance dari JSON map
  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    return DeliveryTask(
      id: json['id']?.toString() ?? '0', // Convert to String
      title: json['title'] ?? 'No Title',
      isCompleted: json['completed'] ?? false,
      description: json['description'],
      imagePath: json['image_path'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      completedAt: json['completed_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['completed_at']) 
          : null,
    );
  }

  // Method untuk convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': isCompleted,
      'description': description,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  // Copy with method untuk update
  DeliveryTask copyWith({
    String? id,
    String? title, 
    bool? isCompleted,
    String? description,
    String? imagePath,
    double? latitude,
    double? longitude,
    DateTime? completedAt,
  }) {
    return DeliveryTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
