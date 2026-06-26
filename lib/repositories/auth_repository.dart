import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:circle_app/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  User? get currentUser => _authService.currentUser;

  Future<AuthResponse> signUp(String email, String password, String username) {
    return _authService.signUp(email, password, username);
  }

  Future<AuthResponse> signIn(String email, String password) {
    return _authService.signIn(email, password);
  }

  Future<void> signOut() {
    return _authService.signOut();
  }

 Future<Map<String, dynamic>?> getUserProfile(String userId) async {
  // 🟢 Cambiado 'profiles' por 'users'
  final response = await Supabase.instance.client
      .from('users') 
      .select('id, username, bio, avatar_url')
      .eq('id', userId)
      .maybeSingle();
  return response;
}

  // NUEVO: Enlaza la ejecución del bloqueo
  Future<void> blockUser(String blockerId, String blockedId) async {
    await _authService.blockUser(blockerId, blockedId);
  }

  


  // NUEVO: Enlaza la consulta de la lista negra
  Future<List<String>> getBlockedUserIds(String blockerId) async {
    return await _authService.fetchBlockedUserIds(blockerId);
  }
}