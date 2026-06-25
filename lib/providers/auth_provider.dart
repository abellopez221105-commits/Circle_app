// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:circle_app/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  User? _user;
  Map<String, dynamic>? _userProfile; // Guardará localmente los datos de la tabla 'users'
  List<String> _blockedUserIds = [];
  bool _isLoading = false;

  Map<String, dynamic> get displayProfile {
    if (_userProfile != null && _userProfile!.isNotEmpty) {
      return _userProfile!;
    }
    
    // Si por alguna razón está vacío temporalmente, usa los metadatos de la sesión
    final metadata = user?.userMetadata;
    return {
      'username': metadata?['username'] ?? metadata?['name'] ?? user?.email?.split('@')[0] ?? 'usuario',
      'bio': '¡Hola! Estoy listo para unirme a un Circle.',
    };
  }
  
  User? get user => _user ?? _authRepository.currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<String> get blockedUserIds => _blockedUserIds;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => user != null;

  AuthProvider() {
    _user = _authRepository.currentUser;
    if (user != null) {
      loadUserProfile(); // Carga los datos de 'users' desde el inicio
    }
  }

  // 🟢 CORRECCIÓN: Cambiado para cargar desde el repositorio que lee la tabla 'users'
  Future<void> loadUserProfile() async {
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _userProfile = await _authRepository.getUserProfile(user!.id);
      _blockedUserIds = await _authRepository.getBlockedUserIds(user!.id);
    } catch (e) {
      debugPrint('Error al cargar perfil/bloqueos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> blockUser(String blockedId) async {
    if (user == null) return;
    try {
      await _authRepository.blockUser(user!.id, blockedId);
      _blockedUserIds.add(blockedId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al bloquear usuario: $e');
      rethrow;
    }
  }

  Future<String?> handleSignUp(String email, String password, String username) async {
    _setLoading(true);
    try {
      await _authRepository.signUp(email, password, username);
      _user = _authRepository.currentUser;
      await loadUserProfile();
      return null;
    } catch (e) {
      return e.toString().replaceAll('AuthException:', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> handleSignIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authRepository.signIn(email, password);
      _user = _authRepository.currentUser;
      await loadUserProfile();
      return null; 
    } catch (e) {
      return e.toString().replaceAll('AuthException:', '');
    } finally {
      _setLoading(false);
    }
  }

  // 🟢 CORRECCIÓN: Ahora hace el upsert apuntando directamente a la tabla 'users'
  Future<String> updateProfile({required String username, required String bio}) async {
    if (user == null) return 'No hay un usuario autenticado';
    
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Guardamos directamente en la tabla 'users'
      await Supabase.instance.client.from('users').upsert({
        'id': user!.id,
        'username': username.trim(),
        'bio': bio.trim(),
      });

      // 2. Actualizamos el estado local INMEDIATAMENTE
      _userProfile = {
        'id': user!.id,
        'username': username.trim(),
        'bio': bio.trim(),
      };

      _isLoading = false;
      notifyListeners(); 
      return 'success';
    } catch (e) {
      print("Error en updateProfile en tabla users: $e");
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> handleSignOut() async {
    await _authRepository.signOut();
    _user = null;
    _userProfile = null;
    _blockedUserIds = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}