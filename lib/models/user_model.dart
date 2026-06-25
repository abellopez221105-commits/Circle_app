// lib/models/user_model.dart

class UserModel {
  final String id;
  final String? username;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final double stars;
  final bool isPremium;
  final List<String> blockedUserIds;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    this.username,
    this.email,
    this.bio,
    this.avatarUrl,
    this.stars = 5.0,
    this.isPremium = false,
    this.blockedUserIds = const [],
    this.createdAt,
  });

  /// Transforma el JSON proveniente de Supabase
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? 'Usuario',
      email: json['email'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      // Soportamos si Supabase devuelve las estrellas como int o double
      stars: (json['stars'] ?? 5.0).toDouble(),
      isPremium: json['is_premium'] ?? false,
      // Mapeamos de forma segura el array de texto de Postgres a una Lista de Dart
      blockedUserIds: json['blocked_user_ids'] != null
          ? List<String>.from(json['blocked_user_ids'])
          : [],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  /// Convierte el modelo a un mapa de datos para guardar o actualizar en Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'bio': bio,
      'avatar_url': avatarUrl,
      'stars': stars,
      'is_premium': isPremium,
      'blocked_user_ids': blockedUserIds,
    };
  }
}