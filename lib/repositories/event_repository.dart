// lib/repositories/event_repository.dart
import 'package:circle_app/models/event_model.dart';
import 'package:circle_app/services/event_service.dart';
import 'package:circle_app/models/comment_model.dart';
import 'package:circle_app/models/user_model.dart'; // 💡 AGREGA ESTA LÍNEA

class EventRepository {
  final EventService _eventService = EventService();

  // MODIFICADO: Ahora requiere el currentUserId para mapear correctamente el estado
 // Permanece limpio y óptimo
  Future<List<EventModel>> getEvents(String currentUserId) async {
    final data = await _eventService.fetchEvents(); // Ya viene filtrado desde Supabase
    return data.map((json) => EventModel.fromJson(json, currentUserId)).toList();
  }
  Future<List<Map<String, dynamic>>> getInterests() async {
    final data = await _eventService.fetchInterests();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> saveEvent(Map<String, dynamic> eventData) async {
    await _eventService.insertEvent(eventData);
  }

  // NUEVO: Llama al servicio correspondiente según la acción solicitada
  Future<void> toggleParticipation(String eventId, String userId, bool isJoining) async {
    if (isJoining) {
      await _eventService.joinEvent(eventId, userId);
    } else {
      await _eventService.leaveEvent(eventId, userId);
    }
  }

  Future<void> sendReport(String eventId, String reporterId, String reason) async {
    await _eventService.reportEvent(eventId, reporterId, reason);
  }

  Future<List<CommentModel>> getComments(String eventId) async {
    final data = await _eventService.fetchComments(eventId);
    return data.map((json) => CommentModel.fromJson(json)).toList();
  }

  // NUEVO: Enlace para guardar comentarios
  Future<void> saveComment(String eventId, String userId, String message) async {
    await _eventService.insertComment(eventId, userId, message);
  }

  Future<List<UserModel>> getParticipants(String eventId) async {
  try {
    final data = await _eventService.getEventParticipants(eventId);
    
    return data.map((item) {
      final usersData = item['users'];
      
      if (usersData != null) {
        if (usersData is Map<String, dynamic>) {
          return UserModel.fromJson(usersData);
        } else if (usersData is List && usersData.isNotEmpty) {
          return UserModel.fromJson(usersData.first as Map<String, dynamic>);
        }
      }
      return null;
    })
    .whereType<UserModel>() // Remueve cualquier mapeo nulo o fallido
    .toList();
    
  } catch (e) {
    print('Error mapeando participantes: $e');
    return [];
  }
}
}