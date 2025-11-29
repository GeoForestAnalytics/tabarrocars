import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/veiculo_model.dart'; // Importe o seu modelo aqui!

class VeiculoService {
  // Instância do banco de dados
  final CollectionReference veiculosRef = 
      FirebaseFirestore.instance.collection('veiculos');

  
  // Função para adicionar
  Future<void> adicionarVeiculo(Veiculo veiculo) async {
    try {
      await veiculosRef.add(veiculo.toMap());
      print("Veículo adicionado com sucesso!");
    } catch (e) {
      print("Erro ao adicionar: $e");
      rethrow; // Repassa o erro para a tela tratar se precisar
    }
  }

  // Função para ler os dados
  Stream<List<Veiculo>> lerVeiculos() {
    return veiculosRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Veiculo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();      
    });
  }
 Future<void> removerVeiculo(String id) async {
    try {
      await veiculosRef.doc(id).delete();
    } catch (e) {
      print("Erro ao excluir: $e");
    }
  }

  // Função para atualizar
  Future<void> atualizarVeiculo(String id, Veiculo veiculo) async {
    try {
      await veiculosRef.doc(id).update(veiculo.toMap());
      print("Veículo atualizado com sucesso!");
    } catch (e) {
      print("Erro ao atualizar: $e");
      rethrow;
    }
  }
}


