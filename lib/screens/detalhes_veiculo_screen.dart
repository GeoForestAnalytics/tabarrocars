import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // <--- IMPORTANTE

import '../providers/app_settings.dart'; // <--- IMPORTANTE
import '../models/veiculo_model.dart';
import '../services/whatsapp_service.dart';

class DetalhesVeiculoScreen extends StatefulWidget {
  final Veiculo veiculo;

  const DetalhesVeiculoScreen({super.key, required this.veiculo});

  @override
  State<DetalhesVeiculoScreen> createState() => _DetalhesVeiculoScreenState();
}

class _DetalhesVeiculoScreenState extends State<DetalhesVeiculoScreen> {
  int _fotoAtual = 0;

  // --- FUNÇÃO ZOOM ---
  void _abrirImagemTelaCheia(BuildContext context, int indiceInicial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: indiceInicial),
            itemCount: widget.veiculo.fotos.length,
            itemBuilder: (ctx, index) {
              return Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(widget.veiculo.fotos[index], fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. PEGAR AS CONFIGURAÇÕES GERAIS
    final settings = Provider.of<AppSettings>(context);

    // 2. DEFINIR CORES BASEADO NO TEMA (Mesma lógica da Home)
    final Color azulMarinho = const Color.fromARGB(255, 2, 56, 83);
    final Color dourado = const Color(0xFFEBE4AB);

    // Se for Dark: Fundo Azul. Se for Light: Fundo Amarelo Claro.
    final Color corFundo = settings.isDark ? const Color.fromARGB(246, 2, 44, 66) : const Color(0xFFFFFDF0);
    
    // AppBar: Se Dark (Azul Escuro), Se Light (Dourado)
    final Color corAppBar = settings.isDark ? const Color.fromARGB(230, 1, 7, 39) : dourado;
    
    // Textos e Ícones: Se Dark (Dourado), Se Light (Azul)
    final Color corTextoDestaque = settings.isDark ? dourado : azulMarinho;
    final Color corTextoComum = settings.isDark ? Colors.white : azulMarinho.withOpacity(0.8);

    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorFormatado = formatador.format(widget.veiculo.valor);
    final kmFormatado = NumberFormat.decimalPattern('pt_BR').format(widget.veiculo.km);

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corAppBar,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: corTextoDestaque), // Seta muda de cor
        title: Text(
          widget.veiculo.modelo.toUpperCase(),
          style: GoogleFonts.montserrat(color: corTextoDestaque, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // --- CARROSSEL ---
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: widget.veiculo.fotos.isNotEmpty
                    ? PageView.builder(
                        itemCount: widget.veiculo.fotos.length,
                        onPageChanged: (index) => setState(() => _fotoAtual = index),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _abrirImagemTelaCheia(context, index),
                            child: Image.network(
                              widget.veiculo.fotos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  Center(child: Icon(Icons.broken_image, color: corTextoComum, size: 50)),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.black26,
                        child: Icon(Icons.car_crash, size: 80, color: corTextoComum),
                      ),
              ),
              // Indicador de fotos
              if (widget.veiculo.fotos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.veiculo.fotos.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _fotoAtual == index ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _fotoAtual == index ? corTextoDestaque : Colors.white38,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),

          // --- INFO ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preço
                  Text(
                    valorFormatado,
                    style: GoogleFonts.montserrat(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: corTextoDestaque // Muda conforme o tema
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Modelo
                  Text(
                    widget.veiculo.modelo,
                    style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w500, color: corTextoComum),
                  ),
                  const SizedBox(height: 20),
                  
                  // Cards Detalhes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard(Icons.calendar_today, "${widget.veiculo.ano}", corTextoDestaque, corTextoComum),
                      _buildInfoCard(Icons.speed, "$kmFormatado km", corTextoDestaque, corTextoComum),
                      _buildInfoCard(Icons.color_lens, widget.veiculo.cor, corTextoDestaque, corTextoComum),
                    ],
                  ),
                  
                  Divider(height: 40, color: corTextoComum.withOpacity(0.2)),
                  
                  Text("Descrição", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoDestaque)),
                  const SizedBox(height: 10),
                  Text(
                    widget.veiculo.descricao,
                    style: GoogleFonts.montserrat(fontSize: 16, color: corTextoComum, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTÃO ZAP ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: corAppBar,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black45, offset: Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: corTextoDestaque, // Cor de Destaque (Dourado ou Azul)
                  foregroundColor: settings.isDark ? azulMarinho : dourado, // Texto Invertido
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                icon: const Icon(Icons.chat, size: 28), 
                label: Text(
                  "TENHO INTERESSE", 
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                onPressed: () {
                  WhatsAppService.abrirWhatsApp(
                    context: context,
                    numeroTelefone: "5515981325236", 
                    mensagem: "Olá! Tenho interesse no *${widget.veiculo.modelo}* anunciado por *$valorFormatado*.",
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, Color corIcone, Color corTexto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: corTexto.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: corIcone.withOpacity(0.3)), 
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: corIcone),
          const SizedBox(height: 5),
          Text(
            label, 
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: corTexto)
          ),
        ],
      ),
    );
  }
}