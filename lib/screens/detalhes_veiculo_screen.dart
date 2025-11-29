import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; 
import 'package:flutter_animate/flutter_animate.dart'; 

import '../providers/app_settings.dart';
import '../models/veiculo_model.dart';
import '../services/whatsapp_service.dart';

class DetalhesVeiculoScreen extends StatefulWidget {
  final Veiculo veiculo;

  const DetalhesVeiculoScreen({super.key, required this.veiculo});

  @override
  State<DetalhesVeiculoScreen> createState() => _DetalhesVeiculoScreenState();
}

class _DetalhesVeiculoScreenState extends State<DetalhesVeiculoScreen> {
  final PageController _pageController = PageController();
  int _fotoAtual = 0;

  // --- CORES INTELIGENTES ---
  Color _getCorVeiculo(String nomeCor) {
    String cor = nomeCor.toLowerCase().trim();
    if (cor.contains('verm')) return const Color(0xFFD32F2F);
    if (cor.contains('azul')) return const Color(0xFF1565C0);
    if (cor.contains('pret')) return const Color(0xFF212121);
    if (cor.contains('branc')) return const Color(0xFFF5F5F5);
    if (cor.contains('prat') || cor.contains('cinz')) return const Color(0xFF90A4AE);
    if (cor.contains('amarel')) return const Color(0xFFFBC02D);
    if (cor.contains('verd')) return const Color(0xFF388E3C);
    return const Color(0xFF546E7A);
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
                      itemCount: widget.veiculo.fotos.length,
                      onPageChanged: (idx) => setStateFull(() => indexFull = idx),
                      itemBuilder: (ctx, index) {
                        return Center(
                          child: InteractiveViewer(
                            panEnabled: true, minScale: 0.5, maxScale: 4.0,
                            child: Image.network(widget.veiculo.fotos[index], fit: BoxFit.contain),
                          ),
                        );
                      },
                    ),
                    if (indexFull > 0)
                      Positioned(left: 20, child: CircleAvatar(backgroundColor: Colors.white24, child: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => controllerFull.previousPage(duration: 300.ms, curve: Curves.ease)))),
                    if (indexFull < widget.veiculo.fotos.length - 1)
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
    
    // === CORES DA MARCA ===
    final Color azulMarinho = const Color.fromARGB(255, 2, 56, 83);
    final Color dourado = const Color(0xFFEBE4AB);

    final Color corItensBarra = settings.isDark ? dourado : azulMarinho;
    final Color corTextoConteudo = settings.isDark ? Colors.white : azulMarinho;
    final Color corDestaqueBotao = const Color(0xFFE6D88F); 

    final List<Color> coresGradiente = settings.isDark 
        ? [const Color(0xFF1E293B), Colors.black] 
        : [const Color(0xFFFFFDF0), const Color(0xFFEBE4AB)];

    return Scaffold(
      // === ESSA LINHA REMOVE A BARRA BRANCA ===
      extendBodyBehindAppBar: true, 
      
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: corItensBarra), 
        title: Text(
          "DETALHES DO VEÍCULO", 
          style: GoogleFonts.montserrat(
            color: corItensBarra, 
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            letterSpacing: 1.2
          )
        ),
      ),
      body: Container(
        // O Container de fundo ocupa a tela TODA agora
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: coresGradiente,
          ),
        ),
        // SafeArea garante que o conteúdo não fique escondido atrás da barra, 
        // mas o fundo continua lá atrás.
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
          child: widget.veiculo.fotos.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  itemCount: widget.veiculo.fotos.length,
                  onPageChanged: (index) => setState(() => _fotoAtual = index),
                  itemBuilder: (ctx, index) {
                    return GestureDetector(
                      onTap: () => _abrirImagemTelaCheia(context, index),
                      child: Image.network(
                        widget.veiculo.fotos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50)),
                      ),
                    );
                  },
                )
              : Container(color: Colors.black12, child: const Icon(Icons.car_crash, size: 80, color: Colors.grey)),
        ),
        if (_fotoAtual > 0)
          Positioned(left: 10, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white), onPressed: () => _pageController.previousPage(duration: 300.ms, curve: Curves.ease)))),
        if (widget.veiculo.fotos.isNotEmpty && _fotoAtual < widget.veiculo.fotos.length - 1)
          Positioned(right: 10, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white), onPressed: () => _pageController.nextPage(duration: 300.ms, curve: Curves.ease)))),
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
    final Color corDoCarro = _getCorVeiculo(widget.veiculo.cor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.veiculo.modelo.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w900, color: corTexto))
          .animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),

        Text(formatador.format(widget.veiculo.valor), style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: corDestaque))
          .animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.2, end: 0),
        
        const SizedBox(height: 30),

        _buildCenarioVideoStyle(corDoCarro, corTexto, isDark),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             _buildSpecRow(Icons.calendar_month, "Ano", "${widget.veiculo.ano}", corTexto, 600),
             _buildSpecRow(Icons.speed, "Km", "${widget.veiculo.km}", corTexto, 700),
             _buildSpecRow(Icons.palette, "Cor", widget.veiculo.cor, corDoCarro, 800),
          ],
        ),

        const SizedBox(height: 30),

        Text("SOBRE O VEÍCULO", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: corTexto.withOpacity(0.6), letterSpacing: 1))
          .animate().fadeIn(delay: 900.ms),
        const SizedBox(height: 10),
        Text(widget.veiculo.descricao, style: GoogleFonts.montserrat(fontSize: 16, height: 1.6, color: corTexto))
          .animate().fadeIn(delay: 1000.ms),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: corDestaque,
              foregroundColor: Colors.black,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            onPressed: () {
              WhatsAppService.abrirWhatsApp(context: context, numeroTelefone: "5515981325236", mensagem: "Olá! Vi o *${widget.veiculo.modelo}* (${widget.veiculo.cor}) e tenho interesse!");
            },
            icon: SizedBox(
              width: 40, height: 40,
              child: Lottie.network(
                'https://lottie.host/98c25735-a682-4467-938b-d775196420b9/N0lC7q0E5U.json',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.chat, size: 30),
              ),
            ),
            label: const Text("TENHO INTERESSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white70)
        .scaleXY(begin: 1.0, end: 1.02, duration: 1.seconds)
        .animate().fadeIn(delay: 1200.ms, duration: 500.ms).slideY(begin: 0.5, end: 0), 
      ],
    );
  }

  Widget _buildCenarioVideoStyle(Color corCarro, Color corTexto, bool isDark) {
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
          Positioned(
            bottom: 0, left: 0, right: 0, height: 40,
            child: Container(color: Colors.grey[800]), 
          ),
          Positioned(
            bottom: 18, left: -50,
            child: Row(
              children: List.generate(10, (index) => Container(
                width: 40, height: 4, margin: const EdgeInsets.only(right: 40), color: Colors.white,
              )),
            )
            .animate(onPlay: (c) => c.repeat())
            .moveX(begin: 0, end: -80, duration: 1.seconds, curve: Curves.linear), 
          ),
          Positioned(
            bottom: 30,
            child: _desenharCarroFlat(corCarro)
            .animate()
            .slideX(begin: 1.5, end: 0, duration: 800.ms, curve: Curves.easeOutBack) 
            .animate(onPlay: (c) => c.repeat(reverse: true)) 
            .moveY(begin: 0, end: 1.5, duration: 100.ms, curve: Curves.easeInOut), 
          ),
        ],
      ),
    );
  }

  Widget _desenharCarroFlat(Color cor) {
    return SizedBox(
      width: 260, height: 100,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(bottom: 0, left: 35, child: _roda()),
          Positioned(bottom: 0, right: 45, child: _roda()),

          Positioned(
            bottom: 15,
            child: Container(
              width: 260, height: 45,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(20), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(2, 4))]
              ),
            ),
          ),

          Positioned(
            bottom: 58, left: 45,
            child: Container(
              width: 130, height: 35,
              decoration: BoxDecoration(color: cor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(5))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 40, height: 25, margin: const EdgeInsets.only(top: 5, right: 5), decoration: const BoxDecoration(color: Color(0xFF263238), borderRadius: BorderRadius.only(topLeft: Radius.circular(25)))),
                  Container(width: 50, height: 25, margin: const EdgeInsets.only(top: 5), decoration: const BoxDecoration(color: Color(0xFF263238), borderRadius: BorderRadius.only(topRight: Radius.circular(5)))),
                ],
              ),
            ),
          ),

          Positioned(bottom: 0, left: 35, child: _rodaDetalhe()),
          Positioned(bottom: 0, right: 45, child: _rodaDetalhe()),
        ],
      ),
    );
  }

  Widget _roda() {
    return Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle));
  }
  
  Widget _rodaDetalhe() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: const Color(0xFF37474F), shape: BoxShape.circle, border: Border.all(color: Colors.grey[400]!, width: 2)),
      child: Center(child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle))),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value, Color corTexto, int delayMs) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: corTexto.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: corTexto.withOpacity(0.8)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.montserrat(fontSize: 11, color: corTexto.withOpacity(0.6))),
            Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: corTexto)),
          ],
        )
      ],
    ).animate().scale(delay: delayMs.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}