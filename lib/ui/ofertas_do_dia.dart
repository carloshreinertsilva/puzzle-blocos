import 'package:flutter/material.dart';

import '../core/mercado.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../services/plataforma.dart';
import '../services/progress_store.dart';
import '../shop/loja_service.dart';
import 'capi.dart';
import 'palette.dart';
import 'typography.dart';

/// The day's offers, in the shop: one legendary item for money and a common
/// and a rare one for stars with a discount. They change at midnight, the
/// same for everyone (nothing is drawn).
class OfertasDoDia extends StatefulWidget {
  const OfertasDoDia({super.key, required this.services});
  final AppServices services;

  @override
  State<OfertasDoDia> createState() => _OfertasDoDiaState();
}

class _OfertasDoDiaState extends State<OfertasDoDia> {
  bool _comprando = false;
  String? _aviso;

  ProgressStore get _store => widget.services.store;
  LojaService get _loja => widget.services.loja;

  Future<void> _comprarLendario(Cosmetic c) async {
    if (_comprando) return;
    setState(() => _comprando = true);
    final r = await _loja.comprar(Mercado.produtoDe(c));
    if (r == ResultadoCompra.ok) {
      await Wardrobe.equip(_store, c);
      widget.services.feedback.praise(4);
    }
    if (!mounted) return;
    setState(() {
      _comprando = false;
      _aviso = switch (r) {
        ResultadoCompra.ok => tr('{item} é seu!', {'item': c.label}),
        ResultadoCompra.pendente => tr(
          'Pagamento pendente: o item chega quando ele for aprovado.',
        ),
        ResultadoCompra.cancelada => null,
        _ => tr('Não deu para comprar agora. Tente de novo mais tarde.'),
      };
    });
  }

  Future<void> _comprarComEstrelas(Cosmetic c) async {
    if (!await Mercado.comprarComEstrelas(_store, c, DateTime.now())) return;
    widget.services.feedback.praise(3);
    await Wardrobe.equip(_store, c);
    final premios = await Wardrobe.awardCollections(_store);
    if (!mounted) return;
    setState(() {
      _aviso = premios.isEmpty
          ? tr('{item} é seu! Já está no Capi.', {'item': c.label})
          : tr('Coleção completa! Você ganhou: {itens}.', {
              'itens': premios.map((p) => p.label).join(', '),
            });
    });
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final falta = Mercado.ateTrocar(agora);
    final lendario = Mercado.lendarioDoDia(agora);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_rounded, color: Color(0xFFFFC94D)),
            const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(tr('Ofertas do dia'), style: displayText(20)),
              ),
            ),
            Text(
              tr('mudam em {h} h {min} min', {
                'h': falta.inHours,
                'min': falta.inMinutes % 60,
              }),
              style: bodyText(12, color: Palette.textDim),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _oferta(
          lendario,
          preco: _loja.disponivel
              ? _loja.preco(Mercado.produtoDe(lendario))
              : null,
          rotulo: _loja.disponivel
              ? null
              : noIPhone
              ? tr('Ainda não está à venda no iPhone')
              : tr('À venda no app Android'),
          onComprar: _loja.disponivel && !_comprando
              ? () => _comprarLendario(lendario)
              : null,
        ),
        for (final c in [Mercado.comumDoDia(agora), Mercado.raroDoDia(agora)])
          _oferta(
            c,
            preco: tr('{n} estrelas', {'n': Mercado.precoComDesconto(c)}),
            rotulo: tr('de {preco}', {'preco': c.preco}),
            riscado: true,
            onComprar: _store.stars >= Mercado.precoComDesconto(c)
                ? () => _comprarComEstrelas(c)
                : null,
          ),
        if (_aviso != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _aviso!,
              textAlign: TextAlign.center,
              style: bodyText(13, color: Palette.accent),
            ),
          ),
      ],
    );
  }

  Widget _oferta(
    Cosmetic c, {
    String? preco,
    String? rotulo,
    bool riscado = false,
    VoidCallback? onComprar,
  }) {
    final seu = Wardrobe.owns(_store, c);
    final look = CapiLook.of(_store).wearing(c);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.raridade.color, width: 1.6),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 56,
            child: CustomPaint(
              painter: CapiPainter(
                mood: CapiMood.happy,
                t: 0,
                hat: look.hat,
                look: look,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.label, style: displayText(15, color: Palette.text)),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RaridadeChip(c.raridade),
                    if (rotulo != null && !seu)
                      Text(
                        rotulo,
                        style: bodyText(12, color: Palette.textDim).copyWith(
                          decoration: riscado
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (seu)
            Text(tr('Seu'), style: displayText(14, color: Palette.good))
          else if (preco != null)
            Semantics(
              button: true,
              label: tr('Comprar {item} por {preco}', {
                'item': c.label,
                'preco': preco,
              }),
              excludeSemantics: true,
              onTap: onComprar,
              child: FilledButton(
                onPressed: onComprar,
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.accent,
                  foregroundColor: const Color(0xFF3A2200),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(preco, style: displayText(13)),
              ),
            ),
        ],
      ),
    );
  }
}

/// An item's rarity, as a small colored tag.
class RaridadeChip extends StatelessWidget {
  const RaridadeChip(this.r, {super.key});
  final Raridade r;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: r.color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: r.color),
    ),
    child: Text(r.label, style: displayText(10, color: r.color)),
  );
}
