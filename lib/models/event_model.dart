// lib/models/event_model.dart
class EventModel {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String interestName;
  final DateTime dateTime;
  final String location;
  final int participantCount; 
  final bool isParticipating; 
  final int maxParticipants; // 🟢 NUEVO CAMPO

  EventModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.interestName,
    required this.dateTime,
    required this.location,
    required this.participantCount,
    required this.isParticipating,
    required this.maxParticipants, // 🟢 AGREGAR AL CONSTRUCTOR
  });

  factory EventModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final interestData = json['interests'] as Map<String, dynamic>?;
    final participantsList = json['event_participants'] as List<dynamic>? ?? [];
    
    return EventModel(
      id: json['id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      title: json['title'] ?? 'Sin título',
      description: json['description'] ?? '',
      interestName: interestData?['name'] ?? 'General',
      dateTime: DateTime.parse(json['date_time'] ?? DateTime.now().toIso8601String()),
      location: json['location'] ?? 'Ubicación no especificada',
      participantCount: participantsList.length, 
      isParticipating: participantsList.any((p) => p['user_id'] == currentUserId),
      // 🟢 MAPEAMOS EL VALOR REAL DE LA BASE DE DATOS (Por defecto 10 si viene nulo)
      maxParticipants: json['max_participants'] ?? 10, 
    );
  }
}