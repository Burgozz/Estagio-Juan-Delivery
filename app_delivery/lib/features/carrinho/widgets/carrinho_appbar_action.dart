import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/carrinho_controller.dart';
import '../screens/carrinho_screen.dart';

/// Ícone de carrinho com badge de quantidade, usado na AppBar de
/// InicioScreen, CatalogoScreen (Busca) e ProdutoDetalheScreen. Ao tocar,
/// navega para a CarrinhoScreen.
class CarrinhoAppBarAction extends StatelessWidget {
  const CarrinhoAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarrinhoController>(
      builder: (context, carrinho, _) {
        final quantidade = carrinho.totalItens;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                tooltip: 'Carrinho',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
                ),
              ),
              if (quantidade > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        quantidade > 99 ? '99+' : '$quantidade',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
