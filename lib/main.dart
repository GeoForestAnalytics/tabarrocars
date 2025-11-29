import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Necessário para usar o kIsWeb

import 'providers/app_settings.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // === CONFIGURAÇÃO EXATA DA SUA IMAGEM ===
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCkki9AyDg2NyCMLXIhDGMcJfNdndA9Lk",
        authDomain: "tabarrocars.firebaseapp.com",
        projectId: "tabarrocars",
        storageBucket: "tabarrocars.firebasestorage.app",
        messagingSenderId: "47935554618",
        appId: "1:47935554618:web:9c746f35a6ee2506a52103",
        measurementId: "G-JKQVYRX1RL",
      ),
    );
  } else {
    // === ANDROID E IOS (Automático pelo google-services.json) ===
    await Firebase.initializeApp();
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppSettings(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tabarro Store',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}