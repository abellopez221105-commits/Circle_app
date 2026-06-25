// lib/models/comment_model.dart
class CommentModel {
  final String username;
  final String message;
  final DateTime createdAt;

  CommentModel({
    required this.username,
    required this.message,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Extraemos el username del join con la tabla 'users'
    final userData = json['users'] as Map<String, dynamic>?;
    return CommentModel(
      username: userData?['username'] ?? 'Usuario',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}