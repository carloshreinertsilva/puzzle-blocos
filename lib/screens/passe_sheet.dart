import 'package:flutter/material.dart';

import '../core/passe.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/progress_store.dart';
import '../shop/loja_service.dart';
import '../shop/produtos.dart';
import '../ui/capi.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// The Passe do Capi: this season's track, free and premium rewards side by
/// side, every reward visible from the start.
Future<void> showPasse(BuildContext context, AppServices services) {
  Analytics.event('screen_open', {'screen': 'passe'});
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _Passe(services: services),
  );
}

/// A season item and where on the track it comes from.
typedef _ItemDaTemporada = ({Cosmetic item, String origem});

class _Passe extends StatefulWidget {
  const _Passe({required this.services});
  final AppServices services;

  @override
  State<_Passe> createState() => _PasseState();
}

class _PasseState extends State<_Passe> {
  bool _comprando = false;
  String? _aviso;

  /// The season item Capi is trying on in the highlight.
  String? _provando;

  ProgressStore get _store => widget.services.store;
  LojaService get _loja => widget.services.loja;

  /// Height of one level on the track.
  static const _alturaNivel = 60.0;

  /// Width of the track's middle column (the line, the levels and Capi).
  static const _larguraTrilha = 50.0;

  @override
  void initState() {
    super.initState();
    _loja.addListener(_mudou);
    if (!_loja.disponivel) _loja.iniciar();
  }

  @override
  void dispose() {
    _loja.removeListener(_mudou);
    super.dispose();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  Future<void> _pegar(int n, {required bool premium}) async {
    final ok = await PasseDoCapi.pegar(
      _store,
      DateTime.now(),
      n,
      trilhaPremium: premium,
    );
    if (!ok || !mounted) return;
    widget.services.feedback.praise(2);
    final nivel = PasseDoCapi.trilha(DateTime.now())[n - 1];
    final r = premium ? nivel.premium : nivel.gratis;
    setState(() => _aviso = tr('Você ganhou: {premio}!', {'premio': r.texto}));
  }

  Future<void> _comprar() async {
    if (_comprando) return;
    setState(() => _comprando = true);
    final r = await _loja.comprar(Produto.passeCapi);
    if (!mounted) return;
    setState(() {
      _comprando = false;
      _aviso = switch (r) {
        ResultadoCompra.ok => switch (_exclusivo) {
          final item? => tr(
            'Trilha premium liberada! {item} já está no Capi.',
            {'item': item.label},
          ),
          null => tr('Trilha premium liberada! Pegue seus prêmios.'),
        },
        ResultadoCompra.pendente => tr(
          'Pagamento pendente: a trilha libera quando ele for aprovado.',
        ),
        ResultadoCompra.cancelada => null,
        _ => tr('Não deu para comprar agora. Tente de novo mais tarde.'),
      };
    });
  }

  /// This month's item that comes with the premium track, if any.
  Cosmetic? get _exclusivo => switch (PasseDoCapi.tema(DateTime.now())) {
    TemaTemporada(naCompra: final id?) => Wardrobe.byId(id),
    _ => null,
  };

  /// The season's items, with where each one comes from.
  List<_ItemDaTemporada> _itensDaTemporada(DateTime agora) {
    final tema = PasseDoCapi.tema(agora);
    if (tema == null) return const [];
    final out = <_ItemDaTemporada>[];
    if (tema.naCompra case final id?) {
      if (Wardrobe.byId(id) case final c?) {
        out.add((item: c, origem: tr('na hora, com o premium')));
      }
    }
    for (final MapEntry(key: n, value: id) in tema.premium.entries) {
      if (Wardrobe.byId(id) case final c?) {
        out.add((item: c, origem: tr('nível {n} premium', {'n': n})));
      }
    }
    for (final MapEntry(key: n, value: id) in tema.gratis.entries) {
      if (Wardrobe.byId(id) case final c?) {
        out.add((item: c, origem: tr('nível {n} grátis', {'n': n})));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final tema = PasseDoCapi.tema(agora);
    final temporada = PasseDoCapi.temporada(agora);
    final nivel = PasseDoCapi.nivel(_store, agora);
    final pontos = PasseDoCapi.pontos(_store, agora);
    final premium = PasseDoCapi.premium(_store, agora);
    final porNivel = PasseDoCapi.pontosPorNivel;
    final dentro = nivel >= PasseDoCapi.niveis ? porNivel : pontos % porNivel;
    final itens = _itensDaTemporada(agora);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.military_tech_rounded,
                    color: Palette.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        tr('Passe do Capi'),
                        style: displayText(22, color: Palette.text),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: tr('Fechar'),
                    excludeSemantics: true,
                    onTap: () => Navigator.of(context).pop(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Palette.textDim,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              // Everything else scrolls. Not a lazy list: every level is
              // built, so the screen reader (and the browser tests) can
              // find any of them.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _contagem(agora, tema, temporada),
                      const SizedBox(height: 8),
                      _progresso(nivel, dentro, porNivel),
                      if (itens.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _destaque(itens),
                      ],
                      const SizedBox(height: 8),
                      premium ? _premiumAtivo() : _premiumCta(agora),
                      if (_aviso != null) ...[
                        const SizedBox(height: 6),
                        _texto(_aviso!, bodyText(13, color: Palette.good)),
                      ],
                      const SizedBox(height: 8),
                      _cabecalhoTrilha(premium),
                      const SizedBox(height: 4),
                      for (var n = 1; n <= PasseDoCapi.niveis; n++)
                        _linha(n, nivel, premium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Text the screen reader (and the browser tests) can find.
  Widget _texto(String text, TextStyle style) => Semantics(
    container: true,
    label: text,
    excludeSemantics: true,
    child: Text(text, textAlign: TextAlign.center, style: style),
  );

  /// The season's name and how long it still runs (hours on its last day).
  Widget _contagem(DateTime agora, TemaTemporada? tema, int temporada) {
    final ultimoDia = PasseDoCapi.ultimoDia(agora);
    final String texto;
    if (ultimoDia) {
      final h = PasseDoCapi.horasRestantes(agora);
      texto = tema != null
          ? trN(
              h,
              'Temporada {tema} · termina em {n} hora',
              'Temporada {tema} · termina em {n} horas',
              {'tema': tema.nome},
            )
          : trN(
              h,
              'Temporada {t} · termina em {n} hora',
              'Temporada {t} · termina em {n} horas',
              {'t': temporada},
            );
    } else {
      final dias = PasseDoCapi.diasRestantes(agora);
      texto = tema != null
          ? trN(
              dias,
              'Temporada {tema} · termina em {n} dia',
              'Temporada {tema} · termina em {n} dias',
              {'tema': tema.nome},
            )
          : trN(
              dias,
              'Temporada {t} · termina em {n} dia',
              'Temporada {t} · termina em {n} dias',
              {'t': temporada},
            );
    }
    final cor = ultimoDia ? Palette.accentDeep : Palette.textDim;
    return Semantics(
      container: true,
      label: texto,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: cor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyText(13, color: cor),
            ),
          ),
        ],
      ),
    );
  }

  /// The level reached and the points toward the next one.
  Widget _progresso(int nivel, int dentro, int porNivel) {
    final completo = nivel >= PasseDoCapi.niveis;
    return Column(
      children: [
        _texto(
          tr('Nível {n} de {total}', {'n': nivel, 'total': PasseDoCapi.niveis}),
          displayText(16, color: Palette.accent),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: dentro / porNivel,
            minHeight: 10,
            backgroundColor: const Color(0x22FFFFFF),
            color: Palette.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          completo
              ? tr('Passe completo nesta temporada!')
              : tr(
                  'Cada estrela ganha jogando vale 1 ponto: '
                  '{feitos}/{total} para o próximo nível.',
                  {'feitos': dentro, 'total': porNivel},
                ),
          textAlign: TextAlign.center,
          style: bodyText(12, color: Palette.textDim),
        ),
      ],
    );
  }

  /// The season's items, Capi trying on the one picked (the rarest first).
  Widget _destaque(List<_ItemDaTemporada> itens) {
    final escolhido = itens.firstWhere(
      (e) => e.item.id == _provando,
      orElse: () => itens.reduce(
        (a, b) => b.item.raridade.index >= a.item.raridade.index ? b : a,
      ),
    );
    final item = escolhido.item;
    final tem = _store.unlockedHats.contains(item.id);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: item.raridade.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.raridade.color, width: 1.6),
      ),
      child: Row(
        children: [
          Capi(
            size: 68,
            mood: CapiMood.cheer,
            look: CapiLook.of(_store).wearing(item),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  container: true,
                  label: tr('{item}, {raridade}: {origem}', {
                    'item': item.label,
                    'raridade': item.raridade.label.toLowerCase(),
                    'origem': escolhido.origem,
                  }),
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: displayText(16, color: item.raridade.color),
                      ),
                      Text(
                        tem
                            ? tr('{raridade} · já é seu', {
                                'raridade': item.raridade.label,
                              })
                            : '${item.raridade.label} · ${escolhido.origem}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(12, color: Palette.textDim),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final e in itens) _miniatura(e, e.item == item),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tr('Só neste mês. Depois, é seu para sempre.'),
                  maxLines: 2,
                  style: bodyText(12, color: Palette.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One season item to try on Capi.
  Widget _miniatura(_ItemDaTemporada e, bool escolhido) {
    void provar() {
      setState(() => _provando = e.item.id);
      Analytics.event('passe_provar', {'item': e.item.id});
    }

    return Semantics(
      button: true,
      selected: escolhido,
      label: tr('Ver {item} no Capi', {'item': e.item.label}),
      excludeSemantics: true,
      onTap: provar,
      child: GestureDetector(
        onTap: provar,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: escolhido
                ? e.item.raridade.color.withValues(alpha: 0.3)
                : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: e.item.raridade.color,
              width: escolhido ? 2 : 1,
            ),
          ),
          child: CustomPaint(
            painter: CapiPainter(
              mood: CapiMood.happy,
              t: 0,
              hat: const CapiLook().wearing(e.item).hat,
              look: const CapiLook().wearing(e.item),
            ),
          ),
        ),
      ),
    );
  }

  /// What the premium track gives every day, while it is on.
  Widget _vantagens() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _vantagem(
        Icons.lightbulb_rounded,
        trN(
          PasseDoCapi.dicasExtras,
          '+{n} dica grátis em cada partida',
          '+{n} dicas grátis em cada partida',
        ),
      ),
      _vantagem(
        Icons.calendar_today_rounded,
        tr('Estrelas em dobro no Desafio diário'),
      ),
    ],
  );

  Widget _vantagem(IconData icone, String texto) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      children: [
        Icon(icone, size: 15, color: Palette.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            maxLines: 2,
            style: bodyText(12, color: Palette.text),
          ),
        ),
      ],
    ),
  );

  Widget _premiumAtivo() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Palette.accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Palette.accent.withValues(alpha: 0.6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Premium ativo nesta temporada'),
          style: displayText(13, color: Palette.accent),
        ),
        _vantagens(),
      ],
    ),
  );

  Widget _premiumCta(DateTime agora) {
    if (!_loja.disponivel) {
      return Text(
        _loja.existe
            ? tr('A loja não respondeu agora. Tente de novo daqui a pouco.')
            : tr('A trilha premium sai no app Android (Google Play).'),
        textAlign: TextAlign.center,
        style: bodyText(12, color: Palette.textDim),
      );
    }
    final preco = _loja.preco(Produto.passeCapi);
    final naHora = PasseDoCapi.naHora(_store, agora);
    final total = PasseDoCapi.totalPremium(agora);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Palette.accent.withValues(alpha: 0.18),
            Palette.accentDeep.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.accent.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // What comes the moment it is bought: the premium rewards of the
          // levels already reached and the month's item.
          _texto(
            naHora.vazio
                ? tr('Premium na temporada: {premios}.', {
                    'premios': total.texto,
                  })
                : tr('Comprando agora, você recebe na hora: {premios}.', {
                    'premios': naHora.texto,
                  }),
            displayText(13, color: Palette.accent),
          ),
          const SizedBox(height: 4),
          _vantagens(),
          const SizedBox(height: 6),
          ChunkyButton(
            label: _comprando
                ? tr('Abrindo…')
                : PasseDoCapi.precoLancamento(agora)
                ? tr('Premium · {preco} (lançamento)', {'preco': preco})
                : tr('Liberar premium · {preco}', {'preco': preco}),
            semanticLabel: tr('Liberar a trilha premium do Passe por {preco}', {
              'preco': preco,
            }),
            icon: Icons.workspace_premium_rounded,
            onTap: _comprando ? null : _comprar,
          ),
        ],
      ),
    );
  }

  Widget _cabecalhoTrilha(bool premium) => Row(
    children: [
      Expanded(
        child: Text(
          tr('Grátis'),
          textAlign: TextAlign.center,
          style: displayText(13, color: Palette.text),
        ),
      ),
      const SizedBox(width: _larguraTrilha),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!premium) ...[
              const Icon(Icons.lock_rounded, size: 13, color: Palette.accent),
              const SizedBox(width: 3),
            ],
            Text(tr('Premium'), style: displayText(13, color: Palette.accent)),
          ],
        ),
      ),
    ],
  );

  /// One level: the free reward, the track with the level (Capi stands on
  /// the one being worked toward) and the premium reward.
  Widget _linha(int n, int nivel, bool premium) {
    final alcancado = n <= nivel;
    final aqui = n == nivel + 1;
    final nivelPasse = PasseDoCapi.trilha(DateTime.now())[n - 1];
    const linhaFeita = Palette.accent;
    const linhaFalta = Color(0x33FFFFFF);
    return SizedBox(
      height: _alturaNivel,
      child: Row(
        children: [
          Expanded(
            child: _celula(n, nivelPasse.gratis, premium: false, aberta: true),
          ),
          SizedBox(
            width: _larguraTrilha,
            child: ExcludeSemantics(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The track line: above the level, then below it.
                  Positioned(
                    top: 0,
                    bottom: _alturaNivel / 2,
                    child: Container(
                      width: 4,
                      color: n == 1
                          ? Colors.transparent
                          : (alcancado ? linhaFeita : linhaFalta),
                    ),
                  ),
                  Positioned(
                    top: _alturaNivel / 2,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      color: n == PasseDoCapi.niveis
                          ? Colors.transparent
                          : (n < nivel ? linhaFeita : linhaFalta),
                    ),
                  ),
                  if (aqui)
                    const Capi(size: 50, mood: CapiMood.cheer)
                  else
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: alcancado ? Palette.accent : Palette.panel,
                        border: Border.all(
                          color: alcancado ? Palette.accent : linhaFalta,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '$n',
                        style: displayText(
                          13,
                          color: alcancado
                              ? const Color(0xFF3A2200)
                              : Palette.text,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _celula(
              n,
              nivelPasse.premium,
              premium: true,
              aberta: premium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _celula(
    int n,
    Recompensa r, {
    required bool premium,
    required bool aberta,
  }) {
    final agora = DateTime.now();
    final temporada = PasseDoCapi.temporada(agora);
    final pegou = _store.passClaimed(temporada, n, premium: premium);
    final pode = PasseDoCapi.podePegar(
      _store,
      agora,
      n,
      trilhaPremium: premium,
    );
    final item = r.item == null ? null : Wardrobe.byId(r.item!);
    final estado = pegou
        ? tr('já pego')
        : pode
        ? tr('pegar')
        : !aberta
        ? tr('bloqueado')
        : tr('nível {n}', {'n': n});
    final borda =
        item?.raridade.color ??
        (premium
            ? Palette.accent.withValues(alpha: 0.6)
            : const Color(0x33FFFFFF));
    final fundo = pode
        ? Palette.accent.withValues(alpha: 0.25)
        : premium
        ? Palette.accent.withValues(alpha: 0.08)
        : const Color(0x14FFFFFF);

    final celula = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borda, width: pode ? 2 : 1),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 34,
            child: item != null
                ? CustomPaint(
                    painter: CapiPainter(
                      mood: CapiMood.happy,
                      t: 0,
                      hat: const CapiLook().wearing(item).hat,
                      look: const CapiLook().wearing(item),
                    ),
                  )
                : Icon(
                    r.ferramenta != null
                        ? Icons.handyman_rounded
                        : Icons.star_rounded,
                    color: Palette.accent,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              r.texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bodyText(12, color: Palette.text),
            ),
          ),
          if (pegou)
            const Icon(
              Icons.check_circle_rounded,
              color: Palette.good,
              size: 18,
            )
          else if (!aberta)
            const Icon(Icons.lock_rounded, color: Palette.accent, size: 16)
          else if (pode)
            const Icon(Icons.redeem_rounded, color: Palette.accent, size: 20),
        ],
      ),
    );

    return Semantics(
      button: pode,
      label: premium
          ? tr('Nível {n} premium: {premio}, {estado}', {
              'n': n,
              'premio': r.texto,
              'estado': estado,
            })
          : tr('Nível {n} grátis: {premio}, {estado}', {
              'n': n,
              'premio': r.texto,
              'estado': estado,
            }),
      excludeSemantics: true,
      onTap: pode ? () => _pegar(n, premium: premium) : null,
      child: GestureDetector(
        onTap: pode ? () => _pegar(n, premium: premium) : null,
        child: Opacity(
          opacity: pegou ? 0.7 : (aberta ? 1 : 0.75),
          child: celula,
        ),
      ),
    );
  }
}
