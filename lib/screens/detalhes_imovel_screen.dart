import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; 
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
    
    // COR DO BOTÃO: AMARELO PASTEL / CREME (Suave e elegante)
    final Color corDestaqueBotao = const Color(0xFFF0E68C); 

    // Gradiente de Fundo
    final List<Color> coresGradiente = settings.isDark 
        ? [const Color(0xFF1E293B), Colors.black] 
        : [const Color(0xFFFFFDF0), const Color(0xFFEBE4AB)];

    return Scaffold(
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
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: coresGradiente,
          ),
        ),
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

        // === CENÁRIO: CASA ANIMADA (LOTTIE ONLINE - SEM ERRO DE ARQUIVO) ===
        _buildCenarioCasaAnimada(corTexto, isDark),

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

        // === BOTÃO PASTEL + LOTTIE ONLINE ===
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: corDestaque, // Amarelo Pastel
              foregroundColor: Colors.black, // Texto Preto
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            onPressed: () {
              WhatsAppService.abrirWhatsApp(context: context, numeroTelefone: "5515981325236", mensagem: "Olá! Gostei do imóvel *${widget.imovel.titulo}* e quero agendar visita.");
            },
            icon: SizedBox(
              width: 40, height: 40,
              child: Lottie.network(
                // Ícone do WhatsApp 3D online
                'https://lottie.host/98c25735-a682-4467-938b-d775196420b9/N0lC7q0E5U.json',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.chat, size: 30),
              ),
            ),
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

  // --- ANIMAÇÃO DE CASA (Lottie Online - Garantido que funciona) ---
  Widget _buildCenarioCasaAnimada(Color corTexto, bool isDark) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        // Mantivemos o seu gradiente bonito de fundo
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark 
            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
            : [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // AQUI ESTÁ A MUDANÇA: Usamos Image.asset para o GIF
          SizedBox(
            height: 200, 
            width: double.infinity,
            child: Image.asset(
              'assets/images/casa.gif', // <--- NOME DO SEU ARQUIVO AQUI
              fit: BoxFit.contain, // Ajusta para aparecer a casa inteira sem cortar
            ),
          )
          // Mantivemos a animação de entrada (Pop) para ficar estiloso
          .animate().scale(duration: 1.seconds, curve: Curves.elasticOut)
          .fadeIn(duration: 800.ms), 
        ],
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