// lib/providers/event_provider.dart
import 'package:flutter/material.dart';
import 'package:circle_app/models/event_model.dart';
import 'package:circle_app/repositories/event_repository.dart';
import 'package:circle_app/models/comment_model.dart';
import 'package:circle_app/models/user_model.dart';

class EventProvider extends ChangeNotifier {
  final EventRepository _eventRepository = EventRepository();

  List<EventModel> _events = [];
  List<Map<String, dynamic>> _interests = [];
  List<CommentModel> _comments = [];
  List<CommentModel> get comments => _comments;
  bool _isLoading = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  List<Map<String, dynamic>> get interests => _interests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<UserModel> _currentParticipants = [];
  List<UserModel> get currentParticipants => _currentParticipants;

  bool _isLoadingParticipants = false;
  bool get isLoadingParticipants => _isLoadingParticipants;

  // 🟢 NUEVO: Estado de carga específico para la acción del botón de inscripción
  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  Future<void> loadEventParticipants(String eventId) async {
    _isLoadingParticipants = true;
    notifyListeners();
    try {
      _currentParticipants = await _eventRepository.getParticipants(eventId);
    } catch (e) {
      print('Error al cargar participantes en el provider: $e');
    } finally {
      _isLoadingParticipants = false;
      notifyListeners();
    }
  }

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

  // 🟢 OPTIMIZADO: Ahora maneja estados de carga locales y refresca los participantes del círculo al instante
  Future<void> toggleEventParticipation(String eventId, String userId, bool isCurrentlyParticipating) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      // Si ya participa, pasa false (salir). Si no participa, pasa true (unirse).
      await _eventRepository.toggleParticipation(eventId, userId, !isCurrentlyParticipating);
      
      // Sincronizamos en paralelo el estado global de eventos y los avatares del círculo actual
      await Future.wait([
        loadEvents(userId),
        loadEventParticipants(eventId),
      ]);
    } catch (e) {
      debugPrint('Error al cambiar participación: $e');
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> reportEvent(String eventId, String reporterId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('🚀 Enviando reporte - EventID: $eventId, ReporterID: $reporterId, Razón: $reason');
      await _eventRepository.sendReport(eventId, reporterId, reason);
      print('✅ Reporte enviado con éxito a la base de datos.');
      return null;
    } catch (e) {
      print('❌ Error atrapado en EventProvider.reportEvent: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadComments(String eventId) async {
    _comments = [];
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
      await loadComments(eventId);
    } catch (e) {
      debugPrint('Error al comentar: $e');
    }
  }
}