// lib/services/event_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // MODIFICADO: Agregamos event_participants(user_id) al select
  Future<List<dynamic>> fetchEvents() async {
    final response = await _supabase
        .from('events')
        .select('*, interests(name), event_participants(user_id)')
        .order('date_time', ascending: true);
    return response as List<dynamic>;
  }

  Future<List<dynamic>> fetchInterests() async {
    return await _supabase.from('interests').select('id, name').order('name', ascending: true);
  }

  Future<void> insertEvent(Map<String, dynamic> eventData) async {
    await _supabase.from('events').insert(eventData);
  }

  // NUEVO: Registra al usuario en el evento
  Future<void> joinEvent(String eventId, String userId) async {
    await _supabase.from('event_participants').insert({
      'event_id': eventId,
      'user_id': userId,
    });
  }

  // NUEVO: Elimina el registro de participación
  Future<void> leaveEvent(String eventId, String userId) async {
    await _supabase
        .from('event_participants')
        .delete()
        .match({'event_id': eventId, 'user_id': userId});
  }
  Future<void> reportEvent(String eventId, String reporterId, String reason) async {
    await _supabase.from('reports').insert({
      'event_id': eventId,
      'reporter_id': reporterId,
      'reason': reason,
    });
  }

  // NUEVO: Trae los comentarios en orden cronológico incluyendo el username del autor
  Future<List<dynamic>> fetchComments(String eventId) async {
    final response = await _supabase
        .from('event_comments')
        .select('*, users(username)')
        .eq('event_id', eventId)
        .order('created_at', ascending: true);
    return response as List<dynamic>;
  }

  // NUEVO: Inserta un comentario
  Future<void> insertComment(String eventId, String userId, String message) async {
    await _supabase.from('event_comments').insert({
      'event_id': eventId,
      'user_id': userId,
      'message': message,
    });
  }

  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId) async {
  try {
    // 💡 OPTIMIZACIÓN: Traemos estrictamente los campos necesarios para el perfil público y estrellas
    final response = await _supabase
        .from('event_participants') 
        .select('users (id, username, bio, avatar_url, stars, is_premium)')
        .eq('event_id', eventId);
    
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    throw Exception('Error optimizado en getEventParticipants: $e');
  }
}

}