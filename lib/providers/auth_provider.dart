// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:circle_app/repositories/auth_repository.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Motor de compresión

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool _isUploadingAvatar = false;
  bool get isUploadingAvatar => _isUploadingAvatar;
  
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

  /// 🟢 MÓDULO 4: Selecciona, comprime e inyecta la foto en Storage y la tabla users
  Future<String?> uploadAndRefreshAvatar() async {
    final picker = ImagePicker();
    
    // 1. Abrir la galería para seleccionar la foto
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return null; // El usuario canceló la acción

    _isUploadingAvatar = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final userId = user?.id;
      if (userId == null) throw 'Usuario no autenticado';

      // 2. Optimización local de la imagen (Redimensionar y Comprimir)
      final File file = File(pickedFile.path);
      final Uint8List imageBytes = await file.readAsBytes();
      
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) throw 'No se pudo decodificar la imagen';

      // Redimensionamos de forma proporcional a un lienzo máximo de 500 px
      img.Image resizedImage = img.copyResize(
        decodedImage, 
        width: decodedImage.width > decodedImage.height ? 500 : null,
        height: decodedImage.height >= decodedImage.width ? 500 : null,
      );

      // Codificamos a un binario JPG estricto con calidad al 80% (~50KB de peso)
      final Uint8List optimizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 80));

      // 3. Subir al Storage de Supabase
      // Usamos el userId como nombre directo para forzar el reemplazo automático en el bucket
      final String fileName = userId; 
      
      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        optimizedBytes,
        fileOptions: const FileOptions(
          upsert: true, // Habilita sobreescritura automática por RLS
          contentType: 'image/jpeg',
        ),
      );

      // 4. Obtener la URL pública oficial y romper la caché del renderizador
      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      final String finalUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // 5. Actualizar la tabla relacional public.users
      await supabase
          .from('users')
          .update({'avatar_url': finalUrl})
          .eq('id', userId);

      // 6. Actualizar el estado local en vivo para evitar parpadeos o retrasos en la UI
      if (_userProfile != null) {
        _userProfile!['avatar_url'] = finalUrl;
      } else {
        _userProfile = {
          'id': userId,
          'avatar_url': finalUrl,
        };
      }

      _isUploadingAvatar = false;
      notifyListeners();
      return finalUrl;

    } catch (e) {
      _isUploadingAvatar = false;
      notifyListeners();
      debugPrint('Error en uploadAndRefreshAvatar: $e');
      rethrow;
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

      // 2. Actualizamos el estado local INMEDIATAMENTE manteniendo el avatar_url previo
      if (_userProfile != null) {
        _userProfile!['username'] = username.trim();
        _userProfile!['bio'] = bio.trim();
      } else {
        _userProfile = {
          'id': user!.id,
          'username': username.trim(),
          'bio': bio.trim(),
        };
      }

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