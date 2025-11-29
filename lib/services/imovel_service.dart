import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/imovel_model.dart';

class ImovelService {
  final CollectionReference imoveisRef = 
      FirebaseFirestore.instance.collection('imoveis');

  // Adicionar
  Future<void> adicionarImovel(Imovel imovel) async {
    try {
      await imoveisRef.add(imovel.toMap());
    } catch (e) {
      print("Erro ao adicionar imóvel: $e");
      rethrow;
    }
  }

  // Ler (Stream)
  Stream<List<Imovel>> lerImoveis() {
    return imoveisRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Imovel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // --- NOVAS FUNÇÕES ---

  // Remover
  Future<void> removerImovel(String id) async {
    try {
      await imoveisRef.doc(id).delete();
    } catch (e) {
      print("Erro ao excluir imóvel: $e");
    }
  }

  // Atualizar
  Future<void> atualizarImovel(String id, Imovel imovel) async {
    try {
      await imoveisRef.doc(id).update(imovel.toMap());
    } catch (e) {
      print("Erro ao atualizar imóvel: $e");
      rethrow;
    }
  }
}