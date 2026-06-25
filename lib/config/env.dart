import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // Leemos las variables del archivo .env
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'No URL found';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'No Key found';
  
  // Función para inicializar el lector de entorno
  static Future<void> initEnvironment() async {
    await dotenv.load(fileName: ".env");
  }
}