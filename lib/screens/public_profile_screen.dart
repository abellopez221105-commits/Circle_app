// lib/screens/public_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:circle_app/models/user_model.dart';

class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@${user.username ?? "Usuario"}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar con corona si es Premium
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE8EAF6),
                  child: Text(
                    (user.username ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5)),
                  ),
                ),
                if (user.isPremium)
                  const Positioned(
                    top: 0,
                    right: 4,
                    child: Icon(Icons.stars, color: Colors.amber, size: 28),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.username ?? 'Usuario Anónimo',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // 🌟 VISUALIZAR ESTRELLAS DEL USUARIO
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < user.stars.floor()
                          ? Icons.star_rounded
                          : (index < user.stars ? Icons.star_half_rounded : Icons.star_outline_rounded),
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  user.stars.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(indent: 32, endIndent: 32),
            
            // Biografía / Información
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sobre mí',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.bio ?? '¡Hola! Estoy listo para unirme a un Círculo.',
                      style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}