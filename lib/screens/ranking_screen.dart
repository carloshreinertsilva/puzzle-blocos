import 'package:flutter/material.dart';

import '../core/hats.dart';
import '../core/nome_filtro.dart';
import '../core/ranking.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/placares.dart';
import '../services/progress_store.dart';
import '../services/ranking_servidor.dart';
import '../ui/capi.dart';
import '../ui/palette.dart';
import '../ui/premio.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// What a board shows: its best lines and where the player stands.
class _Lista {
  const _Lista(this.linhas, this.minha, this.posicao);
  final List<EntradaRanking> linhas;

  /// The player's own line, when there is a score to show.
  final EntradaRanking? minha;

  /// The player's place on the board (1 = first), or null.
  final int? posicao;
}

/// The game's own ranking, full screen: four boards (Tower, Endless, Blitz
/// and Levels), each with this week's list and the all-time one. Every line
/// shows the player's Capi, the name they chose and their score; the
/// player's own place is always at the bottom.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, required this.services});
  final AppServices services;

  static Future<void> show(BuildContext context, AppServices services) =>
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, _, _) => RankingScreen(services: services),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  Quadro _quadro = Quadro.torre;
  Periodo _periodo = Periodo.semana;
  String? _uid;

  /// What was read from the server, per board, and when: a list is asked
  /// for again only after a few minutes (each read counts on the free plan).
  final Map<String, (DateTime, Future<_Lista>)> _lidas = {};
  static const _validade = Duration(minutes: 4);

  ProgressStore get _store => widget.services.store;
  RankingServidor get _servidor => RankingServidor.atual!;

  @override
  void initState() {
    super.initState();
    _abrir();
  }

  Future<void> _abrir() async {
    await RankingSync.moderacao(_servidor);
    await RankingSync.enviar(_store);
    final uid = await _servidor.entrar();
    if (!mounted) return;
    setState(() => _uid = uid);
    if (_store.rankingNome == null) await _escolherNome();
  }

  Future<_Lista> _ler(Quadro q, Periodo p) {
    final agora = DateTime.now();
    final id = Ranking.id(q, p, agora);
    final guardada = _lidas[id];
    if (guardada != null && agora.difference(guardada.$1) < _validade) {
      return guardada.$2;
    }
    final lista = _buscar(id, q, p, agora);
    _lidas[id] = (agora, lista);
    // A failed read is not kept: the next look tries again.
    lista.catchError((Object _) {
      _lidas.remove(id);
      return const _Lista([], null, null);
    });
    return lista;
  }

  Future<_Lista> _buscar(String id, Quadro q, Periodo p, DateTime agora) async {
    final uid = _uid ?? await _servidor.entrar();
    if (uid == null) throw StateError('sem conexão');
    final escondidos = {...RankingSync.ocultos, ..._store.rankingDenunciados};
    final linhas = [
      for (final e in await _servidor.topo(id, Ranking.topo + 5))
        if (!escondidos.contains(e.uid)) e,
    ].take(Ranking.topo).toList();
    final minha = Ranking.minha(_store, uid, q, p, agora);
    int? posicao;
    if (minha != null) {
      final i = linhas.indexWhere((e) => e.uid == uid);
      posicao = i >= 0 ? i + 1 : await _servidor.acima(id, minha.pontos) + 1;
    }
    return _Lista(linhas, minha, posicao);
  }

  void _recarregar() => setState(_lidas.clear);

  Future<void> _escolherNome() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => _NomeDialog(atual: _store.rankingNome),
    );
    if (nome == null || !mounted) return;
    await _store.setRankingNome(nome);
    Analytics.event('ranking_nome');
    await RankingSync.enviar(_store);
    if (mounted) _recarregar();
  }

  Future<void> _denunciar(EntradaRanking e) async {
    final sim = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CardPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedTitle(tr('Denunciar nome'), size: 22),
              const SizedBox(height: 8),
              Text(
                tr(
                  'O nome "{nome}" é ofensivo? Ele some da sua lista e vai '
                  'para a nossa moderação.',
                  {'nome': e.nome},
                ),
                textAlign: TextAlign.center,
                style: bodyText(15),
              ),
              const SizedBox(height: 16),
              ChunkyButton(
                label: tr('Denunciar'),
                icon: Icons.flag_rounded,
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              ChunkyButton(
                label: tr('Cancelar'),
                color: Palette.panelEdge,
                textColor: Colors.white,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (sim != true || !mounted) return;
    final id = Ranking.id(_quadro, _periodo, DateTime.now());
    await _store.addRankingDenunciado(e.uid);
    try {
      await _servidor.denunciar(id, e, _uid ?? '');
    } catch (_) {
      // Hidden on this phone all the same.
    }
    Analytics.event('ranking_denuncia');
    if (!mounted) return;
    mostrarPremio(
      context,
      tr('Obrigado! Vamos olhar esse nome.'),
      icon: Icons.flag_rounded,
    );
    _recarregar();
  }

  // --- Screen ---

  @override
  Widget build(BuildContext context) {
    final lista = _ler(_quadro, _periodo);
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
                  _quadros(),
                  const SizedBox(height: 8),
                  _periodos(),
                  const SizedBox(height: 6),
                  Expanded(
                    child: FutureBuilder<_Lista>(
                      key: ValueKey((_quadro, _periodo, lista)),
                      future: lista,
                      builder: (context, snap) {
                        if (snap.hasError) return _semConexao();
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Palette.accent,
                            ),
                          );
                        }
                        return _linhas(snap.data!);
                      },
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

  Widget _topo() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: OutlinedTitle(tr('Ranking'), size: 26),
              ),
            ),
          ),
        ),
        RoundIconButton(
          icon: Icons.edit_rounded,
          label: tr('Mudar meu nome no ranking'),
          onTap: _escolherNome,
        ),
      ],
    ),
  );

  static const _icones = {
    Quadro.torre: Icons.layers_rounded,
    Quadro.infinito: Icons.all_inclusive_rounded,
    Quadro.blitz: Icons.bolt_rounded,
    Quadro.fases: Icons.flag_rounded,
  };

  Widget _quadros() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        for (final q in Quadro.values)
          Expanded(
            child: _Aba(
              icon: _icones[q]!,
              nome: tr(q.nome),
              selecionada: q == _quadro,
              onTap: () {
                widget.services.feedback.click();
                setState(() => _quadro = q);
              },
            ),
          ),
      ],
    ),
  );

  Widget _periodos() {
    final falta = Ranking.fimDaSemana(DateTime.now())
        .difference(DateTime.now().toUtc());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          for (final (p, nome) in [
            (Periodo.semana, tr('Esta semana')),
            (Periodo.geral, tr('Sempre')),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Semantics(
                button: true,
                selected: p == _periodo,
                label: nome,
                excludeSemantics: true,
                onTap: () => setState(() => _periodo = p),
                child: GestureDetector(
                  onTap: () {
                    widget.services.feedback.click();
                    setState(() => _periodo = p);
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: p == _periodo
                          ? Palette.accent
                          : const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      nome,
                      style: displayText(
                        14,
                        color: p == _periodo
                            ? const Color(0xFF3A2200)
                            : Palette.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (_periodo == Periodo.semana)
            Flexible(
              child: Text(
                tr('Recomeça em {d} d {h} h', {
                  'd': falta.inDays,
                  'h': falta.inHours % 24,
                }),
                textAlign: TextAlign.end,
                style: bodyText(12, color: Palette.textDim),
              ),
            ),
        ],
      ),
    );
  }

  Widget _semConexao() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Capi(size: 96, mood: CapiMood.worried),
          const SizedBox(height: 8),
          Text(
            tr('Não deu para abrir o ranking. Confira a internet.'),
            textAlign: TextAlign.center,
            style: bodyText(15),
          ),
          const SizedBox(height: 12),
          ChunkyButton(
            label: tr('Tentar de novo'),
            icon: Icons.refresh_rounded,
            onTap: _recarregar,
          ),
        ],
      ),
    ),
  );

  Widget _linhas(_Lista l) {
    final uid = _uid;
    return Column(
      children: [
        Expanded(
          child: l.linhas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Capi(size: 96, mood: CapiMood.point),
                        const SizedBox(height: 8),
                        Text(
                          tr('Ninguém por aqui ainda. Seja o primeiro!'),
                          textAlign: TextAlign.center,
                          style: bodyText(15),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  itemCount: l.linhas.length + (Placares.ativo ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == l.linhas.length) return _lojas();
                    final e = l.linhas[i];
                    return _Linha(
                      posicao: i + 1,
                      entrada: e,
                      unidade: _quadro.unidade,
                      minha: e.uid == uid,
                      onDenunciar: e.uid == uid ? null : () => _denunciar(e),
                    );
                  },
                ),
        ),
        _rodape(l),
      ],
    );
  }

  /// The stores' own boards (Play Games, Game Center) are still there.
  Widget _lojas() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: TextButton.icon(
      onPressed: () => Placares.mostrar(_store),
      icon: const Icon(Icons.open_in_new_rounded, size: 16),
      label: Text(
        tr('Ver os placares do {servico}', {'servico': Placares.nome}),
        style: bodyText(13, color: Palette.textDim),
      ),
    ),
  );

  /// Where the player stands, always in sight.
  Widget _rodape(_Lista l) {
    final nome = _store.rankingNome;
    final Widget conteudo;
    if (nome == null) {
      conteudo = ChunkyButton(
        label: tr('Escolher meu nome'),
        semanticLabel: tr('Escolher meu nome para entrar no ranking'),
        icon: Icons.edit_rounded,
        onTap: _escolherNome,
      );
    } else if (l.minha == null) {
      conteudo = Text(
        _periodo == Periodo.semana
            ? tr('Jogue esta semana para entrar na lista!')
            : tr('Jogue para entrar na lista!'),
        textAlign: TextAlign.center,
        style: bodyText(15),
      );
    } else {
      conteudo = _Linha(
        posicao: l.posicao ?? 0,
        entrada: l.minha!,
        unidade: _quadro.unidade,
        minha: true,
        rotulo: tr('Você'),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0x33000000),
        border: Border(top: BorderSide(color: Palette.panelEdge, width: 2)),
      ),
      child: conteudo,
    );
  }
}

/// One board's button, at the top.
class _Aba extends StatelessWidget {
  const _Aba({
    required this.icon,
    required this.nome,
    required this.selecionada,
    required this.onTap,
  });
  final IconData icon;
  final String nome;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selecionada,
    label: tr('Ranking: {quadro}', {'quadro': nome}),
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selecionada
              ? const Color(0x33FFC94D)
              : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionada ? Palette.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selecionada ? Palette.accent : Palette.text,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                nome,
                maxLines: 1,
                style: displayText(
                  12,
                  color: selecionada ? Palette.accent : Palette.text,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A player on the list: place, Capi, name and score.
class _Linha extends StatelessWidget {
  const _Linha({
    required this.posicao,
    required this.entrada,
    required this.unidade,
    this.minha = false,
    this.rotulo,
    this.onDenunciar,
  });
  final int posicao;
  final EntradaRanking entrada;
  final String unidade;
  final bool minha;

  /// Shown in place of the name ("You", on the bottom bar).
  final String? rotulo;
  final VoidCallback? onDenunciar;

  static const _medalhas = [
    Color(0xFFFFD43B),
    Color(0xFFCED4DA),
    Color(0xFFE8A86B),
  ];

  @override
  Widget build(BuildContext context) {
    final e = entrada;
    final pontos = formatInt(e.pontos);
    final medalha = posicao >= 1 && posicao <= 3
        ? _medalhas[posicao - 1]
        : null;
    return Semantics(
      container: true,
      // The report button is read by itself, not as part of the line.
      explicitChildNodes: true,
      label: tr('{posicao}º lugar: {nome}, {pontos} {unidade}', {
        'posicao': posicao,
        'nome': rotulo ?? e.nome,
        'pontos': pontos,
        'unidade': tr(unidade),
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        decoration: BoxDecoration(
          color: minha ? const Color(0x33FFC94D) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: minha ? Palette.accent : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: medalha ?? const Color(0x22FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      posicao > 0 ? '$posicao' : '-',
                      style: displayText(
                        15,
                        color: medalha == null
                            ? Palette.text
                            : const Color(0xFF3A2200),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 44,
                child: CustomPaint(
                  painter: CapiPainter(
                    mood: posicao == 1 ? CapiMood.cheer : CapiMood.happy,
                    t: 0,
                    hat: CapiHat.fromId(e.chapeu),
                    look: CapiLook(
                      hat: CapiHat.fromId(e.chapeu),
                      pelagem: e.pelagem,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rotulo ?? e.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: displayText(16, color: Palette.text),
                    ),
                    if (e.embaixador)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.volunteer_activism_rounded,
                            size: 13,
                            color: Color(0xFFFF8FAB),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            tr('Embaixador'),
                            style: bodyText(11, color: const Color(0xFFFF8FAB)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(pontos, style: displayText(17, color: Palette.accent)),
                  Text(
                    tr(unidade),
                    style: bodyText(10, color: Palette.textDim),
                  ),
                ],
              ),
            ),
            if (onDenunciar != null)
              Semantics(
                button: true,
                label: tr('Denunciar o nome {nome}', {'nome': e.nome}),
                excludeSemantics: true,
                onTap: onDenunciar,
                child: IconButton(
                  onPressed: onDenunciar,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: Palette.textDim,
                  ),
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Asks for the name shown on the ranking. Returns it, or null.
class _NomeDialog extends StatefulWidget {
  const _NomeDialog({this.atual});
  final String? atual;

  @override
  State<_NomeDialog> createState() => _NomeDialogState();
}

class _NomeDialogState extends State<_NomeDialog> {
  late final _campo = TextEditingController(text: widget.atual ?? '');
  String? _erro;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salvar() {
    final recusa = NomeFiltro.recusar(_campo.text);
    if (recusa == null) {
      Navigator.pop(context, NomeFiltro.limpar(_campo.text));
      return;
    }
    setState(() {
      _erro = switch (recusa) {
        NomeRecusado.curto => tr('O nome precisa de pelo menos 3 letras.'),
        NomeRecusado.longo => tr('O nome pode ter até 16 letras.'),
        NomeRecusado.caracteres => tr(
          'Use só letras, números, espaço, ponto, traço ou _.',
        ),
        NomeRecusado.improprio => tr(
          'Esse nome não pode. Escolha outro, por favor.',
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    child: SingleChildScrollView(
      child: CardPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedTitle(tr('Seu nome no ranking'), size: 22),
            const SizedBox(height: 8),
            Text(
              tr(
                'Todo mundo vê esse nome nas listas. Pode ser um apelido: '
                'não use nome completo nem dados pessoais.',
              ),
              textAlign: TextAlign.center,
              style: bodyText(14, color: Palette.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _campo,
              autofocus: true,
              maxLength: NomeFiltro.maximo,
              textCapitalization: TextCapitalization.words,
              style: displayText(18, color: Palette.text),
              decoration: InputDecoration(
                counterText: '',
                labelText: tr('Nome no ranking'),
                labelStyle: bodyText(13, color: Palette.textDim),
                filled: true,
                fillColor: const Color(0x22FFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _salvar(),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: bodyText(13, color: const Color(0xFFFF8A8A)),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ChunkyButton(
              label: tr('Salvar'),
              semanticLabel: tr('Salvar meu nome no ranking'),
              icon: Icons.check_rounded,
              onTap: _salvar,
            ),
            const SizedBox(height: 8),
            ChunkyButton(
              label: tr('Agora não'),
              color: Palette.panelEdge,
              textColor: Colors.white,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
