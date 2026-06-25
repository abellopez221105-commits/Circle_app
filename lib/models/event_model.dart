// lib/models/event_model.dart
class EventModel {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String interestName;
  final DateTime dateTime;
  final String location;
  final int participantCount; // NUEVO
  final bool isParticipating; // NUEVO

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
  });

  factory EventModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final interestData = json['interests'] as Map<String, dynamic>?;
    
    // NUEVO: Extraemos la lista de participantes mapeada por el Join
    final participantsList = json['event_participants'] as List<dynamic>? ?? [];
    
    return EventModel(
      id: json['id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      title: json['title'] ?? 'Sin título',
      description: json['description'] ?? '',
      interestName: interestData?['name'] ?? 'General',
      dateTime: DateTime.parse(json['date_time'] ?? DateTime.now().toIso8601String()),
      location: json['location'] ?? 'Ubicación no especificada',
      participantCount: participantsList.length, // Total de filas encontradas
      isParticipating: participantsList.any((p) => p['user_id'] == currentUserId), // ¿Estoy ahí?
    );
  }
}