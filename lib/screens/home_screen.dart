// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:circle_app/screens/explore_screen.dart';
import 'package:circle_app/screens/create_event_screen.dart';
import 'package:circle_app/screens/profile_screen.dart'; // NUEVO IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ExploreScreen(),
    const CreateEventScreen(),
    const ProfileScreen(), // REEMPLAZADO: Despliega el perfil real
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF3F51B5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Crear'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}