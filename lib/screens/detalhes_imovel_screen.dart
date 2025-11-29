import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_settings.dart';
import '../models/imovel_model.dart';
import '../services/whatsapp_service.dart';

class DetalhesImovelScreen extends StatefulWidget {
  final Imovel imovel;

  const DetalhesImovelScreen({super.key, required this.imovel});

  @override
  State<DetalhesImovelScreen> createState() => _DetalhesImovelScreenState();
}

class _DetalhesImovelScreenState extends State<DetalhesImovelScreen> {
  final PageController _pageController = PageController();
  int _fotoAtual = 0;

  Future<void> _abrirMapa() async {
    final lat = widget.imovel.latitude;
    final long = widget.imovel.longitude;
    if (lat == null || long == null) return;
    
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$long");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o mapa.')));
    }
  }

  void _abrirImagemTelaCheia(BuildContext context, int indiceInicial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          final PageController controllerFull = PageController(initialPage: indiceInicial);
          int indexFull = indiceInicial;
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
            extendBodyBehindAppBar: true,
            body: StatefulBuilder(
              builder: (context, setStateFull) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: controllerFull,
                      itemCount: widget.imovel.fotos.length,
                      onPageChanged: (idx) => setStateFull(() => indexFull = idx),
                      itemBuilder: (ctx, index) {
                        return Center(
                          child: InteractiveViewer(
                            panEnabled: true, minScale: 0.5, maxScale: 4.0,
                            child: Image.network(widget.imovel.fotos[index], fit: BoxFit.contain),
                          ),
                        );
                      },
                    ),
                    if (indexFull > 0)
                      Positioned(left: 20, child: CircleAvatar(backgroundColor: Colors.white24, child: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => controllerFull.previousPage(duration: 300.ms, curve: Curves.ease)))),
                    if (indexFull < widget.imovel.fotos.length - 1)
                      Positioned(right: 20, child: CircleAvatar(backgroundColor: Colors.white24, child: IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white), onPressed: () => controllerFull.nextPage(duration: 300.ms, curve: Curves.ease)))),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    
    // === CORES ===
    final Color azulMarinho = const Color.fromARGB(255, 2, 56, 83);
    final Color dourado = const Color(0xFFEBE4AB);

    final Color corItensBarra = settings.isDark ? dourado : azulMarinho;
    final Color corTextoConteudo = settings.isDark ? Colors.white : azulMarinho;
    final Color corDestaqueBotao = const Color(0xFFF0E68C); 

    final List<Color> coresGradiente = settings.isDark 
        ? [const Color(0xFF1E293B), Colors.black] 
        : [const Color(0xFFFFFDF0), const Color(0xFFEBE4AB)];

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: corItensBarra), 
        title: Text(
          "DETALHES DO IMÓVEL", 
          style: GoogleFonts.montserrat(
            color: corItensBarra, 
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            letterSpacing: 1.2
          )
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: coresGradiente,
          ),
        ),
        child: SafeArea( 
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWeb = constraints.maxWidth > 900;
              if (isWeb) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20), 
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0,5))]
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildCarrossel(height: constraints.maxHeight - 40),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 40, top: 20, bottom: 20),
                        child: _buildInfoColumn(corTextoConteudo, corDestaqueBotao, settings.isDark),
                      ),
                    ),
                  ],
                );
              } else {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildCarrossel(height: 300)
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildInfoColumn(corTextoConteudo, corDestaqueBotao, settings.isDark),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCarrossel({required double height}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: widget.imovel.fotos.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  itemCount: widget.imovel.fotos.length,
                  onPageChanged: (index) => setState(() => _fotoAtual = index),
                  itemBuilder: (ctx, index) {
                    return GestureDetector(
                      onTap: () => _abrirImagemTelaCheia(context, index),
                      child: Image.network(
                        widget.imovel.fotos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50)),
                      ),
                    );
                  },
                )
              : Container(color: Colors.black12, child: const Icon(Icons.home, size: 80, color: Colors.grey)),
        ),
        if (_fotoAtual > 0)
          Positioned(left: 10, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white), onPressed: () => _pageController.previousPage(duration: 300.ms, curve: Curves.ease)))),
        if (widget.imovel.fotos.isNotEmpty && _fotoAtual < widget.imovel.fotos.length - 1)
          Positioned(right: 10, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white), onPressed: () => _pageController.nextPage(duration: 300.ms, curve: Curves.ease)))),
      ],
    )
    .animate()
    .scale(duration: 600.ms, curve: Curves.easeOutBack, begin: const Offset(0.9, 0.9))
    .fadeIn(duration: 600.ms)
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .moveY(begin: 0, end: 5, duration: 2500.ms, curve: Curves.easeInOut);
  }

  Widget _buildInfoColumn(Color corTexto, Color corDestaque, bool isDark) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.imovel.titulo.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w900, color: corTexto))
          .animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),

        Text(formatador.format(widget.imovel.valor), style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: corDestaque))
          .animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.2, end: 0),
        
        const SizedBox(height: 20),

        GestureDetector(
          onTap: _abrirMapa,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: corTexto.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: corTexto.withOpacity(0.1))
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: corDestaque, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.imovel.localizacao, style: GoogleFonts.montserrat(fontSize: 14, color: corTexto.withOpacity(0.8)))),
                if (widget.imovel.latitude != null)
                   Container(
                     margin: const EdgeInsets.only(left: 10),
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                     decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                     child: const Text("MAPA", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                   )
              ],
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 30),

        // === CENÁRIO: CASA ESTILO FLAT (IGUAL O CARRO) ===
        _buildCenarioCasaStyle(corTexto, isDark),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             _buildSpecRow(Icons.bed, "Quartos", "${widget.imovel.quartos}", corTexto, 600),
             _buildSpecRow(Icons.square_foot, "Área", "${widget.imovel.area} m²", corTexto, 700),
             _buildSpecRow(Icons.garage, "Vaga", "Sim", corTexto, 800),
          ],
        ),

        const SizedBox(height: 30),

        Text("SOBRE O IMÓVEL", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: corTexto.withOpacity(0.6), letterSpacing: 1))
          .animate().fadeIn(delay: 900.ms),
        const SizedBox(height: 10),
        Text(widget.imovel.descricao, style: GoogleFonts.montserrat(fontSize: 16, height: 1.6, color: corTexto))
          .animate().fadeIn(delay: 1000.ms),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: corDestaque,
              foregroundColor: Colors.black, 
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            onPressed: () {
              WhatsAppService.abrirWhatsApp(context: context, numeroTelefone: "5515981325236", mensagem: "Olá! Gostei do imóvel *${widget.imovel.titulo}* e quero agendar visita.");
            },
            icon: const Icon(Icons.chat, size: 28),
            label: const Text("AGENDAR VISITA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white54)
        .scaleXY(begin: 1.0, end: 1.02, duration: 1.seconds)
        .animate().fadeIn(delay: 1200.ms, duration: 500.ms).slideY(begin: 0.5, end: 0), 
      ],
    );
  }

  // --- CENÁRIO CASA FLAT (IGUAL AO CARRO) ---
  Widget _buildCenarioCasaStyle(Color corTexto, bool isDark) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.5), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
           // Chão
           Positioned(
            bottom: 0, left: 0, right: 0, height: 40,
            child: Container(color: Colors.grey[800]), 
          ),
          // Grama
          Positioned(
            bottom: 35, left: 0, right: 0, height: 10,
            child: Container(color: Colors.green[800]), 
          ),

          // A Casa desenhada com código
          Positioned(
            bottom: 25,
            child: _desenharCasaFlat(corTexto)
            .animate()
            .slideY(begin: 1.0, end: 0, duration: 1.seconds, curve: Curves.easeOutBack) // Casa sobe do chão
          ),
        ],
      ),
    );
  }

  // Desenho da casa usando apenas Widgets (Sem imagens externas para não quebrar)
  Widget _desenharCasaFlat(Color corTexto) {
    return SizedBox(
      width: 220,
      height: 160,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Fumaça da chaminé 1 (Sai imediatamente)
          Positioned(
            top: 10, right: 50,
            child: Icon(Icons.cloud, color: Colors.grey.withOpacity(0.5), size: 20)
            .animate(onPlay: (c) => c.repeat())
            .moveY(begin: 0, end: -30, duration: 2.seconds)
            .fadeOut(duration: 2.seconds),
          ),
          
          // Fumaça da chaminé 2 (Sai com atraso)
          Positioned(
            top: 25, right: 40,
            child: Icon(Icons.cloud, color: Colors.grey.withOpacity(0.5), size: 15)
            // CORREÇÃO AQUI: O delay vem antes, e o repeat fica vazio
            .animate(delay: 500.ms, onPlay: (c) => c.repeat()) 
            .moveY(begin: 0, end: -30, duration: 2.seconds)
            .fadeOut(duration: 2.seconds),
          ),

          // Chaminé
          Positioned(
            top: 40, right: 45,
            child: Container(width: 20, height: 30, color: const Color(0xFF5D4037)),
          ),

          // Corpo da Casa
          Container(
            width: 160, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1), // Branco Gelo
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: const Offset(3, 3))],
              border: Border.all(color: Colors.grey[400]!),
            ),
          ),

          // Telhado (Triângulo usando ClipPath)
          Positioned(
            top: 20,
            child: ClipPath(
              clipper: TrianguloClipper(),
              child: Container(
                width: 180, height: 60,
                color: const Color(0xFF37474F), // Cinza Escuro
              ),
            ),
          ),

          // Porta
          Positioned(
            bottom: 0,
            child: Container(
              width: 30, height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF795548), // Marrom
                border: Border.all(color: Colors.brown[800]!),
              ),
            ),
          ),

          // Janela Esquerda
          Positioned(
            bottom: 40, left: 50,
            child: _janela(),
          ),
          
          // Janela Direita
          Positioned(
            bottom: 40, right: 50,
            child: _janela(),
          ),

          // Degrau
          Positioned(
            bottom: 0,
            child: Container(width: 40, height: 5, color: Colors.grey),
          )
        ],
      ),
    );
  }

  Widget _janela() {
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFB3E5FC), // Azul vidro
        border: Border.all(color: const Color(0xFF37474F), width: 2),
      ),
      child: Center(
        child: Container(width: 2, height: 30, color: const Color(0xFF37474F)), // Grade da janela
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value, Color corTexto, int delayMs) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: corTexto.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 24, color: corTexto.withOpacity(0.8)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.montserrat(fontSize: 11, color: corTexto.withOpacity(0.6))),
            Text(value, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: corTexto)),
          ],
        )
      ],
    ).animate().scale(delay: delayMs.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}

// Classe auxiliar para desenhar o triângulo do telhado
class TrianguloClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0); // Topo
    path.lineTo(size.width, size.height); // Direita baixo
    path.lineTo(0, size.height); // Esquerda baixo
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}