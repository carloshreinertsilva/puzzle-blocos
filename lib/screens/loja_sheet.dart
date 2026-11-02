import 'package:flutter/material.dart';

import '../core/hats.dart';
import '../core/mercado.dart';
import '../core/passe.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/progress_store.dart';
import '../shop/loja_service.dart';
import '../shop/produtos.dart';
import '../ui/capi.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';
import 'passe_sheet.dart';
import 'wardrobe_dialog.dart';

/// The shop: the starter pack (first days only), removing ads, star packs
/// and the tool kit. Payment is all Google Play's; nothing is random.
Future<void> showLoja(BuildContext context, AppServices services) {
  Analytics.event('screen_open', {'screen': 'loja'});
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _Loja(services: services),
  );
}

class _Loja extends StatefulWidget {
  const _Loja({required this.services});
  final AppServices services;

  @override
  State<_Loja> createState() => _LojaState();
}

class _LojaState extends State<_Loja> {
  Produto? _comprando;

  LojaService get _loja => widget.services.loja;
  ProgressStore get _store => widget.services.store;

  @override
  void initState() {
    super.initState();
    _loja.addListener(_mudou);
  }

  @override
  void dispose() {
    _loja.removeListener(_mudou);
    super.dispose();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  Future<void> _comprar(Produto produto) async {
    if (_comprando != null) return;
    widget.services.feedback.click();
    setState(() => _comprando = produto);
    final resultado = await _loja.comprar(produto);
    if (!mounted) return;
    setState(() => _comprando = null);
    final aviso = switch (resultado) {
      ResultadoCompra.ok => 'Pronto! ${produto.nome} é seu.',
      ResultadoCompra.pendente =>
        'Pagamento pendente. Assim que for aprovado, entregamos na hora.',
      ResultadoCompra.erro => 'Não deu certo agora. Tente de novo.',
      ResultadoCompra.indisponivel =>
        'A loja não está disponível agora. Tente mais tarde.',
      ResultadoCompra.cancelada => null,
    };
    if (resultado == ResultadoCompra.ok) widget.services.feedback.praise(3);
    if (aviso != null) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(aviso)));
    }
  }

  Future<void> _restaurar() async {
    widget.services.feedback.click();
    await _loja.restaurar();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Pronto! Suas compras foram verificadas.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final pacote = Entrega.mostraPacoteInicial(_store, agora);
    final semAnuncios = _store.adsRemoved;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OutlinedTitle('Loja do Capi', size: 28),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Palette.accent),
                  const SizedBox(width: 4),
                  Text(
                    'Você tem ${formatInt(_store.stars)} estrelas',
                    style: bodyText(14, color: Palette.textDim),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (pacote) ...[
                _Destaque(
                  produto: Produto.pacoteInicial,
                  preco: _loja.preco(Produto.pacoteInicial),
                  etiqueta: _restante(agora),
                  chapeu: CapiHat.fundador,
                  comprando: _comprando == Produto.pacoteInicial,
                  onComprar: () => _comprar(Produto.pacoteInicial),
                ),
                const SizedBox(height: 12),
              ],
              if (!semAnuncios)
                _Destaque(
                  produto: Produto.removerAnuncios,
                  preco: _loja.preco(Produto.removerAnuncios),
                  chapeu: CapiHat.vip,
                  comprando: _comprando == Produto.removerAnuncios,
                  onComprar: () => _comprar(Produto.removerAnuncios),
                )
              else
                _Linha(
                  icone: Icons.check_circle_rounded,
                  cor: Palette.good,
                  titulo: 'Sem anúncios entre fases',
                  subtitulo: 'Obrigado por apoiar o CapiBlocks!',
                ),
              const SizedBox(height: 10),
              // The pass has its own screen, with every reward shown.
              Semantics(
                button: true,
                label: 'Abrir o Passe do Capi',
                excludeSemantics: true,
                onTap: _abrirPasse,
                child: GestureDetector(
                  onTap: _abrirPasse,
                  child: _Linha(
                    icone: Icons.military_tech_rounded,
                    cor: Palette.accent,
                    titulo: 'Passe do Capi',
                    subtitulo: PasseDoCapi.premium(_store, DateTime.now())
                        ? 'Premium liberado nesta temporada. Toque para ver.'
                        : 'Trilha premium da temporada: '
                              '${_loja.preco(Produto.passeCapi)}. Toque para ver.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Abrir o Mercado do Capi',
                excludeSemantics: true,
                onTap: _abrirMercado,
                child: GestureDetector(
                  onTap: _abrirMercado,
                  child: _Linha(
                    icone: Icons.storefront_rounded,
                    cor: const Color(0xFFFFC94D),
                    titulo: 'Mercado do Capi',
                    subtitulo:
                        'Hoje: ${Mercado.lendarioDoDia(DateTime.now()).label} '
                        '(lendário). Ofertas novas todo dia.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Estrelas', style: displayText(20)),
              ),
              const SizedBox(height: 8),
              for (final p in [
                Produto.estrelas150,
                Produto.estrelas400,
                Produto.estrelas1000,
              ])
                _Item(
                  produto: p,
                  icone: Icons.star_rounded,
                  cor: Palette.accent,
                  preco: _loja.preco(p),
                  comprando: _comprando == p,
                  onComprar: () => _comprar(p),
                ),
              _Item(
                produto: Produto.kitFerramentas,
                icone: Icons.handyman_rounded,
                cor: Palette.blocks[4],
                preco: _loja.preco(Produto.kitFerramentas),
                comprando: _comprando == Produto.kitFerramentas,
                onComprar: () => _comprar(Produto.kitFerramentas),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _restaurar,
                child: Text(
                  'Restaurar compras',
                  style: displayText(16, color: Palette.textDim),
                ),
              ),
              Text(
                'O pagamento é feito pelo Google Play. Nada aqui é sorteio: '
                'você sempre sabe o que está comprando.',
                textAlign: TextAlign.center,
                style: bodyText(12, color: Palette.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirMercado() {
    final services = widget.services;
    final nav = Navigator.of(context);
    nav.pop();
    WardrobeDialog.show(nav.context, services, mercado: true);
  }

  void _abrirPasse() {
    final services = widget.services;
    final nav = Navigator.of(context);
    nav.pop();
    showPasse(nav.context, services);
  }

  String _restante(DateTime agora) {
    final inicio = _store.firstOpenAt ?? agora;
    final falta = inicio.add(ofertaPacoteInicial).difference(agora);
    final horas = falta.inHours;
    return horas >= 24
        ? 'Oferta de boas-vindas: acaba em ${(horas / 24).ceil()} dias'
        : 'Oferta de boas-vindas: acaba em ${horas < 1 ? 1 : horas} h';
  }
}

/// A big card: the starter pack or removing ads, with Capi wearing the hat
/// that comes with it.
class _Destaque extends StatelessWidget {
  const _Destaque({
    required this.produto,
    required this.preco,
    required this.chapeu,
    required this.comprando,
    required this.onComprar,
    this.etiqueta,
  });

  final Produto produto;
  final String preco;
  final CapiHat chapeu;
  final bool comprando;
  final VoidCallback onComprar;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3B2A7A), Color(0xFF241B55)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Palette.accent.withValues(alpha: 0.6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (etiqueta != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              etiqueta!,
              style: bodyText(12, color: Palette.accent, weight: 700),
            ),
          ),
        Row(
          children: [
            Capi(size: 72, hat: chapeu),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto.nome, style: displayText(22)),
                  const SizedBox(height: 2),
                  Text(
                    produto.descricao,
                    style: bodyText(13, color: Palette.textDim),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          button: true,
          label: 'Comprar ${produto.nome} por $preco',
          excludeSemantics: true,
          onTap: comprando ? null : onComprar,
          child: ChunkyButton(
            label: comprando ? 'Abrindo…' : preco,
            icon: Icons.shopping_bag_rounded,
            onTap: comprando ? null : onComprar,
          ),
        ),
      ],
    ),
  );
}

/// A row in the list: a star pack or the tool kit.
class _Item extends StatelessWidget {
  const _Item({
    required this.produto,
    required this.icone,
    required this.cor,
    required this.preco,
    required this.comprando,
    required this.onComprar,
  });

  final Produto produto;
  final IconData icone;
  final Color cor;
  final String preco;
  final bool comprando;
  final VoidCallback onComprar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      button: true,
      label: 'Comprar ${produto.nome} por $preco',
      excludeSemantics: true,
      onTap: comprando ? null : onComprar,
      child: Material(
        color: Palette.emptyCell,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: comprando ? null : onComprar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icone, color: cor, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produto.nome, style: displayText(17)),
                      if (produto.descricao.isNotEmpty)
                        Text(
                          produto.descricao,
                          style: bodyText(12, color: Palette.textDim),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comprando ? '…' : preco,
                    style: displayText(15, color: const Color(0xFF3A2200)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icone;
  final Color cor;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Palette.emptyCell,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icone, color: cor, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: displayText(16)),
              Text(subtitulo, style: bodyText(12, color: Palette.textDim)),
            ],
          ),
        ),
      ],
    ),
  );
}
