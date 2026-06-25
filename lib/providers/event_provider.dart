// lib/providers/event_provider.dart
import 'package:flutter/material.dart';
import 'package:circle_app/models/event_model.dart';
import 'package:circle_app/repositories/event_repository.dart';
import 'package:circle_app/models/comment_model.dart';

class EventProvider extends ChangeNotifier {
  final EventRepository _eventRepository = EventRepository();

  List<EventModel> _events = [];
  List<Map<String, dynamic>> _interests = [];
  List<CommentModel> _comments = []; // NUEVO
  List<CommentModel> get comments => _comments;
  bool _isLoading = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  List<Map<String, dynamic>> get interests => _interests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // MODIFICADO: Ahora solicita el ID de usuario para personalizar el resultado
  Future<void> loadEvents(String currentUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _events = await _eventRepository.getEvents(currentUserId);
    } catch (e) {
      _errorMessage = 'Error al cargar eventos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInterests() async {
    if (_interests.isNotEmpty) return;
    try {
      _interests = await _eventRepository.getInterests();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando intereses: $e');
    }
  }

  // MODIFICADO: Enviamos el ID del creador al recargar la lista
  Future<String?> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _eventRepository.saveEvent(eventData);
      await loadEvents(eventData['creator_id']);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NUEVO: Procesa la inscripción/cancelación y refresca el estado visual al instante
  Future<void> toggleEventParticipation(String eventId, String userId, bool isCurrentlyParticipating) async {
    try {
      // Si ya participa, la acción es salir (isJoining = false). Si no participa, es unirse (isJoining = true).
      await _eventRepository.toggleParticipation(eventId, userId, !isCurrentlyParticipating);
      // Recargamos el listado local para que se actualicen los contadores y colores
      await loadEvents(userId);
    } catch (e) {
      debugPrint('Error al cambiar participación: $e');
    }
  }
Future<String?> reportEvent(String eventId, String reporterId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Mensaje de depuración para la consola de VS Code
      print('🚀 Enviando reporte - EventID: $eventId, ReporterID: $reporterId, Razón: $reason');
      
      // Enviamos los parámetros al repositorio
      await _eventRepository.sendReport(eventId, reporterId, reason);
      
      print('✅ Reporte enviado con éxito a la base de datos.');
      return null; // Éxito
    } catch (e) {
      print('❌ Error atrapado en EventProvider.reportEvent: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadComments(String eventId) async {
    _comments = []; // Limpieza rápida para evitar parpadeos de eventos anteriores
    notifyListeners();
    try {
      _comments = await _eventRepository.getComments(eventId);
    } catch (e) {
      debugPrint('Error cargando comentarios: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> addComment(String eventId, String userId, String message) async {
    try {
      await _eventRepository.saveComment(eventId, userId, message);
      await loadComments(eventId); // Refresco inmediato
    } catch (e) {
      debugPrint('Error al comentar: $e');
    }
  }
}