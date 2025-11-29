import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// import 'package:flutter/foundation.dart'; // Não precisa mais importar isso

import 'providers/app_settings.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart'; // Certifique-se que este import está aqui

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // === INICIALIZAÇÃO UNIVERSAL (WEB, ANDROID, IOS) ===
  // O DefaultFirebaseOptions.currentPlatform já pega a configuração correta
  // de dentro do arquivo firebase_options.dart (que tem a chave certa para Web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // O runApp fica FORA de qualquer if/else para rodar em todas as plataformas
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