import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart'; // <--- Import do GPS
import '../models/imovel_model.dart';
import '../services/imovel_service.dart';

class CadastroImovelScreen extends StatefulWidget {
  final Imovel? imovelParaEditar;
  const CadastroImovelScreen({super.key, this.imovelParaEditar});

  @override
  State<CadastroImovelScreen> createState() => _CadastroImovelScreenState();
}

class _CadastroImovelScreenState extends State<CadastroImovelScreen> {
  final _tituloController = TextEditingController();
  final _localController = TextEditingController();
  final _quartosController = TextEditingController();
  final _areaController = TextEditingController();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  List<File> _novasImagens = [];
  List<String> _fotosExistentes = [];
  
  // Variáveis para guardar a localização
  double? _latitude;
  double? _longitude;
  bool _obtendoLocalizacao = false;

  bool _isLoading = false;
  final ImovelService _imovelService = ImovelService();

  @override
  void initState() {
    super.initState();
    if (widget.imovelParaEditar != null) {
      final i = widget.imovelParaEditar!;
      _tituloController.text = i.titulo;
      _localController.text = i.localizacao;
      _quartosController.text = i.quartos.toString();
      _areaController.text = i.area.toString();
      _valorController.text = i.valor.toStringAsFixed(2);
      _descricaoController.text = i.descricao;
      _fotosExistentes = List.from(i.fotos);
      // Carrega localização existente
      _latitude = i.latitude;
      _longitude = i.longitude;
    }
  }

  // --- FUNÇÃO PARA PEGAR GPS ---
  Future<void> _capturarLocalizacao() async {
    setState(() => _obtendoLocalizacao = true);

    try {
      // 1. Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "Permissão de localização negada";
        }
      }

      // 2. Pega a posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Localização capturada com sucesso! 📍')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao pegar localização: $e')),
      );
    } finally {
      setState(() => _obtendoLocalizacao = false);
    }
  }

  Future<void> _selecionarImagens() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> imagens = await picker.pickMultiImage();
    if (imagens.isNotEmpty) {
      setState(() => _novasImagens.addAll(imagens.map((x) => File(x.path))));
    }
  }

  Future<List<String>> _uploadTodasImagens() async {
    List<String> urls = [];
    for (var imagem in _novasImagens) {
      String nomeArquivo = "imovel_${DateTime.now().millisecondsSinceEpoch}_${urls.length}";
      Reference ref = FirebaseStorage.instance.ref().child('imoveis/$nomeArquivo.jpg');
      await ref.putFile(imagem);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _salvarImovel() async {
    if (_tituloController.text.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha Título e Valor')));
      return;
    }

    // Opcional: Obrigar a ter localização? Por enquanto vou deixar opcional.
    
    setState(() => _isLoading = true);
    try {
      List<String> novasUrls = [];
      if (_novasImagens.isNotEmpty) novasUrls = await _uploadTodasImagens();

      Imovel imovelMontado = Imovel(
        id: widget.imovelParaEditar?.id,
        titulo: _tituloController.text,
        localizacao: _localController.text,
        quartos: int.tryParse(_quartosController.text) ?? 0,
        area: double.tryParse(_areaController.text) ?? 0,
        valor: double.tryParse(_valorController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
        descricao: _descricaoController.text,
        fotos: [..._fotosExistentes, ...novasUrls],
        latitude: _latitude,   // Salva no banco
        longitude: _longitude, // Salva no banco
      );

      if (widget.imovelParaEditar == null) {
        await _imovelService.adicionarImovel(imovelMontado);
      } else {
        await _imovelService.atualizarImovel(widget.imovelParaEditar!.id!, imovelMontado);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPreviewFotos() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _selecionarImagens,
            child: Container(
              width: 80, margin: const EdgeInsets.only(right: 10),
              color: Colors.grey[300], child: const Icon(Icons.add_a_photo),
            ),
          ),
          ..._fotosExistentes.map((url) => Image.network(url, width: 100, fit: BoxFit.cover)),
          ..._novasImagens.map((file) => Image.file(file, width: 100, fit: BoxFit.cover)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.imovelParaEditar == null ? "Novo Imóvel" : "Editar Imóvel")),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Fotos do Imóvel", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPreviewFotos(),
            const SizedBox(height: 20),
            
            TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Título (Ex: Casa Centro)")),
            TextField(controller: _localController, decoration: const InputDecoration(labelText: "Endereço por escrito")),
            
            const SizedBox(height: 10),
            
            // --- BOTÃO DE PEGAR COORDENADAS ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Column(
                children: [
                  if (_latitude != null) 
                    Text(
                      "Coordenadas Salvas: ✅\nLat: $_latitude\nLong: $_longitude",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 5),
                  ElevatedButton.icon(
                    onPressed: _obtendoLocalizacao ? null : _capturarLocalizacao,
                    icon: _obtendoLocalizacao 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.my_location),
                    label: Text(_obtendoLocalizacao ? "Obtendo..." : "USAR MINHA LOCALIZAÇÃO ATUAL"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                  const Text("Esteja no local do imóvel para usar esta função.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            // ----------------------------------

            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _quartosController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Quartos"))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _areaController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Área (m²)"))),
            ]),
            TextField(controller: _valorController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Valor (R\$)")),
            TextField(controller: _descricaoController, maxLines: 3, decoration: const InputDecoration(labelText: "Descrição")),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _salvarImovel, child: const Text("SALVAR"))),
          ],
        ),
      ),
    );
  }
}