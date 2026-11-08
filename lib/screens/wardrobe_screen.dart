import 'dart:math';

import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../core/mercado.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../services/progress_store.dart';
import '../shop/loja_service.dart';
import '../ui/capi.dart';
import '../ui/ofertas_do_dia.dart';
import '../ui/palette.dart';
import '../ui/premio.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// Capi's wardrobe, a whole screen: Capi big on top wearing what the player
/// is trying on, the item's one action under him, the five kinds of clothes
/// as big buttons and the items in a grid. Buying lives in the shop; here
/// stars buy what is missing, and today's offers show their discount.
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key, required this.services});
  final AppServices services;

  static Future<void> show(BuildContext context, AppServices services) =>
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, _, _) => WardrobeScreen(services: services),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  Slot _slot = Slot.cabeca;
  Cosmetic? _selected;
  CapiMood _mood = CapiMood.happy;
  String? _note;
  bool _ocupado = false;

  ProgressStore get _store => widget.services.store;

  // --- Actions ---

  void _cycleMood() {
    widget.services.feedback.click();
    setState(() {
      _mood = switch (_mood) {
        CapiMood.happy => CapiMood.cheer,
        CapiMood.cheer => CapiMood.point,
        CapiMood.point => CapiMood.worried,
        _ => CapiMood.happy,
      };
    });
  }

  void _openSlot(Slot slot) {
    widget.services.feedback.click();
    setState(() {
      _slot = slot;
      _selected = null;
      _note = null;
    });
  }

  void _select(Cosmetic c) {
    widget.services.feedback.click();
    setState(() {
      _selected = c;
      _note = null;
    });
  }

  bool _isEquipped(Cosmetic c) {
    final look = CapiLook.of(_store);
    return switch (c.slot) {
      Slot.cabeca => look.hat.id == c.id,
      Slot.rosto => look.rosto == c.id,
      Slot.pescoco => look.pescoco == c.id,
      Slot.costas => look.costas == c.id,
      Slot.pelagem => look.pelagem == c.id,
    };
  }

  Future<void> _equip(Cosmetic c) async {
    widget.services.feedback.praise(2);
    await Wardrobe.equip(_store, c);
    if (mounted) setState(() => _note = null);
  }

  Future<void> _takeOff(Cosmetic c) async {
    widget.services.feedback.click();
    await Wardrobe.takeOff(_store, c.slot);
    if (mounted) setState(() => _note = null);
  }

  Future<void> _ganhou(Cosmetic c, {int praise = 3}) async {
    widget.services.feedback.praise(praise);
    await Wardrobe.equip(_store, c);
    final prizes = await Wardrobe.awardCollections(_store);
    if (!mounted) return;
    setState(() {
      _note = prizes.isEmpty
          ? tr('{item} é seu!', {'item': c.label})
          : tr('Coleção completa! Você ganhou: {itens}.', {
              'itens': prizes.map((p) => p.label).join(', '),
            });
    });
  }

  Future<void> _buy(Cosmetic c) async {
    if (await Wardrobe.buy(_store, c)) await _ganhou(c);
  }

  Future<void> _buyOffer(Cosmetic c) async {
    if (await Mercado.comprarComEstrelas(_store, c, DateTime.now())) {
      await _ganhou(c);
    }
  }

  Future<void> _buyLegendary(Cosmetic c) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final r = await widget.services.loja.comprar(Mercado.produtoDe(c));
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (r == ResultadoCompra.ok) {
      await _ganhou(c, praise: 4);
      return;
    }
    setState(() {
      _note = switch (r) {
        ResultadoCompra.pendente => tr(
          'Pagamento pendente: o item chega quando ele for aprovado.',
        ),
        ResultadoCompra.cancelada => null,
        _ => tr('Não deu para comprar agora. Tente de novo mais tarde.'),
      };
    });
  }

  /// One more video toward a rare item.
  Future<void> _video(Cosmetic c) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final ok = await widget.services.ads.rewarded(
      context,
      RewardPlacement.wardrobeItem,
    );
    if (!mounted) return;
    var note = _note;
    if (ok) {
      final ganhou = await Wardrobe.videoVisto(_store, c, DateTime.now());
      if (ganhou) {
        widget.services.feedback.praise(3);
        await Wardrobe.equip(_store, c);
        note = tr('{item} é seu!', {'item': c.label});
      } else {
        widget.services.feedback.praise(2);
        note = tr('Vídeo {feitos} de {total} para {item}.', {
          'feitos': Wardrobe.videos(_store, c),
          'total': Wardrobe.videosRaro,
          'item': c.label,
        });
      }
    }
    if (!mounted) return;
    if (ok && note != null) {
      mostrarPremio(context, note, icon: Icons.checkroom_rounded);
    }
    setState(() {
      _ocupado = false;
      _note = note;
    });
  }

  /// Today's offer price for [c], when it is one of the star offers.
  int? _precoOferta(Cosmetic c) {
    final hoje = DateTime.now();
    final ofertas = [Mercado.comumDoDia(hoje), Mercado.raroDoDia(hoje)];
    return ofertas.any((o) => o.id == c.id)
        ? Mercado.precoComDesconto(c)
        : null;
  }

  bool _lendarioDoDia(Cosmetic c) =>
      Mercado.lendarioDoDia(DateTime.now()).id == c.id;

  // --- Screen ---

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final look = CapiLook.of(_store);
    final selected = _selected;
    final preview = selected == null ? look : look.wearing(selected);
    // Trying something on adds its name and action: on short screens Capi
    // gives them room.
    final encolhe = selected != null && size.height < 760;
    final capi = (size.height * (encolhe ? 0.15 : 0.2)).clamp(96.0, 210.0);
    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  _topo(),
                  _palco(preview, capi),
                  _detalhes(selected),
                  const SizedBox(height: 8),
                  _categorias(),
                  const SizedBox(height: 6),
                  Expanded(child: _grade(look)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topo() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Row(
      children: [
        RoundIconButton(
          icon: Icons.arrow_back_rounded,
          label: tr('Voltar'),
          onTap: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Center(
            child: Semantics(
              container: true,
              header: true,
              label: tr('Guarda-Roupa do Capi'),
              excludeSemantics: true,
              child: OutlinedTitle(tr('Guarda-Roupa'), size: 26),
            ),
          ),
        ),
        _Estrelas(_store.stars),
        const SizedBox(width: 8),
        RoundIconButton(
          icon: Icons.collections_bookmark_rounded,
          label: tr('Coleções'),
          onTap: _abrirColecoes,
        ),
      ],
    ),
  );

  /// Capi, big, wearing the look being tried on. A tap changes his mood.
  Widget _palco(CapiLook preview, double capi) => Semantics(
    button: true,
    label: tr('Capi com a roupa escolhida. Toque para trocar o humor'),
    excludeSemantics: true,
    onTap: _cycleMood,
    child: GestureDetector(
      onTap: _cycleMood,
      child: Container(
        height: capi + 16,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Color(0x554F46E5), Color(0x001E1B4B)],
            radius: 0.8,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Capi(size: capi, mood: _mood, look: preview),
        ),
      ),
    ),
  );

  /// The tried-on item's name and its one action; with nothing tried on, a
  /// hint (or the last news).
  Widget _detalhes(Cosmetic? c) {
    if (c == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: _says(
          _note ?? tr('Toque num item para provar no Capi.'),
          style: bodyText(
            14,
            color: _note != null ? Palette.accent : Palette.textDim,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  c.label,
                  overflow: TextOverflow.ellipsis,
                  style: displayText(19, color: Palette.text),
                ),
              ),
              const SizedBox(width: 8),
              RaridadeChip(c.raridade),
            ],
          ),
          if (c.descricao.isNotEmpty)
            Text(
              c.descricao,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bodyText(12, color: Palette.textDim),
            ),
          if (_note != null)
            _says(_note!, style: bodyText(13, color: Palette.accent)),
          const SizedBox(height: 6),
          _acao(c),
          ?_videoAction(c),
        ],
      ),
    );
  }

  /// The one thing to do with [c]: wear it, take it off, buy it, or how to
  /// get it.
  Widget _acao(Cosmetic c) {
    final owned = Wardrobe.owns(_store, c);
    final equipped = _isEquipped(c);
    if (owned && !equipped) {
      return ChunkyButton(
        label: tr('Vestir'),
        semanticLabel: tr('Vestir {item}', {'item': c.label}),
        icon: Icons.checkroom_rounded,
        onTap: () => _equip(c),
      );
    }
    if (equipped) {
      // A hat and a coat are always worn; the rest can come off.
      if (c.slot == Slot.cabeca || c.slot == Slot.pelagem) {
        return _says(
          tr('Vestindo agora'),
          style: displayText(15, color: const Color(0xFF38BDF8)),
        );
      }
      return ChunkyButton(
        label: tr('Tirar'),
        semanticLabel: tr('Tirar {item}', {'item': c.label}),
        icon: Icons.remove_circle_outline_rounded,
        color: Palette.panelEdge,
        onTap: () => _takeOff(c),
      );
    }
    final oferta = _precoOferta(c);
    if (oferta != null) {
      if (_store.stars < oferta) {
        return _says(
          tr('Oferta do dia: {n} estrelas. Faltam {falta}.', {
            'n': oferta,
            'falta': oferta - _store.stars,
          }),
          style: bodyText(13, color: Palette.textDim),
        );
      }
      return ChunkyButton(
        label: tr('Oferta do dia: {n}', {'n': oferta}),
        semanticLabel: tr('Comprar {item} por {preco} estrelas', {
          'item': c.label,
          'preco': oferta,
        }),
        icon: Icons.local_offer_rounded,
        onTap: () => _buyOffer(c),
      );
    }
    final loja = widget.services.loja;
    if (_lendarioDoDia(c) && loja.disponivel) {
      final preco = loja.preco(Mercado.produtoDe(c));
      return ChunkyButton(
        label: tr('Oferta do dia: {preco}', {'preco': preco}),
        semanticLabel: tr('Comprar {item} por {preco}', {
          'item': c.label,
          'preco': preco,
        }),
        icon: Icons.local_offer_rounded,
        onTap: _ocupado ? () {} : () => _buyLegendary(c),
      );
    }
    final preco = c.preco;
    if (preco != null && _store.stars >= preco) {
      return ChunkyButton(
        label: tr('Comprar por {preco}', {'preco': preco}),
        semanticLabel: tr('Comprar {item} por {preco} estrelas', {
          'item': c.label,
          'preco': preco,
        }),
        icon: Icons.star_rounded,
        onTap: () => _buy(c),
      );
    }
    if (preco != null) {
      return _says(
        tr('Faltam {n} estrelas para comprar.', {'n': preco - _store.stars}),
        style: bodyText(13, color: Palette.textDim),
      );
    }
    return _says(c.comoGanhar, style: bodyText(13, color: Palette.textDim));
  }

  /// The video path for a rare item, under the star price.
  Widget? _videoAction(Cosmetic c) {
    if (c.raridade != Raridade.raro ||
        c.fonte is! Estrelas ||
        Wardrobe.owns(_store, c) ||
        !widget.services.ads.hasVideoAds) {
      return null;
    }
    final feitos = Wardrobe.videos(_store, c);
    if (!Wardrobe.podeVerVideo(_store, c, DateTime.now())) {
      return _says(
        tr(
          'Ou com vídeos: {feitos} de {total}. '
          'Volte amanhã para assistir mais.',
          {'feitos': feitos, 'total': Wardrobe.videosRaro},
        ),
        style: bodyText(12, color: Palette.textDim),
      );
    }
    return TextButton.icon(
      onPressed: _ocupado ? null : () => _video(c),
      icon: const Icon(Icons.play_circle_rounded, color: Palette.accent),
      label: Text(
        tr('Ou ganhe com vídeos: {feitos}/{total}', {
          'feitos': feitos,
          'total': Wardrobe.videosRaro,
        }),
        semanticsLabel: tr(
          'Ver vídeo para ganhar {item}: {feitos} de {total}',
          {'item': c.label, 'feitos': feitos, 'total': Wardrobe.videosRaro},
        ),
        style: bodyText(13, color: Palette.accent),
      ),
    );
  }

  /// The five kinds of clothes, all on screen, as big buttons.
  Widget _categorias() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        for (final slot in Slot.values)
          Expanded(
            child: _Categoria(
              slot: slot,
              selecionada: slot == _slot,
              tem: Wardrobe.visiveis(
                _store,
                slot,
                DateTime.now(),
              ).where((c) => Wardrobe.owns(_store, c)).length,
              total: Wardrobe.visiveis(_store, slot, DateTime.now()).length,
              onTap: () => _openSlot(slot),
            ),
          ),
      ],
    ),
  );

  Widget _grade(CapiLook look) {
    final itens = Wardrobe.visiveis(_store, _slot, DateTime.now());
    return LayoutBuilder(
      builder: (context, c) {
        final colunas = max(3, (c.maxWidth / 130).floor());
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: itens.length,
          itemBuilder: (_, i) {
            final item = itens[i];
            return _ItemTile(
              item: item,
              look: look.wearing(item),
              owned: Wardrobe.owns(_store, item),
              equipped: _isEquipped(item),
              selected: _selected?.id == item.id,
              oferta: _precoOferta(item) != null || _lendarioDoDia(item),
              precoOferta: _precoOferta(item),
              onTap: () => _select(item),
            );
          },
        );
      },
    );
  }

  // --- Collections ---

  Future<void> _abrirColecoes() async {
    widget.services.feedback.click();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Palette.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ComFechar(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  OutlinedTitle(tr('Coleções'), size: 26),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      'Junte todos os itens de uma coleção e ganhe o prêmio '
                      'dela.',
                    ),
                    textAlign: TextAlign.center,
                    style: bodyText(13, color: Palette.textDim),
                  ),
                  const SizedBox(height: 10),
                  for (final col in Wardrobe.colecoes) _colecao(col),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colecao(Colecao col) {
    final have = Wardrobe.progress(_store, col);
    final done = have == col.itens.length;
    final premio = Wardrobe.byId(col.premio)!;
    final dados = {
      'nome': col.nome,
      'tem': have,
      'total': col.itens.length,
      'premio': premio.label,
    };
    return Semantics(
      label: done
          ? tr(
              'Coleção {nome}: {tem} de {total}. Prêmio: {premio}, ganho',
              dados,
            )
          : tr('Coleção {nome}: {tem} de {total}. Prêmio: {premio}', dados),
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done ? premio.raridade.color : const Color(0x22FFFFFF),
          ),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 52,
              child: CustomPaint(
                painter: CapiPainter(
                  mood: CapiMood.happy,
                  t: 0,
                  hat: const CapiLook().wearing(premio).hat,
                  look: const CapiLook().wearing(premio),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${col.nome}  $have/${col.itens.length}',
                    style: displayText(15, color: Palette.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    col.itens
                        .map((id) {
                          final it = Wardrobe.byId(id)!;
                          final ok = _store.unlockedHats.contains(id);
                          return '${ok ? '✓' : '·'} ${it.label}';
                        })
                        .join('   '),
                    style: bodyText(12, color: Palette.textDim),
                  ),
                  Text(
                    tr('Prêmio: {premio} ({raridade})', {
                      'premio': premio.label,
                      'raridade': premio.raridade.label,
                    }),
                    style: bodyText(12, color: premio.raridade.color),
                  ),
                ],
              ),
            ),
            if (done)
              const Icon(Icons.verified_rounded, color: Color(0xFF34D399)),
          ],
        ),
      ),
    );
  }

  /// A line of text the screen reader (and the browser tests) can find.
  Widget _says(String text, {TextStyle? style}) => Semantics(
    container: true,
    label: text,
    liveRegion: true,
    excludeSemantics: true,
    child: Text(text, textAlign: TextAlign.center, style: style),
  );
}

/// The star count, top right.
class _Estrelas extends StatelessWidget {
  const _Estrelas(this.n);
  final int n;

  @override
  Widget build(BuildContext context) => Semantics(
    label: tr('{n} estrelas', {'n': n}),
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Palette.accent, size: 20),
          const SizedBox(width: 3),
          Text(formatInt(n), style: displayText(16, color: Palette.text)),
        ],
      ),
    ),
  );
}

/// One kind of clothes: a big icon, its name and how many the player has.
class _Categoria extends StatelessWidget {
  const _Categoria({
    required this.slot,
    required this.selecionada,
    required this.tem,
    required this.total,
    required this.onTap,
  });

  final Slot slot;
  final bool selecionada;
  final int tem;
  final int total;
  final VoidCallback onTap;

  static IconData _icone(Slot s) => switch (s) {
    Slot.cabeca => Icons.school_rounded,
    Slot.rosto => Icons.face_rounded,
    Slot.pescoco => Icons.dry_cleaning_rounded,
    Slot.costas => Icons.backpack_rounded,
    Slot.pelagem => Icons.palette_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final cor = selecionada ? Palette.accent : Palette.textDim;
    return Semantics(
      button: true,
      selected: selecionada,
      label: tr('{tipo}: {tem} de {total}', {
        'tipo': slot.label,
        'tem': tem,
        'total': total,
      }),
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selecionada
                ? Palette.accent.withValues(alpha: 0.18)
                : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionada ? Palette.accent : const Color(0x22FFFFFF),
              width: selecionada ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icone(slot), color: cor, size: 26),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(slot.label, style: displayText(13, color: cor)),
              ),
              Text('$tem/$total', style: bodyText(11, color: Palette.textDim)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.look,
    required this.owned,
    required this.equipped,
    required this.selected,
    required this.oferta,
    required this.precoOferta,
    required this.onTap,
  });

  final Cosmetic item;
  final CapiLook look;
  final bool owned;
  final bool equipped;
  final bool selected;

  /// One of today's offers.
  final bool oferta;

  /// Today's discounted star price, for a star offer.
  final int? precoOferta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = item.raridade;
    final status = equipped
        ? tr('em uso')
        : owned
        ? tr('seu')
        : item.preco != null
        ? tr('{n} estrelas', {'n': item.preco})
        : tr('bloqueado');
    final Widget selo;
    if (equipped) {
      selo = _Selo(tr('Vestindo'), const Color(0xFF38BDF8));
    } else if (owned) {
      selo = _Selo(tr('Seu'), Palette.good);
    } else if (item.preco != null) {
      final oferta = precoOferta;
      selo = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Palette.accent, size: 14),
          Text(
            '${oferta ?? item.preco}',
            style: displayText(
              13,
              color: oferta != null ? const Color(0xFFFF8787) : Palette.text,
            ),
          ),
          if (oferta != null) ...[
            const SizedBox(width: 3),
            Text(
              '${item.preco}',
              style: bodyText(
                11,
                color: Palette.textDim,
              ).copyWith(decoration: TextDecoration.lineThrough),
            ),
          ],
        ],
      );
    } else {
      selo = _Selo(r.label, r.color, icone: Icons.lock_rounded);
    }
    return Semantics(
      button: true,
      selected: selected,
      label: '${item.label}, ${r.label.toLowerCase()}, $status',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          decoration: BoxDecoration(
            color: selected
                ? r.color.withValues(alpha: 0.22)
                : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: r.color, width: selected ? 2.6 : 1.2),
            boxShadow: r == Raridade.lendario
                ? [
                    BoxShadow(
                      color: r.color.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: owned ? 1 : 0.6,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: CapiPainter(
                          mood: CapiMood.happy,
                          t: 0,
                          hat: look.hat,
                          look: look,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    item.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: displayText(12, color: Palette.text),
                  ),
                  const SizedBox(height: 2),
                  selo,
                ],
              ),
              if (oferta && !owned)
                Positioned(
                  left: 0,
                  top: 0,
                  child: _Selo(
                    tr('Oferta'),
                    const Color(0xFFFF6B6B),
                    cheio: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small status tag.
class _Selo extends StatelessWidget {
  const _Selo(this.texto, this.cor, {this.icone, this.cheio = false});
  final String texto;
  final Color cor;
  final IconData? icone;
  final bool cheio;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: cheio ? cor : cor.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icone != null) ...[
          Icon(icone, color: cor, size: 11),
          const SizedBox(width: 2),
        ],
        Text(texto, style: displayText(11, color: cheio ? Colors.white : cor)),
      ],
    ),
  );
}
