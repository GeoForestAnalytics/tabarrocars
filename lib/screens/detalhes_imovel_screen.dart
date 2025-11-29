import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // <--- IMPORTANTE
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_settings.dart'; // <--- IMPORTANTE
import '../models/imovel_model.dart';
import '../services/whatsapp_service.dart';

class DetalhesImovelScreen extends StatefulWidget {
  final Imovel imovel;

  const DetalhesImovelScreen({super.key, required this.imovel});

  @override
  State<DetalhesImovelScreen> createState() => _DetalhesImovelScreenState();
}

class _DetalhesImovelScreenState extends State<DetalhesImovelScreen> {
  int _fotoAtual = 0;

  void _abrirImagemTelaCheia(BuildContext context, int indiceInicial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
          body: PageView.builder(
            controller: PageController(initialPage: indiceInicial),
            itemCount: widget.imovel.fotos.length,
            itemBuilder: (ctx, index) {
              return Center(
                child: InteractiveViewer(
                  panEnabled: true, minScale: 0.5, maxScale: 4.0,
                  child: Image.network(widget.imovel.fotos[index], fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _abrirMapa() async {
    final lat = widget.imovel.latitude;
    final long = widget.imovel.longitude;
    if (lat == null || long == null) return;
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$long");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o mapa.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. PEGAR CONFIGURAÇÕES
    final settings = Provider.of<AppSettings>(context);

    // 2. LÓGICA DE CORES (Inversão para o modo claro)
    final Color azulMarinho = const Color.fromARGB(255, 2, 56, 83);
    final Color dourado = const Color(0xFFEBE4AB);

    final Color corFundo = settings.isDark ? const Color.fromARGB(246, 2, 44, 66) : const Color(0xFFFFFDF0);
    final Color corAppBar = settings.isDark ? const Color.fromARGB(230, 1, 7, 39) : dourado;
    final Color corTextoDestaque = settings.isDark ? dourado : azulMarinho;
    final Color corTextoComum = settings.isDark ? Colors.white : azulMarinho.withOpacity(0.8);

    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorFormatado = formatador.format(widget.imovel.valor);

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corAppBar,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: corTextoDestaque),
        title: Text(
          widget.imovel.titulo.toUpperCase(),
          style: GoogleFonts.montserrat(color: corTextoDestaque, fontWeight: FontWeight.bold, fontSize: 18),
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
                child: widget.imovel.fotos.isNotEmpty
                    ? PageView.builder(
                        itemCount: widget.imovel.fotos.length,
                        onPageChanged: (index) => setState(() => _fotoAtual = index),
                        itemBuilder: (ctx, index) {
                          return GestureDetector(
                            onTap: () => _abrirImagemTelaCheia(context, index),
                            child: Image.network(
                              widget.imovel.fotos[index], 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  Center(child: Icon(Icons.broken_image, color: corTextoComum, size: 50)),
                            ),
                          );
                        },
                      )
                    : Container(color: Colors.black26, child: Icon(Icons.home, size: 80, color: corTextoComum)),
              ),
              if (widget.imovel.fotos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.imovel.fotos.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _fotoAtual == index ? 12 : 8, height: 8,
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

          // --- DETALHES ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valorFormatado, 
                    style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.bold, color: corTextoDestaque)
                  ),
                  const SizedBox(height: 5),
                  Text(widget.imovel.titulo, style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w500, color: corTextoComum)),
                  
                  // Localização
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: corTextoComum.withOpacity(0.7), size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.imovel.localizacao, 
                          style: GoogleFonts.montserrat(fontSize: 14, color: corTextoComum.withOpacity(0.7))
                        ),
                      ),
                    ],
                  ),

                  // Botão Mapa
                  if (widget.imovel.latitude != null && widget.imovel.longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: InkWell(
                        onTap: _abrirMapa,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Ver localização no Mapa",
                                style: GoogleFonts.montserrat(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 25),
                  
                  // Grid de Infos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCard(Icons.bed, "${widget.imovel.quartos} Quartos", corTextoDestaque, corTextoComum),
                      _buildInfoCard(Icons.square_foot, "${widget.imovel.area} m²", corTextoDestaque, corTextoComum),
                    ],
                  ),
                  
                  Divider(height: 40, color: corTextoComum.withOpacity(0.2)),
                  Text("Descrição", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoDestaque)),
                  const SizedBox(height: 10),
                  Text(widget.imovel.descricao, style: GoogleFonts.montserrat(fontSize: 16, color: corTextoComum, height: 1.5)),
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
                  backgroundColor: corTextoDestaque, // DOURADO OU AZUL
                  foregroundColor: settings.isDark ? azulMarinho : dourado, // TEXTO INVERTIDO
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                icon: const Icon(Icons.chat, size: 28),
                label: Text("TENHO INTERESSE", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () {
                  WhatsAppService.abrirWhatsApp(
                    context: context,
                    numeroTelefone: "5515981325236", 
                    mensagem: "Olá! Gostei do imóvel *${widget.imovel.titulo}* em *${widget.imovel.localizacao}* por *$valorFormatado*.",
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: corTexto.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: corIcone.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: corIcone),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: corTexto)),
        ],
      ),
    );
  }
}