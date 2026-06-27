// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circle_app/providers/auth_provider.dart';
import 'package:circle_app/providers/event_provider.dart';
import 'package:circle_app/models/event_model.dart';
import 'package:circle_app/screens/event_details_screen.dart';
import 'package:circle_app/screens/premium_checkout_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? '';
      
      if (authProvider.userProfile == null || authProvider.userProfile!.isEmpty) {
        authProvider.loadUserProfile();
      }
      
      context.read<EventProvider>().loadEvents(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    
    final userId = authProvider.user?.id ?? '';
    final email = authProvider.user?.email ?? 'Sin correo';
    
    // Obtenemos el perfil dinámico inteligente
    final profile = authProvider.displayProfile;
    final username = profile['username'] ?? 'usuario';
    final bio = profile['bio'] ?? '¡Hola! Estoy usando Circle.';
    final String? avatarUrl = profile['avatar_url'];

    // Lectura del estado Premium en vivo
    final isPremium = profile['is_premium'] == true;
    final premiumUntilStr = profile['premium_until'];

    String formattedDate = '';
    if (premiumUntilStr != null) {
      try {
        final expiryDate = DateTime.parse(premiumUntilStr.toString());
        formattedDate = "${expiryDate.day}/${expiryDate.month}/${expiryDate.year}";
      } catch (_) {
        formattedDate = premiumUntilStr.toString();
      }
    }

    final misInscripciones = eventProvider.events.where((e) => e.isParticipating && e.creatorId != userId).toList();
    final misPublicaciones = eventProvider.events.where((e) => e.creatorId == userId).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Cerrar Sesión',
              onPressed: () => _showLogoutDialog(context, authProvider),
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF3F51B5),
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                          child: authProvider.isUploadingAvatar
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF3F51B5)),
                                )
                              : avatarUrl != null && avatarUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(36),
                                      child: Image.network(
                                        avatarUrl,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person, size: 40, color: Color(0xFF3F51B5));
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 40, color: Color(0xFF3F51B5)),
                        ),
                      ),
                      if (!authProvider.isUploadingAvatar)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              try {
                                final resultUrl = await context.read<AuthProvider>().uploadAndRefreshAvatar();
                                if (resultUrl != null && resultUrl.startsWith('Error') && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(resultUrl), backgroundColor: Colors.red),
                                  );
                                } else if (resultUrl != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('¡Foto de perfil actualizada con éxito!'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Color(0xFF3F51B5),
                              child: Icon(Icons.camera_alt, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '@$username',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Color(0xFF3F51B5), size: 24),
                              onPressed: () => _showEditProfileSheet(authProvider, username, bio),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        Text(email, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 6),
                        Text(
                          bio,
                          style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // SECCIÓN REFACTORIZADA: Actualización asíncrona garantizada al regresar
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 16.0),
              child: isPremium
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Premium Activo (Vence: $formattedDate)',
                            style: const TextStyle(
                              color: Color(0xFFB78103),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 20),
                      label: const Text(
                        'Actualizar a Premium ✨',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () async {
  // Esperamos a que la pantalla de pago se cierre
                      // 1. Esperamos a que la pantalla de pago se cierre
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PremiumCheckoutScreen()),
                        );

                        // 2. Si regresó a la pantalla, esperamos 400ms para asegurar que la DB impactó
                        if (context.mounted) {
                          await Future.delayed(const Duration(milliseconds: 400));
                          
                          // 3. Forzamos la recarga total que ahora incluye 'refreshUser()'
                          await context.read<AuthProvider>().loadUserProfile();
                         }
                      },
                    ),
            ),

            const TabBar(
              labelColor: Color(0xFF3F51B5),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF3F51B5),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(icon: Icon(Icons.star_border), text: 'Mis Círculos'),
                Tab(icon: Icon(Icons.maps_home_work_outlined), text: 'Mis Publicaciones'),
              ],
            ),

            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: authProvider.isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _buildEventList(misInscripciones, 'No te has unido a ningún círculo todavía.', Colors.blueGrey),
                          _buildEventList(misPublicaciones, 'No has organizado ningún encuentro aún.', Colors.indigo),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(AuthProvider authProvider, String currentName, String currentBio) {
    final nameController = TextEditingController(text: currentName);
    final bioController = TextEditingController(text: currentBio);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Editar Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      )
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      prefixText: '@ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un nombre de usuario' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: bioController,
                    maxLines: 3,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Biografía / Intereses',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(sheetContext); 
                        
                        final result = await authProvider.updateProfile(
                          username: nameController.text,
                          bio: bioController.text,
                        );

                        if (!mounted) return;

                        final isSuccess = result == 'success' || result == true || result.toString() == 'true';

                        if (isSuccess) {
                          await authProvider.loadUserProfile();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isSuccess ? '¡Perfil actualizado con éxito!' : 'Error: $result'),
                            backgroundColor: isSuccess ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventList(List<EventModel> list, String emptyMessage, Color themeColor) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final event = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.event, color: themeColor, size: 22),
            ),
            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(
              '${event.dateTime.day}/${event.dateTime.month} • ${event.location}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)),
              );
            },
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de Circle?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.handleSignOut();
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}