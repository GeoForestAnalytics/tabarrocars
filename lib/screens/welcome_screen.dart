import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import 'package:audioplayers/audioplayers.dart'; 
import 'home_screen.dart';
import '../services/whatsapp_service.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Função simples para tocar o clique
  Future<void> _tocarClique() async {
    try {
      await _audioPlayer.stop(); 
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      // Ignora erro se não tiver som
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cores (Identidade Visual)
    final Color corDourada = const Color.fromARGB(255, 235, 228, 171);
    final Color corAzulEscura = const Color.fromARGB(255, 2, 56, 83);
    // Usando a cor que você criou
    final Color corbrilhoBranco = const Color.fromARGB(223, 247, 245, 227); 

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [corDourada, corAzulEscura],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // --- 1. LOGO (Com Borda Branca e Brilho) ---
                Container(
                  padding: const EdgeInsets.all(5), // Espaço entre o logo e a borda
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Borda fina e elegante usando sua cor clara
                    border: Border.all(color: corbrilhoBranco.withOpacity(0), width: 2),
                    boxShadow: [
                      // 1. Brilho Branco Intenso (A borda brilhante)
                      BoxShadow(
                        color: corbrilhoBranco, 
                        blurRadius: 90, 
                        spreadRadius: 0,
                      ),
                      // 2. Brilho Dourado Espalhado (O fundo difuso)
                      BoxShadow(
                        color: corDourada.withOpacity(0.3),
                        blurRadius: 90,
                        spreadRadius: 0,
                      )
                    ]
                  ),
                  child: Image.asset(
                    'assets/images/logo1.png',
                    height: 250, // Ajustei levemente para caber na borda
                    fit: BoxFit.contain,
                  ),
                )
                .animate()
                .slideY(begin: -0.5, end: 0, duration: 800.ms, curve: Curves.easeOutBack) 
                .fadeIn()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.02, duration: 2.seconds) // Respiração
                .boxShadow( // Animação extra no brilho da borda
                  begin: BoxShadow(color: corbrilhoBranco.withOpacity(0.5), blurRadius: 90, spreadRadius: 0),
                  end: BoxShadow(color: corbrilhoBranco, blurRadius: 90, spreadRadius: 0),
                  duration: 2.seconds,
                ),

                const SizedBox(height: 30),

                // --- 2. TEXTOS ---
                Text(
                  "Realizando Sonhos",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      shadows: [Shadow(offset: Offset(0, 2), blurRadius: 4.0, color: Colors.black45)],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),

                Text(
                  "Veículos & Imóveis",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                ).animate().fadeIn(delay: 700.ms),

                const Spacer(flex: 3),

                // --- 3. BOTÃO COMPRAR ---
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corAzulEscura,
                      foregroundColor: corDourada,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      _tocarClique();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "QUERO COMPRAR",
                          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 2, end: 0, delay: 800.ms, duration: 600.ms, curve: Curves.easeOut),

                const SizedBox(height: 20),

                // --- 4. BOTÃO VENDER ---
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corDourada,
                      foregroundColor: corAzulEscura,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      _tocarClique();
                      WhatsAppService.abrirWhatsApp(
                        context: context,
                        numeroTelefone: "5515981325236",
                        mensagem: "Olá! Gostaria de anunciar meu veículo/imóvel com vocês.",
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "QUERO VENDER",
                          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 2, end: 0, delay: 1000.ms, duration: 600.ms, curve: Curves.easeOut),

                const Spacer(flex: 1),

                // --- 5. ADMIN ---
                TextButton.icon(
                  onPressed: () {
                    _tocarClique();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  icon: const Icon(Icons.lock_outline, size: 16, color: Colors.white30),
                  label: Text(
                    "Acesso Administrativo",
                    style: GoogleFonts.montserrat(color: Colors.white30, fontSize: 12),
                  ),
                ).animate().fadeIn(delay: 1500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}