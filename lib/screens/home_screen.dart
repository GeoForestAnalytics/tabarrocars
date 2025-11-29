import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings.dart';
import '../models/veiculo_model.dart';
import '../services/veiculo_service.dart';
import '../models/imovel_model.dart';
import '../services/imovel_service.dart';

import 'cadastro_veiculo_screen.dart';
import 'cadastro_imovel_screen.dart';
import 'detalhes_veiculo_screen.dart';
import 'detalhes_imovel_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VeiculoService _veiculoService = VeiculoService();
  final ImovelService _imovelService = ImovelService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
         _tocarSomSuave();
      }
      setState(() {});
    });
  }

  Future<void> _tocarSomSuave() async {
    final settings = Provider.of<AppSettings>(context, listen: false);
    if (settings.isMuted) return;

    try {
       await _audioPlayer.stop();
       await _audioPlayer.setVolume(0.5);
       await _audioPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- FUNÇÕES DE EXCLUSÃO ---
  void _confirmarExclusao(BuildContext context, String id, String modelo) {
    showDialog(context: context, builder: (ctx) => _buildAlert(ctx, "Excluir Veículo", modelo, () {
      _veiculoService.removerVeiculo(id);
      Navigator.pop(ctx);
    }));
  }
  
  void _confirmarExclusaoImovel(BuildContext context, String id, String titulo) {
    showDialog(context: context, builder: (ctx) => _buildAlert(ctx, "Excluir Imóvel", titulo, () {
      _imovelService.removerImovel(id);
      Navigator.pop(ctx);
    }));
  }

  Widget _buildAlert(BuildContext ctx, String titulo, String item, VoidCallback onConfirm) {
    return AlertDialog(
      title: Text(titulo, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      content: Text("Tem certeza que deseja apagar: $item?", style: GoogleFonts.montserrat()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text("EXCLUIR", style: GoogleFonts.montserrat(color: Colors.white)),
        ),
      ],
    );
  }

  // --- CARD COM CORES DINÂMICAS ---
  Widget _buildCardPremium({
    required Widget imagem,
    required String titulo,
    required String subtitulo,
    required double valor,
    required VoidCallback onTap,
    required bool isAdmin,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required int index,
    required Color corTitulo,
    required Color corSubtitulo,
    required Color corCardFundo,
    required Color corBorda,
  }) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      decoration: BoxDecoration(
        color: corCardFundo, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: corBorda, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: InkWell(
        onTap: () {
          _tocarSomSuave();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(height: 200, width: double.infinity, child: imagem),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: GoogleFonts.montserrat(
                            fontSize: 20, fontWeight: FontWeight.w800, color: corTitulo
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin) ...[
                        GestureDetector(onTap: onEdit, child: const Icon(Icons.edit, color: Colors.blue, size: 22)),
                        const SizedBox(width: 15),
                        GestureDetector(onTap: onDelete, child: Icon(Icons.delete, color: Colors.red[400], size: 22)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: corSubtitulo),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(subtitulo, style: GoogleFonts.montserrat(fontSize: 14, color: corSubtitulo, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  Divider(height: 20, color: corSubtitulo.withOpacity(0.3)),
                  Text(
                    formatador.format(valor),
                    style: GoogleFonts.montserrat(fontSize: 24, color: corTitulo, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms)
    .slideX(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = FirebaseAuth.instance.currentUser != null;
    final settings = Provider.of<AppSettings>(context);
    
    // --- CORES DA MARCA ---
    final Color azulMarinhoLogo = const Color.fromARGB(255, 2, 56, 83);
    final Color douradoLogo = const Color.fromARGB(255, 230, 225, 190);
    
    // --- LÓGICA DAS CORES (CONFIGURAÇÃO EXATA DO PEDIDO) ---

    // 1. Fundo da Tela
    // Escuro: Azul Marinho. 
    // Claro: Amarelo "Creme" Bem Claro (para não cansar a vista, mas ser amarelo).
    final Color corFundoTela = settings.isDark 
        ? azulMarinhoLogo 
        : const Color(0xFFFFFDF0); 
    
    // 2. Barra Superior (AppBar)
    // Escuro: Azul Profundo.
    // Claro: DOURADO (Parte azul virou amarela).
    final Color corAppBar = settings.isDark 
        ? const Color.fromARGB(255, 1, 30, 45) 
        : douradoLogo;
    
    // 3. Texto e Ícones da AppBar
    // Escuro: Dourado.
    // Claro: AZUL MARINHO (Letras azuis).
    final Color corTextoAppBar = settings.isDark 
        ? douradoLogo 
        : azulMarinhoLogo;
    
    // 4. Cartões (Cards)
    // Escuro: Dourado (Destaque).
    // Claro: Branco (Para contrastar com o fundo amarelo claro e o topo dourado).
    final Color corCardFundo = settings.isDark 
        ? douradoLogo 
        : Colors.white;
    
    // 5. Texto do Card
    // Sempre Azul Marinho (Lê bem no Dourado e lê bem no Branco).
    final Color corTituloCard = azulMarinhoLogo; 
    final Color corSubtituloCard = azulMarinhoLogo.withOpacity(0.8);
    
    // 6. Borda do Card
    final Color corBordaCard = Colors.transparent;

    return Scaffold(
      backgroundColor: corFundoTela,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: corAppBar,
        centerTitle: true,
        iconTheme: IconThemeData(color: corTextoAppBar),
        title: Text(
          "STORE",
          style: GoogleFonts.montserrat(
            color: corTextoAppBar, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 2.0
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(settings.isMuted ? Icons.volume_off : Icons.volume_up),
            tooltip: "Som",
            onPressed: () => settings.toggleMute(),
          ),
          IconButton(
            icon: Icon(settings.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: "Tema",
            onPressed: () {
              settings.toggleTheme();
              _tocarSomSuave();
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Sair",
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
              },
            )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: corTextoAppBar,
          indicatorWeight: 4,
          labelColor: corTextoAppBar,
          unselectedLabelColor: corTextoAppBar.withOpacity(0.5),
          labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: "VEÍCULOS"),
            Tab(icon: Icon(Icons.home), text: "IMÓVEIS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLista(isAdmin, true, corTituloCard, corSubtituloCard, corCardFundo, corBordaCard),
          _buildLista(isAdmin, false, corTituloCard, corSubtituloCard, corCardFundo, corBordaCard),
        ],
      ),
      floatingActionButton: isAdmin 
        ? FloatingActionButton(
            backgroundColor: settings.isDark ? douradoLogo : azulMarinhoLogo, // Botão inverte tb
            foregroundColor: settings.isDark ? azulMarinhoLogo : douradoLogo,
            child: const Icon(Icons.add, size: 30),
            onPressed: () {
              if (_tabController.index == 0) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CadastroVeiculoScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CadastroImovelScreen()));
              }
            },
          )
        : null,
    );
  }

  Widget _buildLista(bool isAdmin, bool isVeiculo, Color corTit, Color corSub, Color corBg, Color corBorda) {
    final stream = isVeiculo ? _veiculoService.lerVeiculos() : _imovelService.lerImoveis();

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Erro ao carregar", style: GoogleFonts.montserrat(color: Colors.grey)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final lista = snapshot.data as List? ?? [];
        if (lista.isEmpty) return Center(child: Text("Nenhum item disponível.", style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final item = lista[index];
            String titulo, subtitulo, id;
            double valor;
            List<String> fotos;
            
            if (isVeiculo) {
              final v = item as Veiculo;
              titulo = v.modelo;
              subtitulo = "${v.ano} • ${v.cor}";
              valor = v.valor;
              fotos = v.fotos;
              id = v.id!;
            } else {
              final i = item as Imovel;
              titulo = i.titulo;
              subtitulo = i.localizacao;
              valor = i.valor;
              fotos = i.fotos;
              id = i.id!;
            }

            Widget img = fotos.isNotEmpty
                ? Image.network(fotos.first, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey)))
                : Container(color: Colors.grey[300], child: Icon(isVeiculo ? Icons.directions_car : Icons.home, size: 50, color: Colors.grey));

            return _buildCardPremium(
              index: index,
              imagem: img,
              titulo: titulo,
              subtitulo: subtitulo,
              valor: valor,
              isAdmin: isAdmin,
              onTap: () {
                 if (isVeiculo) Navigator.push(context, MaterialPageRoute(builder: (_) => DetalhesVeiculoScreen(veiculo: item as Veiculo)));
                 else Navigator.push(context, MaterialPageRoute(builder: (_) => DetalhesImovelScreen(imovel: item as Imovel)));
              },
              onEdit: () {
                if (isVeiculo) Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroVeiculoScreen(veiculoParaEditar: item as Veiculo)));
                else Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroImovelScreen(imovelParaEditar: item as Imovel)));
              },
              onDelete: () {
                 if (isVeiculo) _confirmarExclusao(context, id, titulo);
                 else _confirmarExclusaoImovel(context, id, titulo);
              },
              corTitulo: corTit,
              corSubtitulo: corSub,
              corCardFundo: corBg,
              corBorda: corBorda,
            );
          },
        );
      },
    );
  }
}