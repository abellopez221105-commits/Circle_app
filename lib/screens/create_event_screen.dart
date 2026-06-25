// lib/screens/create_event_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circle_app/providers/auth_provider.dart';
import 'package:circle_app/providers/event_provider.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  
  int? _selectedInterestId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadInterests();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedInterestId != null) {
      final authProvider = context.read<AuthProvider>();
      final eventProvider = context.read<EventProvider>();

      // Combinamos la fecha y hora seleccionadas en un solo objeto DateTime
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final eventData = {
        'creator_id': authProvider.user?.id,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'interest_id': _selectedInterestId,
        'date_time': fullDateTime.toIso8601String(),
        'location': _locationController.text.trim(),
      };

      final error = await eventProvider.createEvent(eventData);

      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Evento publicado con éxito!'), backgroundColor: Colors.green),
        );
        // Limpiamos el formulario
        _titleController.clear();
        _descController.clear();
        _locationController.clear();
        setState(() => _selectedInterestId = null);
      }
    } else if (_selectedInterestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final interests = context.watch<EventProvider>().interests;
    final isLoading = context.watch<EventProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Encuentro', style: TextStyle(fontWeight: FontWeight.bold))),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título del evento', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                    validator: (value) => value == null || value.isEmpty ? 'Ingresa un título descriptivo' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedInterestId,
                    decoration: const InputDecoration(labelText: 'Categoría o Interés', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                    items: interests.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'],
                        child: Text(item['name']),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedInterestId = val),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: '¿De qué trata el encuentro?', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                    validator: (value) => value == null || value.isEmpty ? 'Cuéntale a la comunidad de qué trata' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Lugar de encuentro', border: OutlineInputBorder(), prefixIcon: Icon(Icons.place)),
                    validator: (value) => value == null || value.isEmpty ? 'Especifica un punto de reunión seguro' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month),
                          label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _submitForm,
                    child: const Text('Publicar Círculo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}