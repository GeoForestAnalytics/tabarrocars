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

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = FirebaseAuth.instance.currentUser != null;
    final settings = Provider.of<AppSettings>(context);
    
    // --- CORES DA MARCA ---
    final Color azulMarinhoLogo = const Color.fromARGB(255, 2, 56, 83);
    final Color douradoLogo = const Color.fromARGB(255, 230, 225, 190);
    
    // --- LÓGICA DAS CORES ---
    final Color corAppBar = settings.isDark ? const Color.fromARGB(255, 1, 30, 45) : douradoLogo;
    final Color corTextoAppBar = settings.isDark ? douradoLogo : azulMarinhoLogo;
    final Color corTituloCard = azulMarinhoLogo; 
    final Color corSubtituloCard = azulMarinhoLogo.withOpacity(0.8);
    
    // As cores do card agora são controladas dentro do FuturisticCard, mas passamos referências
    // A cor de fundo "Sólida" (para admin) ou base para o vidro
    final Color corCardBase = settings.isDark ? douradoLogo : Colors.white;

    return Scaffold(
      // Removemos a cor de fundo chapada e usamos o Container com Gradiente no body
      backgroundColor: Colors.transparent, // Deixa transparente pro container brilhar
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
      // === AQUI ESTÁ O FUNDO FUTURISTA ===
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: settings.isDark 
                ? [const Color(0xFF1E293B), Colors.black] // Escuro Profundo
                : [const Color(0xFFFFFDF0), const Color(0xFFEBE4AB)], // Claro Premium
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLista(isAdmin, true, corTituloCard, corSubtituloCard, corCardBase),
            _buildLista(isAdmin, false, corTituloCard, corSubtituloCard, corCardBase),
          ],
        ),
      ),
      floatingActionButton: isAdmin 
        ? FloatingActionButton(
            backgroundColor: settings.isDark ? douradoLogo : azulMarinhoLogo,
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

  Widget _buildLista(bool isAdmin, bool isVeiculo, Color corTit, Color corSub, Color corBg) {
    final stream = isVeiculo ? _veiculoService.lerVeiculos() : _imovelService.lerImoveis();

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Erro ao carregar", style: GoogleFonts.montserrat(color: Colors.grey)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final lista = snapshot.data as List? ?? [];
        if (lista.isEmpty) return Center(child: Text("Nenhum item disponível.", style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey)));

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isWebOuTablet = constraints.maxWidth > 600;

            if (isWebOuTablet) {
             // === MODO WEB (GRID) ===
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  childAspectRatio: 0.75, // Altura flexível
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: lista.length,
                itemBuilder: (context, index) => _montarItem(context, lista[index], isAdmin, isVeiculo, corTit, corSub, corBg, index),
              );
            } else {
              // === MODO CELULAR (LISTA) ===
              return ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 20, left: 10, right: 10),
                itemCount: lista.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: SizedBox(
                    height: 350, // Altura fixa para o card no mobile ficar bonito
                    child: _montarItem(context, lista[index], isAdmin, isVeiculo, corTit, corSub, corBg, index)
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  // Monta o Card usando o Widget Futurista
  Widget _montarItem(BuildContext context, dynamic item, bool isAdmin, bool isVeiculo, Color corTit, Color corSub, Color corBg, int index) {
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
        ? CardCarrossel(fotos: fotos) 
        : Container(
            color: Colors.grey[300], 
            child: Icon(isVeiculo ? Icons.directions_car : Icons.home, size: 50, color: Colors.grey)
          );

    // === CORREÇÃO DE CORES PARA LEITURA ===
    // O fundo do card agora é Dourado (Dark) ou Branco (Light).
    // Para ler bem, o texto precisa ser ESCURO em ambos os casos.
    final Color corTextoForte = const Color(0xFF0F172A); // Azul bem escuro
    final Color corTextoSuave = const Color(0xFF0F172A).withOpacity(0.7);

    // === RETORNA O CARTÃO FUTURISTA ===
    return FuturisticCard(
      heroTag: id,
      imagem: img,
      titulo: titulo,
      subtitulo: subtitulo,
      valor: valor,
      onTap: () {
         _tocarSomSuave();
         if (isVeiculo) Navigator.push(context, MaterialPageRoute(builder: (_) => DetalhesVeiculoScreen(veiculo: item as Veiculo)));
         else Navigator.push(context, MaterialPageRoute(builder: (_) => DetalhesImovelScreen(imovel: item as Imovel)));
      },
      isAdmin: isAdmin,
      onEdit: () {
        if (isVeiculo) Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroVeiculoScreen(veiculoParaEditar: item as Veiculo)));
        else Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroImovelScreen(imovelParaEditar: item as Imovel)));
      },
      onDelete: () {
         if (isVeiculo) _confirmarExclusao(context, id, titulo);
         else _confirmarExclusaoImovel(context, id, titulo);
      },
      // AQUI MUDAMOS: Texto sempre escuro para contrastar com o card claro/dourado
      corTitulo: corTextoForte,
      corSubtitulo: corTextoSuave, 
      corCardFundo: corBg,
    );
  }
}

// ============================================================================
// WIDGET DO CARTÃO FUTURISTA (COM HOVER E GLASSMORPHISM)
// ============================================================================
class FuturisticCard extends StatefulWidget {
  final Widget imagem;
  final String titulo;
  final String subtitulo;
  final double valor;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color corTitulo;
  final Color corSubtitulo;
  final Color corCardFundo;
  final String heroTag; 

  const FuturisticCard({
    super.key,
    required this.imagem,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onTap,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.corTitulo,
    required this.corSubtitulo,
    required this.corCardFundo,
    required this.heroTag,
  });

  @override
  State<FuturisticCard> createState() => _FuturisticCardState();
}

class _FuturisticCardState extends State<FuturisticCard> {
  bool _isHovered = false; 

  @override
  Widget build(BuildContext context) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          // EFEITO 1: ESCALA 
          transform: _isHovered ? (Matrix4.identity()..scale(1.03)..translate(0.0, -5.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            // EFEITO 2: VIDRO/FUNDO
            color: widget.isAdmin 
                ? widget.corCardFundo // Admin vê sólido
                : (_isHovered ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05)), // Vidro
            borderRadius: BorderRadius.circular(20),
            // EFEITO 3: BORDA BRILHANTE
            border: Border.all(
              color: _isHovered ? widget.corTitulo.withOpacity(0.8) : Colors.white.withOpacity(0.2),
              width: _isHovered ? 2 : 1,
            ),
            // EFEITO 4: SOMBRA NEON
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.corTitulo.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 5),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGEM (Com Hero Animation)
              Expanded(
                flex: 55,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Hero(
                    tag: widget.heroTag, 
                    child: SizedBox(
                      width: double.infinity,
                      child: widget.imagem,
                    ),
                  ),
                ),
              ),
              
              // INFO
              Expanded(
                flex: 45,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Título
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.titulo.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.corTitulo, 
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isAdmin) ...[
                             GestureDetector(onTap: widget.onEdit, child: const Icon(Icons.edit, size: 18, color: Colors.blue)),
                             const SizedBox(width: 8),
                             GestureDetector(onTap: widget.onDelete, child: Icon(Icons.delete, size: 18, color: Colors.red[400])),
                          ]
                        ],
                      ),
                      
                      // Subtítulo
                      Text(
                        widget.subtitulo,
                        style: GoogleFonts.montserrat(
                          fontSize: 12, 
                          color: widget.corSubtitulo.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Linha divisória futurista
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.corTitulo.withOpacity(0), widget.corTitulo, widget.corTitulo.withOpacity(0)]
                          )
                        ),
                      ),

                      // Preço
                      Text(
                        formatador.format(widget.valor),
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          color: widget.corTitulo,
                          fontWeight: FontWeight.w900,
                          shadows: _isHovered 
                              ? [BoxShadow(color: widget.corTitulo.withOpacity(0.5), blurRadius: 10)] 
                              : null, 
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

// ============================================================================
// WIDGET DO MINI CARROSSEL (HOME)
// ============================================================================
class CardCarrossel extends StatefulWidget {
  final List<String> fotos;
  const CardCarrossel({super.key, required this.fotos});

  @override
  State<CardCarrossel> createState() => _CardCarrosselState();
}

class _CardCarrosselState extends State<CardCarrossel> {
  final PageController _controller = PageController();
  int _atual = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.fotos.length,
          onPageChanged: (idx) => setState(() => _atual = idx),
          itemBuilder: (_, index) {
            return Image.network(
              widget.fotos[index],
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
            );
          },
        ),
        if (_atual > 0)
          Positioned(
            left: 5, top: 0, bottom: 0,
            child: Center(
              child: CircleAvatar(
                radius: 15, backgroundColor: Colors.black45,
                child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.white), onPressed: () => _controller.previousPage(duration: 300.ms, curve: Curves.ease)),
              ),
            ),
          ),
        if (widget.fotos.isNotEmpty && _atual < widget.fotos.length - 1)
          Positioned(
            right: 5, top: 0, bottom: 0,
            child: Center(
              child: CircleAvatar(
                radius: 15, backgroundColor: Colors.black45,
                child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white), onPressed: () => _controller.nextPage(duration: 300.ms, curve: Curves.ease)),
              ),
            ),
          ),
        if (widget.fotos.length > 1)
          Positioned(
            bottom: 5, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.fotos.length, (idx) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: _atual == idx ? 8 : 5,
                  height: _atual == idx ? 8 : 5,
                  decoration: BoxDecoration(color: _atual == idx ? Colors.white : Colors.white54, shape: BoxShape.circle),
                );
              }),
            ),
          ),
      ],
    );
  }
}