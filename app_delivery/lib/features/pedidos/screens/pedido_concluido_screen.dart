import 'package:flutter/material.dart';
import '../../../main_screen.dart' show MainScreen;
import '../../catalogo/screens/catalogo_screen.dart' show kPrimary, kTextSecondary;

/// Tela final do fluxo, exibida após a entrega ser confirmada em
/// DetalhesPedidoScreen. O botão "Voltar ao início" limpa todo o histórico
/// de navegação, retornando à MainScreen como se fosse uma nova sessão.
class PedidoConcluidoScreen extends StatelessWidget {
  const PedidoConcluidoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wine_bar, color: kPrimary, size: 120),
              const SizedBox(height: 28),
              const Text(
                'Pedido Concluído!',
                textAlign: TextAlign.center,
                style: TextStyle(color: kPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Obrigado pela sua compra! Esperamos que aprecie sua seleção.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, fontSize: 15),
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  ),
                  child: const Text('VOLTAR AO INÍCIO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
