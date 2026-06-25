// lib/screens/event_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circle_app/models/event_model.dart';
import 'package:circle_app/providers/auth_provider.dart';
import 'package:circle_app/providers/event_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadComments(widget.event.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id ?? '';
    final eventProvider = context.watch<EventProvider>();
    final comments = eventProvider.comments;

    return Scaffold(
      appBar: AppBar(title: Text(widget.event.title)),
      body: Column(
        children: [
          // Bloque de información del Evento
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.grey[50],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.event.description, style: const TextStyle(fontSize: 15, height: 1.4)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 18, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(child: Text(widget.event.location, style: const TextStyle(fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.forum_outlined, size: 18, color: Color(0xFF3F51B5)),
                SizedBox(width: 8),
                Text('Coordinación del Círculo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          // Lista de comentarios
          Expanded(
            child: comments.isEmpty
                ? const Center(child: Text('No hay mensajes de coordinación todavía.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('@${comment.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3F51B5))),
                                const SizedBox(width: 8),
                                Text('${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                              child: Text(comment.message, style: const TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Caja de texto inferior fija para comentar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, -2))]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: 'Pregunta o coordina algo...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8)),
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
        ],
      ),
    );
  }
}