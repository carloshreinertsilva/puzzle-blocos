import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/convites.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/convites_servidor.dart';
import '../services/progress_store.dart';
import '../ui/capi.dart';
import '../ui/ofertas_do_dia.dart';
import '../ui/palette.dart';
import '../ui/premio.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// Inviting friends: the reward steps, this player's code, sharing it, and
/// typing a friend's code in.
Future<void> showConvites(BuildContext context, AppServices services) {
  Analytics.event('screen_open', {'screen': 'convites'});
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Palette.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ComFechar(child: _Convites(services: services)),
  );
}

class _Convites extends StatefulWidget {
  const _Convites({required this.services});
  final AppServices services;

  @override
  State<_Convites> createState() => _ConvitesState();
}

class _ConvitesState extends State<_Convites> {
  String? _codigo;
  final _campo = TextEditingController();
  String? _aviso;
  bool _avisoBom = false;

  ProgressStore get _store => widget.services.store;

  @override
  void initState() {
    super.initState();
    Convites.meuCodigo(_store).then((c) {
      if (mounted) setState(() => _codigo = c);
    });
    // The latest count of friends (and rewards reached).
    ConvitesServidor.sincronizar(_store).then((novas) {
      if (!mounted) return;
      for (final m in novas) {
        mostrarPremio(
          context,
          tr('Você ganhou: {premio}!', {'premio': m.texto}),
        );
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Future<void> _compartilhar() async {
    final codigo = _codigo ?? await Convites.meuCodigo(_store);
    widget.services.feedback.click();
    Analytics.event('convite_compartilhado', {});
    if (!kIsWeb) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: Convites.mensagem(codigo),
            subject: tr('Vem jogar CapiBlocks comigo!'),
          ),
        );
        return;
      } catch (_) {
        // No share sheet: copy it instead.
      }
    }
    await Clipboard.setData(ClipboardData(text: Convites.mensagem(codigo)));
    if (mounted) {
      setState(() {
        _aviso = tr('Convite copiado! Cole no WhatsApp.');
        _avisoBom = true;
      });
    }
  }

  Future<void> _usar() async {
    final texto = _campo.text;
    final codigo = Convites.normalizar(texto);
    if (codigo == null) {
      setState(() {
        _aviso = tr(
          'O código tem 6 letras e números. Confira e tente de novo.',
        );
        _avisoBom = false;
      });
      return;
    }
    if (codigo == _store.conviteCodigo) {
      setState(() {
        _aviso = tr('Esse é o seu código: mande para um amigo!');
        _avisoBom = false;
      });
      return;
    }
    if (!await Convites.usar(_store, codigo)) return;
    widget.services.feedback.praise(3);
    Analytics.event('convite_usado', {});
    if (!mounted) return;
    mostrarPremio(
      context,
      tr('Presente do convite: {n} estrelas e {item}!', {
        'n': Convites.presenteEstrelas,
        'item': Wardrobe.byId(Convites.itemPresente)!.label,
      }),
    );
    setState(() {
      _aviso = null;
      _campo.clear();
    });
    // Counts for the friend once this player reaches level 5.
    await ConvitesServidor.sincronizar(_store);
  }

  @override
  Widget build(BuildContext context) {
    final amigos = _store.conviteAmigos;
    final embaixador = Convites.embaixador(_store);
    final coroa = Wardrobe.byId('coroa_amizade')!;
    final look = CapiLook.of(_store).wearing(coroa);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: OutlinedTitle(tr('Convide amigos'), size: 28)),
              if (embaixador)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x334DABF7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4DABF7)),
                    ),
                    child: Text(
                      tr('Capi Embaixador'),
                      style: displayText(14, color: const Color(0xFF74C0FC)),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox.square(
                    dimension: 84,
                    child: CustomPaint(
                      painter: CapiPainter(
                        mood: CapiMood.cheer,
                        t: 0,
                        hat: look.hat,
                        look: look,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(
                        'Chame amigos para a Vila do Capi! Quem entra pelo '
                        'seu convite ganha {n} estrelas e o {item}. Cada '
                        'amigo que chegar à fase {fase} conta para os seus '
                        'prêmios.',
                        {
                          'n': Convites.presenteEstrelas,
                          'item': Wardrobe.byId(Convites.itemPresente)!.label,
                          'fase': Convites.faseQueConta,
                        },
                      ),
                      style: bodyText(13, color: Palette.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final m in Convites.metas) _meta(m, amigos),
              const SizedBox(height: 4),
              _texto(
                ConvitesServidor.ativo
                    ? trN(
                        amigos,
                        '{n} amigo já chegou à fase {fase}',
                        '{n} amigos já chegaram à fase {fase}',
                        {'fase': Convites.faseQueConta},
                      )
                    : tr('Os convites contam no app do celular.'),
                bodyText(13, color: Palette.textDim),
              ),
              const SizedBox(height: 12),
              if (_codigo != null)
                _texto(
                  tr('Seu código: {codigo}', {'codigo': _codigo}),
                  displayText(18, color: Palette.accent),
                ),
              const SizedBox(height: 8),
              ChunkyButton(
                big: true,
                icon: Icons.share_rounded,
                label: tr('Convidar pelo WhatsApp'),
                semanticLabel: tr('Compartilhar convite'),
                onTap: _compartilhar,
              ),
              if (_store.conviteUsado == null) ...[
                const SizedBox(height: 18),
                Text(
                  tr('Ganhou um convite? Digite o código:'),
                  style: displayText(15, color: Palette.text),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _campo,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 8,
                        style: displayText(18, color: Palette.text),
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: tr('Código do convite'),
                          labelStyle: bodyText(13, color: Palette.textDim),
                          hintText: 'ABC234',
                          hintStyle: displayText(18, color: Palette.textDim),
                          filled: true,
                          fillColor: const Color(0x22FFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _usar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // A fixed width: a ChunkyButton fills the row by itself.
                    SizedBox(
                      width: 104,
                      child: ChunkyButton(
                        label: tr('Usar'),
                        semanticLabel: tr('Usar código do convite'),
                        onTap: _usar,
                      ),
                    ),
                  ],
                ),
              ],
              if (_aviso != null) ...[
                const SizedBox(height: 8),
                _texto(
                  _aviso!,
                  bodyText(
                    13,
                    color: _avisoBom ? Palette.good : const Color(0xFFFF8787),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// One reward step: how many friends, the prize, and whether it is given.
  Widget _meta(MetaConvite m, int amigos) {
    final dada = _store.conviteMetasDadas.contains(m.amigos);
    final item = m.item == null ? null : Wardrobe.byId(m.item!);
    final rotulo = trN(
      m.amigos,
      '{n} amigo: {premio}',
      '{n} amigos: {premio}',
      {'premio': m.texto},
    );
    return Semantics(
      container: true,
      label: dada ? tr('{meta}, ganho', {'meta': rotulo}) : rotulo,
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: dada ? const Color(0x2234D399) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item?.raridade.color ?? Palette.accent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 44,
              child: item == null
                  ? const Icon(
                      Icons.star_rounded,
                      color: Palette.accent,
                      size: 32,
                    )
                  : CustomPaint(
                      painter: CapiPainter(
                        mood: CapiMood.happy,
                        t: 0,
                        hat: const CapiLook().wearing(item).hat,
                        look: const CapiLook().wearing(item),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trN(m.amigos, '{n} amigo', '{n} amigos'),
                    style: bodyText(12, color: Palette.textDim),
                  ),
                  Text(m.texto, style: displayText(16, color: Palette.text)),
                ],
              ),
            ),
            if (item != null) RaridadeChip(item.raridade),
            if (dada) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded, color: Palette.good),
            ],
          ],
        ),
      ),
    );
  }

  /// Text the screen reader (and the browser tests) can find.
  Widget _texto(String text, TextStyle style) => Semantics(
    container: true,
    liveRegion: true,
    label: text,
    excludeSemantics: true,
    child: Text(text, textAlign: TextAlign.center, style: style),
  );
}

/// A friend's invite arrived (the link, or the Play Store on install): the
/// welcome gift, one tap away. Shown over whatever is open.
Route<void> rotaConviteRecebido(AppServices services, String codigo) =>
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0xB3070A20),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) =>
          _ConviteRecebido(services: services, codigo: codigo),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );

Future<void> mostrarConviteRecebido(
  BuildContext context,
  AppServices services,
  String codigo,
) {
  final store = services.store;
  if (store.conviteUsado != null || codigo == store.conviteCodigo) {
    return Future.value();
  }
  return Navigator.of(context).push(rotaConviteRecebido(services, codigo));
}

class _ConviteRecebido extends StatefulWidget {
  const _ConviteRecebido({required this.services, required this.codigo});
  final AppServices services;
  final String codigo;

  @override
  State<_ConviteRecebido> createState() => _ConviteRecebidoState();
}

class _ConviteRecebidoState extends State<_ConviteRecebido> {
  bool _pegou = false;

  Future<void> _pegar() async {
    final store = widget.services.store;
    if (!await Convites.usar(store, widget.codigo)) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    widget.services.feedback.praise(3);
    Analytics.event('convite_usado', {'origem': 'link'});
    if (mounted) setState(() => _pegou = true);
    await ConvitesServidor.sincronizar(store);
  }

  @override
  Widget build(BuildContext context) {
    final item = Wardrobe.byId(Convites.itemPresente)!;
    final look = CapiLook.of(widget.services.store).wearing(item);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: CardPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedTitle(
                _pegou ? tr('Presente seu!') : tr('Você foi convidado!'),
                size: 26,
              ),
              const SizedBox(height: 8),
              SizedBox.square(
                dimension: 110,
                child: CustomPaint(
                  painter: CapiPainter(
                    mood: CapiMood.cheer,
                    t: 0,
                    hat: look.hat,
                    look: look,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _pegou
                    ? tr(
                        '{n} estrelas e o {item} já estão com você. Bom jogo!',
                        {'n': Convites.presenteEstrelas, 'item': item.label},
                      )
                    : tr(
                        'Um amigo te chamou para a Vila do Capi. Seu '
                        'presente: {n} estrelas e o {item}.',
                        {'n': Convites.presenteEstrelas, 'item': item.label},
                      ),
                textAlign: TextAlign.center,
                style: bodyText(15, color: Palette.text),
              ),
              const SizedBox(height: 14),
              ChunkyButton(
                big: true,
                icon: _pegou
                    ? Icons.play_arrow_rounded
                    : Icons.card_giftcard_rounded,
                label: _pegou ? tr('Jogar') : tr('Pegar presente'),
                onTap: _pegou ? () => Navigator.of(context).pop() : _pegar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
