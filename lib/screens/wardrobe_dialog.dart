import 'package:flutter/material.dart';

import '../core/wardrobe.dart';
import '../main.dart';
import '../services/progress_store.dart';
import '../ui/capi.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// Capi's wardrobe: items by slot, with rarity, prices in stars, a try-on
/// preview and the collections.
class WardrobeDialog extends StatefulWidget {
  const WardrobeDialog({super.key, required this.services});
  final AppServices services;

  static Future<void> show(BuildContext context, AppServices services) {
    return showDialog(
      context: context,
      builder: (_) => WardrobeDialog(services: services),
    );
  }

  @override
  State<WardrobeDialog> createState() => _WardrobeDialogState();
}

class _WardrobeDialogState extends State<WardrobeDialog> {
  /// The open tab: a slot, or null for the collections.
  Slot? _tab = Slot.cabeca;
  Cosmetic? _selected;
  CapiMood _previewMood = CapiMood.happy;
  String? _note;

  ProgressStore get _store => widget.services.store;

  void _cycleMood() {
    widget.services.feedback.click();
    setState(() {
      _previewMood = switch (_previewMood) {
        CapiMood.happy => CapiMood.cheer,
        CapiMood.cheer => CapiMood.point,
        CapiMood.point => CapiMood.worried,
        CapiMood.worried => CapiMood.happy,
        _ => CapiMood.happy,
      };
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
    setState(() => _note = null);
  }

  Future<void> _takeOff(Cosmetic c) async {
    widget.services.feedback.click();
    await Wardrobe.takeOff(_store, c.slot);
    setState(() => _note = null);
  }

  Future<void> _buy(Cosmetic c) async {
    if (!await Wardrobe.buy(_store, c)) return;
    widget.services.feedback.praise(3);
    await Wardrobe.equip(_store, c);
    final prizes = await Wardrobe.awardCollections(_store);
    setState(() {
      _note = prizes.isEmpty
          ? '${c.label} é seu!'
          : 'Coleção completa! Você ganhou: '
                '${prizes.map((p) => p.label).join(', ')}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final look = CapiLook.of(_store);
    final selected = _selected;
    final preview = selected == null ? look : look.wearing(selected);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
        child: CardPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(context),
              const SizedBox(height: 8),
              // The preview: what Capi wears, with the selected item on.
              Semantics(
                button: true,
                label: 'Capi com a roupa escolhida. Toque para trocar o humor',
                excludeSemantics: true,
                onTap: _cycleMood,
                child: GestureDetector(
                  onTap: _cycleMood,
                  child: Container(
                    height: 132,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x334F46E5), Color(0x111E1B4B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x33818CF8)),
                    ),
                    child: Center(
                      child: Capi(size: 118, mood: _previewMood, look: preview),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _details(selected),
              const SizedBox(height: 8),
              _tabs(),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: _tab == null ? _collections() : _grid(_tab!, look),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Row(
    children: [
      const Icon(Icons.checkroom_rounded, color: Color(0xFFF59E0B), size: 24),
      const SizedBox(width: 8),
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            'Guarda-Roupa',
            semanticsLabel: 'Guarda-Roupa do Capi',
            style: displayText(18, color: Palette.text),
          ),
        ),
      ),
      Semantics(
        label: '${_store.stars} estrelas',
        excludeSemantics: true,
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Palette.accent, size: 20),
            const SizedBox(width: 2),
            Text(
              '${_store.stars}',
              style: displayText(16, color: Palette.text),
            ),
          ],
        ),
      ),
      Semantics(
        button: true,
        label: 'Fechar',
        excludeSemantics: true,
        onTap: () => Navigator.of(context).pop(),
        child: IconButton(
          icon: const Icon(Icons.close_rounded, color: Palette.textDim),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    ],
  );

  Widget _details(Cosmetic? c) {
    if (c == null) {
      return Text(
        _note ?? 'Toque num item para provar no Capi.',
        textAlign: TextAlign.center,
        style: bodyText(
          13,
          color: _note != null ? Palette.accent : Palette.textDim,
        ),
      );
    }
    final owned = Wardrobe.owns(_store, c);
    final equipped = _isEquipped(c);
    final preco = c.preco;
    final canTakeOff =
        equipped && c.slot != Slot.cabeca && c.slot != Slot.pelagem;

    Widget action;
    if (owned && !equipped) {
      action = ChunkyButton(
        label: 'Equipar',
        semanticLabel: 'Equipar ${c.label}',
        icon: Icons.check_circle_rounded,
        onTap: () => _equip(c),
      );
    } else if (canTakeOff) {
      action = ChunkyButton(
        label: 'Tirar',
        semanticLabel: 'Tirar ${c.label}',
        icon: Icons.remove_circle_outline_rounded,
        color: Palette.panelEdge,
        onTap: () => _takeOff(c),
      );
    } else if (equipped) {
      action = Text(
        'Em uso',
        style: displayText(14, color: const Color(0xFF38BDF8)),
      );
    } else if (preco != null && _store.stars >= preco) {
      action = ChunkyButton(
        label: 'Comprar por $preco',
        semanticLabel: 'Comprar ${c.label} por $preco estrelas',
        icon: Icons.star_rounded,
        onTap: () => _buy(c),
      );
    } else if (preco != null) {
      action = _says(
        'Faltam ${preco - _store.stars} estrelas para comprar.',
        textAlign: TextAlign.center,
        style: bodyText(13, color: Palette.textDim),
      );
    } else {
      action = _says(
        c.comoGanhar,
        textAlign: TextAlign.center,
        style: bodyText(13, color: Palette.textDim),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                c.label,
                overflow: TextOverflow.ellipsis,
                style: displayText(17, color: Palette.accent),
              ),
            ),
            const SizedBox(width: 6),
            _RarityChip(c.raridade),
          ],
        ),
        if (c.descricao.isNotEmpty)
          Text(
            c.descricao,
            textAlign: TextAlign.center,
            style: bodyText(12, color: Palette.textDim),
          ),
        if (_note != null)
          _says(
            _note!,
            textAlign: TextAlign.center,
            style: bodyText(12, color: Palette.accent),
          ),
        const SizedBox(height: 6),
        action,
      ],
    );
  }

  /// A line of text the screen reader (and the browser tests) can find.
  Widget _says(String text, {TextAlign? textAlign, TextStyle? style}) =>
      Semantics(
        container: true,
        label: text,
        liveRegion: true,
        excludeSemantics: true,
        child: Text(text, textAlign: textAlign, style: style),
      );

  Widget _tabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final tab in [...Slot.values, null])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              button: true,
              selected: _tab == tab,
              label: 'Aba ${tab?.label ?? 'Coleções'}',
              excludeSemantics: true,
              onTap: () => _openTab(tab),
              child: ChoiceChip(
                label: Text(tab?.label ?? 'Coleções', style: bodyText(13)),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                selected: _tab == tab,
                showCheckmark: false,
                selectedColor: Palette.accent.withValues(alpha: 0.35),
                backgroundColor: const Color(0x22FFFFFF),
                side: BorderSide(
                  color: _tab == tab ? Palette.accent : const Color(0x33FFFFFF),
                ),
                onSelected: (_) => _openTab(tab),
              ),
            ),
          ),
      ],
    ),
  );

  void _openTab(Slot? tab) {
    widget.services.feedback.click();
    setState(() {
      _tab = tab;
      _selected = null;
      _note = null;
    });
  }

  Widget _grid(Slot slot, CapiLook look) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      for (final c in Wardrobe.inSlot(slot))
        _ItemTile(
          item: c,
          look: look.wearing(c),
          owned: Wardrobe.owns(_store, c),
          equipped: _isEquipped(c),
          selected: _selected?.id == c.id,
          onTap: () {
            widget.services.feedback.click();
            setState(() {
              _selected = c;
              _note = null;
            });
          },
        ),
    ],
  );

  Widget _collections() => Column(
    children: [
      Text(
        'Junte todos os itens de uma coleção e ganhe o prêmio dela.',
        textAlign: TextAlign.center,
        style: bodyText(12, color: Palette.textDim),
      ),
      const SizedBox(height: 6),
      for (final col in Wardrobe.colecoes) _collectionRow(col),
    ],
  );

  Widget _collectionRow(Colecao col) {
    final have = Wardrobe.progress(_store, col);
    final done = have == col.itens.length;
    final premio = Wardrobe.byId(col.premio)!;
    return Semantics(
      label:
          'Coleção ${col.nome}: $have de ${col.itens.length}. '
          'Prêmio: ${premio.label}${done ? ', ganho' : ''}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done ? premio.raridade.color : const Color(0x22FFFFFF),
          ),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 48,
              child: CustomPaint(
                painter: CapiPainter(
                  mood: CapiMood.happy,
                  t: 0,
                  hat: const CapiLook().wearing(premio).hat,
                  look: const CapiLook().wearing(premio),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${col.nome}  $have/${col.itens.length}',
                    style: displayText(14, color: Palette.text),
                  ),
                  Text(
                    col.itens
                        .map((id) {
                          final it = Wardrobe.byId(id)!;
                          final ok = _store.unlockedHats.contains(id);
                          return '${ok ? '✓' : '·'} ${it.label}';
                        })
                        .join('   '),
                    style: bodyText(11, color: Palette.textDim),
                  ),
                  Text(
                    'Prêmio: ${premio.label} (${premio.raridade.label})',
                    style: bodyText(11, color: premio.raridade.color),
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
}

class _RarityChip extends StatelessWidget {
  const _RarityChip(this.r);
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

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.look,
    required this.owned,
    required this.equipped,
    required this.selected,
    required this.onTap,
  });

  final Cosmetic item;
  final CapiLook look;
  final bool owned;
  final bool equipped;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = item.raridade;
    final status = equipped
        ? 'em uso'
        : owned
        ? 'seu'
        : item.preco != null
        ? '${item.preco} estrelas'
        : 'bloqueado';
    return Semantics(
      button: true,
      selected: selected,
      label: '${item.label}, ${r.label.toLowerCase()}, $status',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 84,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          decoration: BoxDecoration(
            color: selected
                ? r.color.withValues(alpha: 0.22)
                : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: r.color, width: selected ? 2.4 : 1.2),
            boxShadow: r == Raridade.lendario
                ? [
                    BoxShadow(
                      color: r.color.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: owned ? 1 : 0.55,
                    child: SizedBox.square(
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
                  ),
                  if (!owned)
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  if (equipped)
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF38BDF8),
                        size: 18,
                      ),
                    ),
                ],
              ),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: displayText(11, color: Palette.text),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!owned && item.preco != null) ...[
                    const Icon(
                      Icons.star_rounded,
                      color: Palette.accent,
                      size: 12,
                    ),
                    Text(
                      '${item.preco}',
                      style: bodyText(11, color: Palette.text),
                    ),
                  ] else
                    Text(
                      equipped ? 'EM USO' : (owned ? 'Seu' : r.label),
                      style: bodyText(
                        10,
                        color: equipped ? const Color(0xFF38BDF8) : r.color,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
