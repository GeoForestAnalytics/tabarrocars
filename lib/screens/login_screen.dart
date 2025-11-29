// Arquivo: lib\screens\login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  bool _obscureSenha = true;

  // Cores da Identidade Visual Tabarro
  final Color corDourada = const Color(0xFFEBE4AB);
  final Color corAzulEscura = const Color.fromARGB(255, 2, 56, 83);

  Future<void> _fazerLogin() async {
    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha email e senha")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String erro = "Erro ao logar";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        erro = "Email ou senha incorretos";
      } else if (e.code == 'wrong-password') {
        erro = "Senha incorreta";
      } else if (e.code == 'invalid-email') {
        erro = "Email inválido";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              corDourada.withOpacity(0.9), // Dourado no topo
              corAzulEscura,               // Azul escuro embaixo
            ],
          ),
        ),
        child: SafeArea(
          // Usamos Stack para colocar o botão de voltar "flutuando" sobre o conteúdo
          child: Stack(
            children: [
              // --- CAMADA 1: O CONTEÚDO CENTRALIZADO ---
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      children: [
                        const SizedBox(height: 40), // Espaço para não bater no topo

                        // --- 1. LOGO CIRCULAR (GRANDE) ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo1.png',
                            height: 250, // Mantido tamanho grande
                            width: 250,
                            fit: BoxFit.contain,
                          ),
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 30),

                        // --- 2. TÍTULO ---
                        Text(
                          "TABARRO STORE",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: corAzulEscura,
                            letterSpacing: 1.5,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, end: 0),

                        Text(
                          "Administrativo",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: corAzulEscura.withOpacity(0.7),
                            letterSpacing: 4,
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 40),

                        // --- 3. CARD BRANCO DE LOGIN ---
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Input Email
                              _buildInputLabel("Email"),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.montserrat(color: corAzulEscura),
                                decoration: _inputDecoration(Icons.email_outlined),
                              ),
                              
                              const SizedBox(height: 20),

                              // Input Senha
                              _buildInputLabel("Senha"),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _senhaController,
                                obscureText: _obscureSenha,
                                style: GoogleFonts.montserrat(color: corAzulEscura),
                                decoration: _inputDecoration(Icons.lock_outline).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Esqueci minha senha
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text("Entre em contato com o suporte para resetar.")),
                                     );
                                  },
                                  child: Text(
                                    "Esqueci minha senha",
                                    style: GoogleFonts.montserrat(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Botão ENTRAR
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _fazerLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: corAzulEscura,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: _isLoading 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        "ENTRAR",
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().slideY(begin: 0.2, end: 0, delay: 600.ms, duration: 600.ms),

                        const SizedBox(height: 40),
                        // O Botão "CRIAR NOVA CONTA" foi removido daqui.
                      ],
                    ),
                  ),
                ),
              ),

              // --- CAMADA 2: O BOTÃO VOLTAR (FLUTUANTE) ---
              Positioned(
                top: 10,
                left: 10,
                child: Semantics(
                  label: "Voltar",
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context), // Volta para a WelcomeScreen
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3), // Fundo translúcido
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new, 
                          color: corAzulEscura,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: corAzulEscura.withOpacity(0.6)),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: corAzulEscura, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}