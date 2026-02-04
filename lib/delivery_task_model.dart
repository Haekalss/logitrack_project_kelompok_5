class DeliveryTask {
  final String id; // Ubah dari int ke String
  final String title;
  final bool isCompleted;
  final String? description; // Tambahkan field description

  // Constructor
  const DeliveryTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    this.description,
  });
  // Factory constructor untuk membuat instance dari JSON map
  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    return DeliveryTask(
      id: json['id']?.toString() ?? '0', // Convert to String
      title: json['title'] ?? 'No Title',
      isCompleted: json['completed'] ?? false,
      description: json['description'],
    );
  }

  // Method untuk convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': isCompleted,
      'description': description,
    };
  }
}
