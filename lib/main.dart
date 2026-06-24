import 'package:flutter/material.dart';

void main() {
  // Aquí inicializaremos configuraciones futuras (como Supabase)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CircleApp());
}

class CircleApp extends StatelessWidget {
  const CircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circle',
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5), // Nuestro Azul Índigo
          primary: const Color(0xFF3F51B5),
          secondary: const Color(0xFFFF9800), // Nuestro Naranja
        ),
        useMaterial3: true,
      ),
      home: const InitialScreen(),
    );
  }
}

// Pantalla temporal para verificar que todo funciona
class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circle: Conecta y Comparte', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_alt, size: 80, color: Color(0xFF3F51B5)),
            const SizedBox(height: 20),
            const Text(
              'Bienvenido a Circle',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'MVP en construcción...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Acción temporal
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Botón funcionando perfectamente')),
                );
              },
              child: const Text('Unirse a un evento'),
            )
          ],
        ),
      ),
    );
  }
}