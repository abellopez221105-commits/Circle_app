import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener el usuario actual si existe autenticación activa
  User? get currentUser => _supabase.auth.currentUser;

  // Registro en Supabase Auth + Inserción en la tabla pública de perfiles (users)
  Future<AuthResponse> signUp(String email, String password, String username) async {
    // 1. Crea el usuario en el sistema de credenciales oculto de Supabase
    final response = await _supabase.auth.signUp(email: email, password: password);
    
    // 2. Si el usuario se creó con éxito, guardamos sus datos públicos en nuestra tabla 'users'
    if (response.user != null) {
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'username': username,
        'bio': '¡Hola! Estoy listo para unirme a un Circle.',
      });
    }
    return response;
  }

  // Inicio de Sesión
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Cierre de Sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle(); // Devuelve una sola fila o null si no existe
    return response;
  }

  // NUEVO: Inserta una relación de bloqueo en Supabase
  Future<void> blockUser(String blockerId, String blockedId) async {
    await _supabase.from('blocks').insert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });
  }

  // NUEVO: Recupera la lista de IDs de usuarios bloqueados por ti
  Future<List<String>> fetchBlockedUserIds(String blockerId) async {
    final response = await _supabase
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', blockerId);
    
    final data = response as List<dynamic>;
    return data.map((item) => item['blocked_id'] as String).toList();
  }
}