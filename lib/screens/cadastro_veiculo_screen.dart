import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/veiculo_model.dart';
import '../services/veiculo_service.dart';

class CadastroVeiculoScreen extends StatefulWidget {
  final Veiculo? veiculoParaEditar;

  const CadastroVeiculoScreen({super.key, this.veiculoParaEditar});

  @override
  State<CadastroVeiculoScreen> createState() => _CadastroVeiculoScreenState();
}

class _CadastroVeiculoScreenState extends State<CadastroVeiculoScreen> {
  final _modeloController = TextEditingController();
  final _anoController = TextEditingController();
  final _kmController = TextEditingController();
  final _corController = TextEditingController();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  // LISTAS PARA GERENCIAR AS IMAGENS
  List<File> _novasImagens = []; // Fotos selecionadas agora da galeria
  List<String> _fotosExistentes = []; // Fotos (URLs) que já estavam no banco (edição)
  
  bool _isLoading = false;
  final VeiculoService _veiculoService = VeiculoService();

  @override
  void initState() {
    super.initState();
    // Se veio um veículo para editar, preenchemos os campos
    if (widget.veiculoParaEditar != null) {
      final v = widget.veiculoParaEditar!;
      _modeloController.text = v.modelo;
      _anoController.text = v.ano.toString();
      _kmController.text = v.km.toString();
      _corController.text = v.cor;
      _valorController.text = v.valor.toStringAsFixed(2);
      _descricaoController.text = v.descricao;
      
      // Carrega as fotos existentes
      _fotosExistentes = List.from(v.fotos);
    }
  }

  // --- 1. SELECIONAR MÚLTIPLAS IMAGENS ---
  Future<void> _selecionarImagens() async {
    final ImagePicker picker = ImagePicker();
    // pickMultiImage permite selecionar várias
    final List<XFile> imagens = await picker.pickMultiImage();
    
    if (imagens.isNotEmpty) {
      setState(() {
        // Adiciona as novas à lista
        _novasImagens.addAll(imagens.map((x) => File(x.path)));
      });
    }
  }

  // --- 2. UPLOAD DE LISTA DE IMAGENS ---
  Future<List<String>> _uploadTodasImagens() async {
    List<String> urls = [];
    
    for (var imagem in _novasImagens) {
      String nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString() + "_" + urls.length.toString();
      Reference ref = FirebaseStorage.instance.ref().child('veiculos/$nomeArquivo.jpg');
      
      UploadTask uploadTask = ref.putFile(imagem);
      TaskSnapshot taskSnapshot = await uploadTask;
      String url = await taskSnapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _salvarVeiculo() async {
    if (_modeloController.text.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha Modelo e Valor')));
      return;
    }

    // Validação: Tem que ter pelo menos uma foto (seja nova ou antiga)
    if (_novasImagens.isEmpty && _fotosExistentes.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos uma foto!')));
       return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Faz upload das novas fotos
      List<String> novasUrls = [];
      if (_novasImagens.isNotEmpty) {
        novasUrls = await _uploadTodasImagens();
      }

      // 2. Junta as fotos antigas com as novas
      List<String> listaFinalDeFotos = [..._fotosExistentes, ...novasUrls];

      Veiculo veiculoMontado = Veiculo(
        id: widget.veiculoParaEditar?.id,
        modelo: _modeloController.text,
        ano: int.tryParse(_anoController.text) ?? 0,
        km: double.tryParse(_kmController.text) ?? 0,
        cor: _corController.text,
        valor: double.tryParse(_valorController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
        descricao: _descricaoController.text,
        fotos: listaFinalDeFotos, // Agora passamos a lista!
      );

      // Decisão: Criar ou Atualizar?
      if (widget.veiculoParaEditar == null) {
        await _veiculoService.adicionarVeiculo(veiculoMontado);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veículo criado!')));
      } else {
        await _veiculoService.atualizarVeiculo(widget.veiculoParaEditar!.id!, veiculoMontado);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veículo atualizado!')));
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Widget auxiliar para mostrar as miniaturas
  Widget _buildPreviewFotos() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Botão de Adicionar
          GestureDetector(
            onTap: _selecionarImagens,
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 30),
                  Text("Adicionar")
                ],
              ),
            ),
          ),
          
          // Fotos Existentes (Vindas do Firebase)
          ..._fotosExistentes.map((url) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ClipRRect(
               borderRadius: BorderRadius.circular(10),
               child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
            ),
          )),

          // Fotos Novas (Do Celular)
          ..._novasImagens.map((file) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                ),
                // Pequeno ícone verde para indicar que é nova
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                )
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.veiculoParaEditar == null ? "Novo Veículo" : "Editar Veículo"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Área de Fotos (Nova Versão)
                  const Align(
                    alignment: Alignment.centerLeft, 
                    child: Text("Fotos do Veículo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  ),
                  const SizedBox(height: 10),
                  _buildPreviewFotos(),
                  
                  const SizedBox(height: 20),
                  TextField(controller: _modeloController, decoration: const InputDecoration(labelText: "Modelo")),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _anoController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Ano"))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _kmController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Km"))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _corController, decoration: const InputDecoration(labelText: "Cor")),
                  const SizedBox(height: 10),
                  TextField(controller: _valorController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Valor (R\$)")),
                  const SizedBox(height: 10),
                  TextField(controller: _descricaoController, maxLines: 3, decoration: const InputDecoration(labelText: "Descrição")),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _salvarVeiculo,
                      child: Text(widget.veiculoParaEditar == null ? "CADASTRAR" : "SALVAR ALTERAÇÕES"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}