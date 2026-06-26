// lib/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circle_app/providers/auth_provider.dart';
import 'package:circle_app/providers/event_provider.dart';
import 'package:circle_app/screens/event_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Estados locales para controlar los filtros en tiempo real
  String _searchQuery = '';
  dynamic _selectedInterestId; // null significa "Todos"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<EventProvider>().loadEvents(userId);
      context.read<EventProvider>().loadInterests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id ?? '';
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descubrir Encuentros', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Componente visual del Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Buscar círculos o actividades...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3F51B5)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Selector horizontal de Categorías (Intereses)
          _buildInterestsBar(eventProvider),
          
          const Divider(height: 1),

          // Contenido principal (Cartelera filtrada)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => eventProvider.loadEvents(userId),
              child: _buildBody(eventProvider, userId),
            ),
          ),
        ],
      ),
    );
  }

  // Generador de la barra horizontal de chips estilizables
  Widget _buildInterestsBar(EventProvider provider) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: provider.interests.length + 1, // +1 para la opción "Todos"
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedInterestId == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: const Text('Todos'),
                selected: isSelected,
                selectedColor: const Color(0xFF3F51B5).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF3F51B5),
                onSelected: (_) => setState(() => _selectedInterestId = null),
              ),
            );
          }

          final interest = provider.interests[index - 1];
          final isSelected = _selectedInterestId == interest['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(interest['name'] ?? ''),
              selected: isSelected,
              selectedColor: const Color(0xFF3F51B5).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF3F51B5),
              onSelected: (_) {
                setState(() {
                  _selectedInterestId = isSelected ? null : interest['id'];
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(EventProvider provider, String userId) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)));
    }

    final blockedIds = context.watch<AuthProvider>().blockedUserIds;

    final visibleEvents = provider.events.where((event) {
      // 1. Filtro de Seguridad
      final passesSecurity = !blockedIds.contains(event.creatorId) && event.creatorId != userId;
      
      // 2. Filtro de Intereses
      bool passesInterest = true;
      if (_selectedInterestId != null) {
        final selectedInterestName = provider.interests.firstWhere(
          (i) => i['id'].toString() == _selectedInterestId.toString(), 
          orElse: () => {'name': ''},
        )['name'];
        
        passesInterest = event.interestName.toLowerCase() == selectedInterestName.toString().toLowerCase();
      }

      // 3. Optimización del Buscador
      final passesSearch = event.title.toLowerCase().contains(_searchQuery) || 
                           event.description.toLowerCase().contains(_searchQuery) ||
                           event.interestName.toLowerCase().contains(_searchQuery);

      return passesSecurity && passesInterest && passesSearch;
    }).toList();

    if (visibleEvents.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No encontramos encuentros que coincidan\ncon tus filtros actuales.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: visibleEvents.length,
      itemBuilder: (context, index) {
        final event = visibleEvents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(event.interestName),
                        backgroundColor: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            '${event.dateTime.day}/${event.dateTime.month} - ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                            onSelected: (value) {
                              if (value == 'report') {
                                _showReportDialog(context, event.id, userId);
                              } else if (value == 'block') {
                                _showBlockConfirmation(context, event.creatorId);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    Icon(Icons.flag, color: Colors.red, size: 18),
                                    SizedBox(width: 8),
                                    Text('Reportar evento', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'block',
                                child: Row(
                                  children: [
                                    Icon(Icons.block, color: Colors.orange, size: 18),
                                    SizedBox(width: 8),
                                    Text('Bloquear organizador', style: TextStyle(color: Colors.orange)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(event.description, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.location, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // SECCIÓN CORREGIDA: Control de aforo e inhabilitación desde la cartelera
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, size: 20, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '${event.participantCount} / ${event.maxParticipants} cupos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: event.participantCount >= event.maxParticipants && !event.isParticipating
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Builder(
                        builder: (context) {
                          final bool isFull = event.participantCount >= event.maxParticipants;
                          final bool canJoin = !isFull || event.isParticipating;

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !canJoin 
                                  ? Colors.grey[300] 
                                  : (event.isParticipating ? Colors.grey[200] : const Color(0xFF3F51B5)),
                              foregroundColor: !canJoin
                                  ? Colors.grey[600]
                                  : (event.isParticipating ? Colors.red : Colors.white),
                              elevation: event.isParticipating || !canJoin ? 0 : 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: canJoin
                                ? () {
                                    provider.toggleEventParticipation(event.id, userId, event.isParticipating);
                                  }
                                : null, // Deshabilita el botón por completo
                            child: Text(
                              !canJoin 
                                  ? 'Círculo Lleno' 
                                  : (event.isParticipating ? 'Salir del Círculo' : 'Unirme'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, String eventId, String reporterId) {
    // Tu código del diálogo de reporte se mantiene aquí...
  }

  void _showBlockConfirmation(BuildContext context, String creatorId) {
    // Tu código del diálogo de bloqueo se mantiene aquí...
  }
}