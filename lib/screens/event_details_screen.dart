import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circle_app/models/event_model.dart';
import 'package:circle_app/providers/auth_provider.dart';
import 'package:circle_app/providers/event_provider.dart';
import 'package:circle_app/screens/public_profile_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final eventProvider = context.read<EventProvider>();
      eventProvider.loadComments(widget.event.id);
      
      if (mounted) {
        eventProvider.loadEventParticipants(widget.event.id);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showEditPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pantalla de edición (Formulario precargado) próximamente en el Módulo 4.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id ?? '';
    final eventProvider = context.watch<EventProvider>();
    final comments = eventProvider.comments;

    final isOrganizer = widget.event.creatorId == userId;
    final isParticipating = eventProvider.currentParticipants.any((p) => p.id == userId) || isOrganizer;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // 🟢 CONFIGURACIÓN CLAVE: Permite que el Scaffold se adapte dinámicamente al teclado
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        title: const Text('Detalles del Círculo', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (isOrganizer)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF3F51B5)),
              tooltip: 'Editar encuentro',
              onPressed: _showEditPlaceholder,
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── SECCIÓN SUPERIOR DESLIZABLE (EVITA EL OVERFLOW) ───
          // Usamos Flexible para que ocupe el espacio disponible pero se encoja si el teclado sube
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabecera de detalles del evento
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6, 
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.event.interestName.toUpperCase(),
                                style: const TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                              ),
                            ),
                            if (isOrganizer)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                    const SizedBox(width: 4),
                                    Text('Organizador', style: TextStyle(color: Colors.amber[900], fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.event.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.event.description,
                          style: TextStyle(fontSize: 15, height: 1.4, color: Colors.grey[800]),
                        ),
                        const Divider(height: 28),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 20, color: Color(0xFF3F51B5)),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.event.dateTime.day}/${widget.event.dateTime.month}/${widget.event.dateTime.year} a las ${widget.event.dateTime.hour}:${widget.event.dateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.place, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.event.location,
                                style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botón de acción adaptativo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Consumer<EventProvider>(
                      builder: (context, provider, child) {
                        final currentCount = provider.currentParticipants.length;
                        final maxCount = widget.event.maxParticipants;
                        final isFull = currentCount >= maxCount;

                        VoidCallback? onPressedAction;
                        String buttonText = '';
                        Color buttonBgColor = const Color(0xFF3F51B5);
                        BorderSide buttonBorder = const BorderSide(color: Color(0xFF3F51B5));
                        Color textColor = Colors.white;

                        if (provider.isActionLoading) {
                          onPressedAction = null;
                        } else if (isOrganizer) {
                          onPressedAction = _showEditPlaceholder;
                          buttonText = 'Configurar Parámetros del Círculo';
                          buttonBgColor = Colors.grey[100]!;
                          buttonBorder = BorderSide(color: Colors.grey[400]!);
                          textColor = Colors.black87;
                        } else if (isParticipating) {
                          onPressedAction = () => provider.toggleEventParticipation(widget.event.id, userId, true);
                          buttonText = 'Abandonar este Círculo';
                          buttonBgColor = Colors.transparent;
                          buttonBorder = const BorderSide(color: Colors.red);
                          textColor = Colors.red;
                        } else if (isFull) {
                          onPressedAction = null;
                          buttonText = 'Cupos agotados ($currentCount/$maxCount)';
                          buttonBgColor = Colors.grey[300]!;
                          buttonBorder = BorderSide(color: Colors.grey[300]!);
                          textColor = Colors.grey[600]!;
                        } else {
                          onPressedAction = () => provider.toggleEventParticipation(widget.event.id, userId, false);
                          buttonText = 'Inscribirme en el Círculo';
                        }

                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: onPressedAction,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: buttonBgColor,
                              side: buttonBorder,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: provider.isActionLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5))))
                                : Text(buttonText, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        );
                      },
                    ),
                  ),

                  // Lista horizontal de participantes
                  Consumer<EventProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoadingParticipants) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
                            child: Text(
                              'Miembros Inscritos (${provider.currentParticipants.length} / ${widget.event.maxParticipants})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                            ),
                          ),
                          SizedBox(
                            height: 76,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              itemCount: provider.currentParticipants.length,
                              itemBuilder: (context, index) {
                                final participant = provider.currentParticipants[index];
                                final displayName = participant.username ?? 'Miembro';
                                final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';
                                final firstName = displayName.split(' ').first;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => PublicProfileScreen(user: participant)),
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                                          child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 55,
                                          child: Text(firstName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ─── CHAT PROTEGIDO (SE QUEDA FIJO ABAJO REACCIONANDO AL TECLADO) ───
          Expanded(
            child: !isParticipating
                ? Container(
                    color: Colors.grey[100],
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'Coordinación Privada',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Únete a este encuentro para desbloquear el canal de comunicación del equipo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            const Text('Canal de Coordinación', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: comments.isEmpty
                            ? const Center(child: Text('No hay mensajes todavía. ¡Sé el primero!', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('@${comment.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3F51B5))),
                                          const SizedBox(height: 2),
                                          Text(comment.message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: SafeArea(
                          top: false, // Protege el espacio en dispositivos con navegación por gestos
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(hintText: 'Escribe un mensaje al grupo...', border: InputBorder.none),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFF3F51B5)),
                                onPressed: () {
                                  final msg = _commentController.text.trim();
                                  if (msg.isNotEmpty) {
                                    eventProvider.addComment(widget.event.id, userId, msg);
                                    _commentController.clear();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}