import 'dart:math';
import 'dart:async';

import '../core/cartao_convite.dart';
import '../core/convites.dart';
import '../core/descoberta.dart';
import '../core/dica_do_dia.dart';
import '../core/duelos.dart';
import '../core/fila_abertura.dart';
import '../core/menu_estado.dart';
import '../core/hats.dart';
import '../core/novidades.dart';
import '../core/ofertas.dart';
import '../core/passe.dart';
import '../core/presente_diario.dart';
import '../core/wardrobe.dart';
import '../core/daily_missions.dart';
import 'daily_missions_dialog.dart';
import 'wardrobe_screen.dart';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../core/missions.dart';
import '../core/village.dart';
import '../game/onboarding.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/avaliacao.dart';
import '../services/avisos.dart';
import '../services/convites_servidor.dart';
import '../services/duelos_servidor.dart';
import '../services/jogo_salvo.dart';
import '../services/musica.dart';
import '../services/placares.dart';
import '../services/ranking_resumo.dart';
import '../services/ranking_servidor.dart';
import '../services/progress_store.dart';
import '../testing/test_bridge.dart';
import '../ui/capi.dart';
import '../ui/menu_widgets.dart';
import '../ui/nome_dialog.dart';
import '../ui/oferta_nuvem.dart';
import '../ui/palette.dart';
import '../ui/placar_duelos.dart';
import '../core/level.dart';
import '../ui/premio.dart';
import '../ui/regras_duelo.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';
import '../shop/produtos.dart';
import 'game_screen.dart';
import 'cartao_convite_dialog.dart';
import 'convites_sheet.dart';
import 'loja_sheet.dart';
import 'novidades_dialog.dart';
import 'passe_sheet.dart';
import 'ranking_screen.dart';
import 'presente_dialog.dart';
import 'obra_screen.dart';
import 'settings_sheet.dart';
import 'stats_sheet.dart';
import 'village_screen.dart';
import 'tower_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// What Capi says over the menu (news first, then any hint), if anything.
  late List<MenuNews> _news = Onboarding.pendingNews(widget.services.store);
  String? _hint;

  String? get _capiLine => _news.isNotEmpty ? _news.first.text : _hint;

  // The shop button shows once the store answers (and the starter pack
  // badge as soon as it is on offer).
  Timer? _abertura;

  @override
  void initState() {
    super.initState();
    widget.services.loja.addListener(_lojaMudou);
    widget.services.feedback.musica.tocar(Trilha.menu);
    _talvezSugerir();
    // Records not on the boards yet go now (a player from before the
    // name was asked for, or a send that failed), then the menu's place.
    unawaited(
      RankingSync.enviar(widget.services.store).whenComplete(_lerPosicao),
    );
    // Let the menu show first, then the gift (and any update) over it.
    _abertura = Timer(const Duration(milliseconds: 600), _abrirFila);
    if (Avaliacao.noCelular) {
      _telaTimer = Timer.periodic(Avaliacao.passo, (_) => _contarTela());
    }
  }

  Timer? _telaTimer;

  /// Adds up the time with the game on the screen (this menu stays alive
  /// under the matches) and, with the player here on the menu and nothing
  /// over it, maybe asks for a rating in the store.
  Future<void> _contarTela() async {
    final viva =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!viva) return;
    final store = widget.services.store;
    await store.addTempoDeTela(Avaliacao.passo);
    if (!mounted || _filaRodando) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    await Avaliacao.talvezPedirNoMenu(store);
  }

  /// Whether the windows of the opening are still on their way.
  bool _filaRodando = false;

  /// What opens by itself with the menu, most important first and at most
  /// [FilaAbertura.limitePadrao] windows (see core/fila_abertura.dart); the
  /// others keep their conditions and come next time. The syncs behind
  /// them (invites, duels, cloud save) run every time.
  Future<void> _abrirFila() async {
    _filaRodando = true;
    final fila = FilaAbertura();
    Future<void> passo(
      DialogoAbertura d,
      Future<bool> Function(bool cabe) abrir,
    ) async {
      if (!mounted) return;
      // Not over another screen (a match started before the windows came).
      final aqui = ModalRoute.of(context)?.isCurrent != false;
      if (await abrir(fila.cabe(d) && (aqui || d.obrigatorio))) {
        fila.mostrou(d);
      }
    }

    try {
      await passo(DialogoAbertura.conviteRecebido, _conviteNaAbertura);
      await passo(DialogoAbertura.nomeRanking, (_) => _garantirNome());
      await passo(DialogoAbertura.presente, _presenteDoDia);
      await passo(DialogoAbertura.novidades, _novidadesDaVersao);
      await passo(DialogoAbertura.nuvem, _progressoDaNuvem);
      await passo(DialogoAbertura.resultadosDuelo, _resultadosDuelo);
      await passo(DialogoAbertura.bonusFundador, _bonusFundador);
      await passo(DialogoAbertura.ofertaBoasVindas, _ofertaBoasVindas);
      await passo(DialogoAbertura.atualizacao, (_) async {
        await Avisos.verificarAtualizacao(context, widget.services.store);
        return false;
      });
      await passo(DialogoAbertura.playGames, _convidarPlayGames);
    } finally {
      _filaRodando = false;
    }
    if (!mounted) return;
    if (fila.mostrados > 0) {
      Analytics.event('menu_abertura', {'dialogos': fila.mostrados});
    } else {
      // A quiet opening: room for Capi's tip of the day.
      _talvezDica();
    }
  }

  /// Whether the player still has to choose the ranking's name.
  bool get _precisaNome {
    final store = widget.services.store;
    if (RankingServidor.atual == null || store.rankingNome != null) {
      return false;
    }
    // Browser tests keep the menu clear, except the one about the name.
    return !kTestBridge || store.hasSeen('testar_nome');
  }

  /// The name being asked for, so it is never asked twice at once.
  Future<bool>? _pedindoNome;

  /// Asks for the ranking's name (mandatory) while there is none: when the
  /// menu opens and before any match. True when the window opened.
  Future<bool> _garantirNome() {
    if (!mounted || !_precisaNome) return Future.value(false);
    return _pedindoNome ??= _pedirNome().whenComplete(
      () => _pedindoNome = null,
    );
  }

  Future<bool> _pedirNome() async {
    final store = widget.services.store;
    Analytics.event('ranking_nome_pergunta');
    final nome = await pedirNomeObrigatorio(context);
    if (nome == null) return true;
    await store.setRankingNome(nome);
    Analytics.event('ranking_nome', {'origem': 'menu'});
    unawaited(RankingSync.enviar(store).whenComplete(_lerPosicao));
    if (mounted) setState(() {});
    return true;
  }

  /// Whether a match may start now: with the ranking's name chosen.
  Future<bool> _podeJogar() async {
    await _garantirNome();
    return mounted && !_precisaNome;
  }

  /// A cloud save ahead of this phone's (the check also sends this phone's
  /// progress when there is none).
  Future<bool> _progressoDaNuvem(bool cabe) async {
    final store = widget.services.store;
    final nuvem = await JogoSalvo.verificar(store);
    if (!cabe || nuvem == null || !mounted) return false;
    await oferecerProgressoDaNuvem(context, store, nuvem);
    return true;
  }

  /// Friends who played the player's challenges since the last time: who
  /// beat whom, and the score with each of them. Without room for the
  /// window ([cabe]), they wait on the Modos card and the Duel card.
  Future<bool> _resultadosDuelo([bool cabe = true]) async {
    final store = widget.services.store;
    final novos = await DuelosSync.buscar(store);
    if (!mounted) return false;
    if (novos.isEmpty || !cabe) {
      setState(() {});
      return false;
    }
    await _mostrarResultados(novos);
    return true;
  }

  Future<void> _mostrarResultados(List<ResultadoDuelo> novos) async {
    final store = widget.services.store;
    await Duelos.marcarVistos(store);
    Analytics.event('duelo_resultado', {'n': novos.length});
    if (!mounted) return;
    final revanche = await mostrarResultadosDuelo(context, store, novos);
    if (mounted) setState(() {});
    if (revanche != null && mounted) await _jogarRevanche(revanche);
  }

  /// The player's challenge, which this friend beat, played again on the
  /// same board; beating the friend's score sends it back to them.
  Future<void> _jogarRevanche(ResultadoDuelo r) async {
    final duelo = await DuelosSync.ler(r.duelo);
    if (!mounted) return;
    final seed = duelo?.semente;
    Analytics.event('duel_rematch', {'ok': seed != null ? 1 : 0});
    if (seed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Não deu para abrir esse duelo agora. Tente de novo mais tarde.',
            ),
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          services: widget.services,
          mode: duelo!.blitz ? GameMode.blitz : GameMode.duel,
          duelSeed: seed,
          duelTargetScore: r.ele,
          duelRivalName: r.nome,
          revanche: r,
        ),
      ),
    );
  }

  /// The starter pack grew: players who bought it before get the
  /// difference once, and are told so: only with room to tell it ([cabe]),
  /// otherwise next time.
  Future<bool> _bonusFundador(bool cabe) async {
    final store = widget.services.store;
    if (!cabe || !mounted || !await Entrega.bonusFundador(store)) return false;
    Analytics.event('oferta', {'tipo': 'bonus_fundador'});
    if (!mounted) return false;
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: Text(
          tr('Presente para os Fundadores!'),
          style: displayText(22),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Capi(size: 96, hat: CapiHat.vip, mood: CapiMood.cheer),
            const SizedBox(height: 10),
            Text(
              tr(
                'O Pacote Inicial ficou maior, e quem já tinha comprado '
                'ganha a diferença: +{n} estrelas, a Cartola VIP e um kit '
                'de ferramentas. Obrigado por apoiar o CapiBlocks!',
                {'n': PacoteInicial.estrelas - 300},
              ),
              textAlign: TextAlign.center,
              style: bodyText(15),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ChunkyButton(
            label: tr('Legal!'),
            icon: Icons.favorite_rounded,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
    return true;
  }

  /// Once, for players who never bought anything and are into the game:
  /// a cheap first purchase, told on the menu and then kept in the shop
  /// for [OfertaBoasVindas.duracao].
  Future<bool> _ofertaBoasVindas(bool cabe) async {
    final store = widget.services.store;
    final agora = DateTime.now();
    if (!cabe || !mounted || !widget.services.loja.disponivel) return false;
    // Browser tests keep the menu clear, except the one about the offer.
    if (kTestBridge && !store.hasSeen('testar_oferta')) return false;
    if (!OfertaBoasVindas.podeComecar(
      store,
      agora,
      pacoteInicialNoAr: Entrega.mostraPacoteInicial(store, agora),
    )) {
      return false;
    }
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    await store.comecarOfertaBoasVindas(agora);
    Analytics.event('oferta', {'tipo': 'boas_vindas'});
    if (!mounted) return false;
    setState(() {});
    final preco = widget.services.loja.preco(Produto.ofertaBoasVindas);
    final ver = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: Text(
          tr('Um presente de boas-vindas!'),
          style: displayText(22),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Capi(size: 96, mood: CapiMood.cheer),
            const SizedBox(height: 10),
            Text(
              tr(
                '{n} estrelas + 1 martelo, 1 pá e 1 troca de peças por só '
                '{preco}. Oferta única, por 48 horas.',
                {'n': OfertaBoasVindas.estrelas, 'preco': preco},
              ),
              textAlign: TextAlign.center,
              style: bodyText(15),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              tr('Agora não'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
          ChunkyButton(
            label: tr('Ver oferta'),
            icon: Icons.card_giftcard_rounded,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ver == true && mounted) await _openLoja();
    return true;
  }

  /// A friend's invite from the Play Store (first run on Android), then the
  /// server's count of this player's friends and any reward reached.
  /// The invite is read (once) only with room to show it ([cabe]).
  Future<bool> _conviteNaAbertura(bool cabe) async {
    final store = widget.services.store;
    var mostrou = false;
    if (cabe) {
      final codigo = await ConvitesServidor.codigoDaInstalacao(store);
      if (codigo != null &&
          mounted &&
          store.conviteUsado == null &&
          codigo != store.conviteCodigo) {
        await mostrarConviteRecebido(context, widget.services, codigo);
        mostrou = true;
      }
    }
    // In the background: its prizes are toasts, and the gift shouldn't
    // wait for the server.
    unawaited(_sincronizarConvites());
    return mostrou;
  }

  Future<void> _sincronizarConvites() async {
    final novas = await ConvitesServidor.sincronizar(widget.services.store);
    if (!mounted) return;
    for (final m in novas) {
      mostrarPremio(
        context,
        tr('Amigos no CapiBlocks! Você ganhou: {premio}', {'premio': m.texto}),
      );
    }
    if (novas.isNotEmpty) setState(() {});
  }

  /// After the first levels, twice at most: sign in to Play Games to be on
  /// the leaderboards.
  Future<bool> _convidarPlayGames(bool cabe) async {
    final store = widget.services.store;
    final hoje = ProgressStore.dayKey(DateTime.now());
    if (!cabe || !mounted || !await Placares.deveConvidar(store, hoje)) {
      return false;
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
    await store.marcarConvitePlayGames(hoje);
    if (!mounted) return false;
    final entrar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.leaderboard_rounded,
              color: Palette.accent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('Salve seu progresso'),
                style: displayText(22, color: Palette.text),
              ),
            ),
          ],
        ),
        content: Text(
          tr(
            'Entre no Google Play Games para salvar seu progresso na nuvem '
            'e aparecer nos placares com seus amigos.',
          ),
          style: bodyText(15, color: Palette.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              tr('Agora não'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
          ChunkyButton(
            label: tr('Entrar'),
            icon: Icons.login_rounded,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (entrar != true) return true;
    Analytics.event('play_games_convite', {'aceitou': 1});
    if (!await Placares.entrar(store)) return true;
    final nuvem = await JogoSalvo.verificarDeNovo(store);
    if (!mounted) return true;
    // The player asked for it: the cloud save may follow.
    await oferecerProgressoDaNuvem(context, store, nuvem);
    return true;
  }

  /// Once a day, after the first levels, the daily gift opens by itself.
  Future<bool> _presenteDoDia(bool cabe) async {
    final store = widget.services.store;
    final agora = DateTime.now();
    final hoje = ProgressStore.dayKey(agora);
    // Not over Capi's first words on the menu: the gift waits for them.
    if (!cabe ||
        !mounted ||
        _news.isNotEmpty ||
        !store.hasSeen('menu') ||
        !PresenteDiario.disponivel(store, agora) ||
        store.giftShownDay == hoje) {
      return false;
    }
    await store.setGiftShown(hoje);
    if (!mounted) return false;
    await showPresente(context, widget.services);
    if (mounted) setState(() {});
    return true;
  }

  /// The first time the game opens after an update: what is new, each
  /// with a button that goes straight to it. Whatever is not opened keeps
  /// a dot on the menu.
  /// Without room ([cabe]) they wait, untold, for the next opening.
  Future<bool> _novidadesDaVersao(bool cabe) async {
    final store = widget.services.store;
    if (!mounted || _news.isNotEmpty || !store.hasSeen('menu')) return false;
    final vistas = store.novidadesVistas;
    if (vistas >= Novidades.atual) return false;
    // Someone who just arrived has nothing "new" to be told.
    final primeira = store.firstOpenAt;
    final novato =
        vistas < 0 &&
        (primeira == null ||
            DateTime.now().difference(primeira) < const Duration(days: 1));
    if (!novato && !cabe) return false;
    await store.setNovidadesVistas(Novidades.atual);
    if (novato) return false;
    final lista = Novidades.pendentes(vistas);
    if (lista.isEmpty) return false;
    await store.setNovidadesPendentes(
      {
        ...store.novidadesPendentes,
        for (final n in lista) n.destino.name,
      }.toList(),
    );
    if (!mounted) return false;
    setState(() {});
    Analytics.event('novidades', {'edicao': Novidades.atual});
    final destino = await mostrarNovidades(context, lista);
    if (destino == null || !mounted) return true;
    Analytics.event('novidade_aberta', {'destino': destino.name});
    await _irPara(destino);
    return true;
  }

  Future<void> _irPara(DestinoNovidade destino) => switch (destino) {
    DestinoNovidade.ranking => _openRanking(),
    DestinoNovidade.torre => _openTower(),
    DestinoNovidade.missoes => _openDailyMissions(),
    DestinoNovidade.guardaRoupa => _openWardrobe(),
    DestinoNovidade.passe => _openPasse(),
    DestinoNovidade.loja => _openLoja(),
    DestinoNovidade.blitz => _openBlitz(),
    DestinoNovidade.duelo => _openDuelo(),
    DestinoNovidade.convites => _openConvites(),
    DestinoNovidade.configuracoes => showSettings(context, widget.services),
  };

  /// Whether [destino] has news the player has not opened yet.
  bool _pendente(DestinoNovidade destino) =>
      widget.services.store.novidadesPendentes.contains(destino.name);

  /// The player went to [destino]: its dot goes away.
  void _abriu(DestinoNovidade destino) {
    final store = widget.services.store;
    if (!_pendente(destino)) return;
    unawaited(
      store.setNovidadesPendentes([
        for (final d in store.novidadesPendentes)
          if (d != destino.name) d,
      ]),
    );
  }

  /// The player's best place on this week's boards, for the Ranking card.
  PosicaoRanking? _posicao;

  Future<void> _lerPosicao() async {
    final p = await RankingResumo.melhor(widget.services.store);
    if (mounted) setState(() => _posicao = p);
  }

  String _rankingSubtitulo(ProgressStore store) {
    final p = _posicao;
    if (p != null) return tr('{n}º na semana', {'n': p.posicao});
    if (RankingServidor.atual != null && store.rankingNome == null) {
      return tr('Entre na disputa!');
    }
    return store.bestScore > 0
        ? tr('Recorde {n}', {'n': formatInt(store.bestScore)})
        : tr('Placares');
  }

  @override
  void dispose() {
    widget.services.loja.removeListener(_lojaMudou);
    _abertura?.cancel();
    _telaTimer?.cancel();
    _sugestaoTimer?.cancel();
    _dicaTimer?.cancel();
    super.dispose();
  }

  void _lojaMudou() {
    if (mounted) setState(() {});
  }

  Future<void> _openLoja() async {
    _abriu(DestinoNovidade.loja);
    final store = widget.services.store;
    // Today's offers are seen: the button's mark goes away.
    unawaited(store.markSeen(TemaDica.loja.aberto));
    unawaited(store.setLojaVistaDia(ProgressStore.dayKey(DateTime.now())));
    setState(() {});
    await showLoja(context, widget.services);
    if (mounted) setState(() {});
  }

  int _waiting(ProgressStore store, DateTime today) =>
      DailyMissionsManager.unclaimedCount(store, today) +
      PasseDoCapi.prontas(store, today) +
      (PresenteDiario.disponivel(store, today) ? 1 : 0);

  void _dismissCapi() {
    widget.services.feedback.click();
    setState(() {
      if (_news.isNotEmpty) {
        widget.services.store.markSeen(_news.removeAt(0).key);
      } else {
        _hint = null;
      }
    });
  }

  static const _tips = [
    'Dica: guarde espaço para as peças grandes, como o quadradão 3x3.',
    'Limpar duas linhas de uma vez vale muito mais pontos!',
    'Limpando linhas em seguida você faz combo e multiplica os pontos.',
    'Gemas só contam quando a linha ou a coluna delas some.',
    'Ficou parado? Eu dou uma dica de onde encaixar a peça.',
  ];
  int _tipIndex = 0;

  void _tip() {
    widget.services.feedback.click();
    setState(() => _hint = tr(_tips[_tipIndex++ % _tips.length]));
  }

  Future<void> _openWardrobe() async {
    Analytics.event('screen_open', {'screen': 'wardrobe'});
    widget.services.feedback.click();
    _abriu(DestinoNovidade.guardaRoupa);
    unawaited(widget.services.store.markSeen(TemaDica.guardaRoupa.aberto));
    await WardrobeScreen.show(context, widget.services);
    if (mounted) setState(() {});
  }

  Future<void> _openDailyMissions() async {
    Analytics.event('screen_open', {'screen': 'missions'});
    widget.services.feedback.click();
    _abriu(DestinoNovidade.missoes);
    unawaited(widget.services.store.markSeen(TemaDica.missoes.aberto));
    await DailyMissionsDialog.show(context, widget.services);
    if (mounted) setState(() {});
  }

  void _locked(String mode, int level) {
    _sairDaFolha();
    widget.services.feedback.click();
    setState(
      () => _hint = tr('Chegue na fase {n} que eu libero o {modo} pra você!', {
        'n': level,
        'modo': tr(mode),
      }),
    );
  }

  Future<void> _openVillage() async {
    Analytics.event('screen_open', {'screen': 'village'});
    widget.services.feedback.click();
    unawaited(widget.services.store.markSeen(TemaDica.vila.aberto));
    final play = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => VillageScreen(services: widget.services),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (!mounted) return;
    setState(() {});
    // "Jogar" in the village: straight into the current level.
    if (play == true) await _open(GameMode.levels);
  }

  Future<void> _open(
    GameMode mode, {
    int? replayLevel,
    int? duelSeed,
    int? duelTargetScore,
    String? duelRivalName,
  }) async {
    if (!await _podeJogar() || !mounted) return;
    _sairDaFolha();
    widget.services.feedback.click();
    if (mode == GameMode.endless) {
      widget.services.store.markSeen('opened_endless');
    }
    if (mode == GameMode.daily) {
      widget.services.store.markSeen(TemaDica.desafioDiario.aberto);
    }
    // Whether the match ends well (a level won, a new record): the moment
    // for the invite card.
    final antes = MarcaPartida.of(widget.services.store);
    final atalho = await Navigator.of(context).push<Atalho>(
      PageRouteBuilder<Atalho>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => GameScreen(
          services: widget.services,
          mode: mode,
          replayLevel: replayLevel,
          duelSeed: duelSeed,
          duelTargetScore: duelTargetScore,
          duelRivalName: duelRivalName,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    // Level, record and streak may have changed, and modes may unlock.
    unawaited(Placares.enviar(widget.services.store));
    unawaited(RankingSync.enviar(widget.services.store));
    unawaited(JogoSalvo.salvar(widget.services.store));
    // A friend's invite counts once this player reaches level 5.
    final store = widget.services.store;
    if (store.conviteUsado != null &&
        store.conviteEnviado < 2 &&
        store.level >= Convites.faseQueConta) {
      unawaited(_sincronizarConvites());
    }
    if (!mounted) return;
    // A mode chosen on the end-of-level card: Capi has nothing left to
    // announce about it on the menu.
    final falada = _noticiaDoAtalho(atalho);
    if (falada != null) await store.markSeen(falada.key);
    if (!mounted) return;
    setState(() => _news = Onboarding.pendingNews(widget.services.store));
    unawaited(_lerPosicao());
    // A friend may have answered a challenge in the meantime.
    if (mode == GameMode.duel || mode == GameMode.blitz) {
      unawaited(_resultadosDuelo());
    } else if (atalho == null) {
      // Back on the menu, one thing at most: the store's rating window,
      // or else Capi's invite card (after a good match), or else his tip
      // of the day.
      final pediu = await Avaliacao.talvezPedirNoMenu(store);
      if (!mounted) return;
      if (!pediu &&
          !await _talvezCartaoConvite(CartaoConvite.momentoBom(antes, store))) {
        if (mounted) _talvezDica();
      }
    }
    if (atalho != null) await _irParaAtalho(atalho);
  }

  static MenuNews? _noticiaDoAtalho(Atalho? a) => switch (a) {
    Atalho.infinito => MenuNews.endless,
    Atalho.obras => MenuNews.obras,
    Atalho.desafioDiario => MenuNews.daily,
    Atalho.blitz => MenuNews.blitz,
    Atalho.duelo => MenuNews.duel,
    Atalho.torre => MenuNews.tower,
    _ => null,
  };

  /// Where a shortcut on the end-of-level card leads.
  Future<void> _irParaAtalho(Atalho a) => switch (a) {
    Atalho.infinito => _open(GameMode.endless),
    Atalho.obras => _openObras(),
    Atalho.desafioDiario => _open(GameMode.daily),
    Atalho.blitz => _openBlitz(),
    Atalho.duelo => _openDuelo(),
    Atalho.torre => _openTower(),
    Atalho.passe => _openPasse(),
    Atalho.loja => _openLoja(),
  };

  Future<void> _openTower() async {
    if (!await _podeJogar() || !mounted) return;
    _sairDaFolha();
    Analytics.event('screen_open', {'screen': 'tower'});
    widget.services.feedback.click();
    widget.services.store.markSeen('opened_tower');
    _abriu(DestinoNovidade.torre);
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => TowerScreen(services: widget.services),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    unawaited(Placares.enviar(widget.services.store));
    unawaited(RankingSync.enviar(widget.services.store));
    unawaited(JogoSalvo.salvar(widget.services.store));
    // A friend's invite counts once this player reaches level 5.
    final store = widget.services.store;
    if (store.conviteUsado != null &&
        store.conviteEnviado < 2 &&
        store.level >= Convites.faseQueConta) {
      unawaited(_sincronizarConvites());
    }
    if (!mounted) return;
    setState(() => _news = Onboarding.pendingNews(widget.services.store));
    unawaited(_lerPosicao());
  }

  Widget _towerCard(ProgressStore store) {
    if (!Onboarding.towerUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Torre do Capi'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.towerAt}),
        onTap: () => _locked('Torre do Capi', Onboarding.towerAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.layers_rounded,
      color: const Color(0xFF0284C7),
      title: tr('Torre do Capi'),
      subtitle: store.towerBestHeight > 0
          ? tr('Recorde {n} andares', {'n': store.towerBestHeight})
          : tr('Suba em 2.5D'),
      badge: store.hasSeen('opened_tower') && !_pendente(DestinoNovidade.torre)
          ? null
          : tr('NOVO'),
      onTap: _openTower,
    );
  }

  Widget _blitzCard(ProgressStore store) {
    if (!Onboarding.blitzUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Blitz 60s'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.blitzAt}),
        onTap: () => _locked('Blitz 60s', Onboarding.blitzAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.bolt_rounded,
      color: const Color(0xFFFA5252),
      title: tr('Blitz 60s'),
      subtitle: store.blitzBestScore > 0
          ? tr('Recorde {n}', {'n': formatInt(store.blitzBestScore)})
          : tr('Corrida de 60s'),
      badge: store.hasSeen('opened_blitz') && !_pendente(DestinoNovidade.blitz)
          ? null
          : tr('NOVO'),
      onTap: _openBlitz,
    );
  }

  /// The Blitz from its card or from the news (still locked: Capi says when).
  Future<void> _openBlitz() async {
    final store = widget.services.store;
    if (!Onboarding.blitzUnlocked(store)) {
      return _locked('Blitz 60s', Onboarding.blitzAt);
    }
    store.markSeen('opened_blitz');
    _abriu(DestinoNovidade.blitz);
    await _open(GameMode.blitz);
  }

  Widget _duelCard(ProgressStore store) {
    if (!Onboarding.duelUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Duelo'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.duelAt}),
        onTap: () => _locked('Duelo', Onboarding.duelAt),
      );
    }
    // Friends' answers not told yet (the menu had no room for them).
    final resultados = Duelos.novos(store).length;
    return MenuCard(
      compact: true,
      icon: Icons.sports_kabaddi_rounded,
      color: const Color(0xFF228BE6),
      title: tr('Duelo'),
      subtitle: resultados > 0
          ? trN(resultados, '{n} resultado novo', '{n} resultados novos')
          : store.duelsWon > 0
          ? tr('{n} vitórias', {'n': store.duelsWon})
          : tr('Desafie amigos'),
      badge:
          resultados == 0 &&
              store.hasSeen('opened_duel') &&
              !_pendente(DestinoNovidade.duelo)
          ? null
          : tr('NOVO'),
      onTap: _openDuelo,
    );
  }

  /// The Duel from its card or from the news (still locked: Capi says when).
  Future<void> _openDuelo() async {
    final store = widget.services.store;
    if (!Onboarding.duelUnlocked(store)) {
      return _locked('Duelo', Onboarding.duelAt);
    }
    store.markSeen('opened_duel');
    _abriu(DestinoNovidade.duelo);
    // Answers waiting: they come first, with the rematch.
    final novos = Duelos.novos(store);
    if (novos.isNotEmpty) {
      _sairDaFolha();
      widget.services.feedback.click();
      await _mostrarResultados(novos);
      return;
    }
    _openDuelDialog();
  }

  void _openDuelDialog() {
    _sairDaFolha();
    widget.services.feedback.click();
    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.sports_kabaddi_rounded,
              color: Color(0xFF339AF0),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(tr('Modo Duelo'), style: displayText(22, color: Palette.text)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'Você e um amigo jogam as mesmas {n} peças. Quem fizer mais pontos vence!',
                {'n': LevelConfig.duelPieces},
              ),
              style: bodyText(15, color: Palette.textDim),
            ),
            const SizedBox(height: 12),
            const RegrasDuelo(),
            const SizedBox(height: 12),
            for (final (i, passo) in [
              tr('Jogue as {n} peças e faça a sua pontuação.', {
                'n': LevelConfig.duelPieces,
              }),
              tr('No fim, toque em Desafiar Amigo e mande o link.'),
              tr('Seu amigo joga as mesmas peças e tenta passar você.'),
              tr('Quando ele jogar, você vê o resultado e o placar de vocês.'),
            ].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF228BE6),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: displayText(13, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        passo,
                        style: bodyText(15, color: Palette.text),
                      ),
                    ),
                  ],
                ),
              ),
            if (Duelos.placar(widget.services.store).isNotEmpty) ...[
              const SizedBox(height: 10),
              ListaPlacarDuelos(store: widget.services.store),
            ],
          ],
        ),
        scrollable: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              tr('Fechar'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
          ChunkyButton(
            label: tr('Começar Duelo'),
            icon: Icons.play_arrow_rounded,
            color: const Color(0xFF228BE6),
            textColor: Colors.white,
            onTap: () {
              Navigator.of(ctx).pop();
              _open(GameMode.duel, duelSeed: seed);
            },
          ),
        ],
      ),
    );
  }

  Widget _villageCard(ProgressStore store) {
    final built = store.villageBuilt;
    final next = Village.suggestion(store.villageItems);
    final canBuild = next != null && store.stars >= next.cost;
    return MenuCard(
      compact: true,
      icon: Icons.cottage_rounded,
      color: Palette.blocks[3],
      title: tr('Vila do Capi'),
      subtitle: next == null
          ? tr('Vila completa!')
          : tr('{n} de {total} prontos', {
              'n': built,
              'total': Village.items.length,
            }),
      badge: canBuild ? tr('CONSTRUIR!') : null,
      onTap: _openVillage,
    );
  }

  Widget _obrasCard(ProgressStore store) {
    if (!Onboarding.obrasUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Obras'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.obrasAt}),
        onTap: () => _locked('Obras', Onboarding.obrasAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.architecture_rounded,
      color: Palette.blocks[6],
      title: tr('Obras'),
      subtitle: tr('Obra {n}', {'n': store.obraLevel}),
      badge: store.hasSeen('opened_obras') ? null : tr('NOVO'),
      onTap: _openObras,
    );
  }

  Future<void> _openObras() async {
    _sairDaFolha();
    Analytics.event('screen_open', {'screen': 'obras'});
    widget.services.feedback.click();
    widget.services.store.markSeen('opened_obras');
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => ObraScreen(services: widget.services),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _endlessCard(ProgressStore store) {
    if (!Onboarding.endlessUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Infinito'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.endlessAt}),
        onTap: () => _locked('Infinito', Onboarding.endlessAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.all_inclusive_rounded,
      color: Palette.blocks[5],
      title: tr('Infinito'),
      subtitle: store.bestScore > 0
          ? tr('Recorde {n}', {'n': formatInt(store.bestScore)})
          : tr('Sem metas, sem fim'),
      badge: store.hasSeen('opened_endless') ? null : tr('NOVO'),
      onTap: () => _open(GameMode.endless),
    );
  }

  /// How each mode of the Modos sheet stands, for the card's line.
  List<EstadoModo> _estadoModos(ProgressStore store) => [
    EstadoModo(
      Atalho.infinito,
      liberado: Onboarding.endlessUnlocked(store),
      aberto: store.hasSeen('opened_endless'),
      recorde: store.bestScore > 0 ? formatInt(store.bestScore) : null,
    ),
    EstadoModo(
      Atalho.obras,
      liberado: Onboarding.obrasUnlocked(store),
      aberto: store.hasSeen('opened_obras'),
    ),
    EstadoModo(
      Atalho.blitz,
      liberado: Onboarding.blitzUnlocked(store),
      aberto: store.hasSeen('opened_blitz'),
      novidade: _pendente(DestinoNovidade.blitz),
      recorde: store.blitzBestScore > 0
          ? formatInt(store.blitzBestScore)
          : null,
    ),
    EstadoModo(
      Atalho.duelo,
      liberado: Onboarding.duelUnlocked(store),
      aberto: store.hasSeen('opened_duel'),
      novidade: _pendente(DestinoNovidade.duelo),
    ),
    EstadoModo(
      Atalho.torre,
      liberado: Onboarding.towerUnlocked(store),
      aberto: store.hasSeen('opened_tower'),
      novidade: _pendente(DestinoNovidade.torre),
      recorde: store.towerBestHeight > 0 ? '${store.towerBestHeight}' : null,
    ),
  ];

  /// Answers to the player's duels not told yet, once the Duel is open.
  int _resultadosDueloNovos(ProgressStore store) =>
      Onboarding.duelUnlocked(store) ? Duelos.novos(store).length : 0;

  /// A mode the player has unlocked but never opened: "NOVO" on Modos.
  bool _modoNovo(ProgressStore store) =>
      _resultadosDueloNovos(store) > 0 ||
      (Onboarding.endlessUnlocked(store) && !store.hasSeen('opened_endless')) ||
      (Onboarding.blitzUnlocked(store) &&
          (!store.hasSeen('opened_blitz') ||
              _pendente(DestinoNovidade.blitz))) ||
      (Onboarding.duelUnlocked(store) &&
          (!store.hasSeen('opened_duel') ||
              _pendente(DestinoNovidade.duelo))) ||
      (Onboarding.towerUnlocked(store) && !store.hasSeen('opened_tower')) ||
      (Onboarding.obrasUnlocked(store) && !store.hasSeen('opened_obras'));

  /// Every other way to play, in one sheet: the menu keeps room for the
  /// road.
  Future<void> _openModos() async {
    Analytics.event('screen_open', {'screen': 'modos'});
    widget.services.feedback.click();
    final store = widget.services.store;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        _folha = Navigator.of(ctx);
        Widget toque(Widget Function(ProgressStore) card) => card(store);
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Palette.panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Palette.panelEdge, width: 2),
            ),
            // A close button too: the iPhone has no back button.
            child: ComFechar(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        tr('Modos de jogo'),
                        style: displayText(20, color: Palette.text),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: toque(_endlessCard)),
                        const SizedBox(width: 10),
                        Expanded(child: toque(_blitzCard)),
                        const SizedBox(width: 10),
                        Expanded(child: toque(_duelCard)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: toque(_towerCard)),
                        const SizedBox(width: 10),
                        Expanded(child: toque(_obrasCard)),
                        const SizedBox(width: 10),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    _folha = null;
    if (mounted) setState(() {});
  }

  /// The Modos sheet while it is open: a mode chosen in it closes it first.
  NavigatorState? _folha;

  void _sairDaFolha() {
    final folha = _folha;
    _folha = null;
    if (folha != null && folha.mounted && folha.canPop()) folha.pop();
  }

  /// Under "Passe do Capi": rewards waiting, or the level.
  static String _passeSubtitulo(ProgressStore store) {
    final agora = DateTime.now();
    final prontas = PasseDoCapi.prontas(store, agora);
    return prontas > 0
        ? trN(prontas, '{n} prêmio pronto', '{n} prêmios prontos')
        : PasseDoCapi.nivel(store, agora) == 0
        ? tr('Prêmios da temporada')
        : tr('Nível {n}', {'n': PasseDoCapi.nivel(store, agora)});
  }

  Future<void> _openConvites() async {
    widget.services.feedback.click();
    _abriu(DestinoNovidade.convites);
    await showConvites(context, widget.services);
    if (mounted) setState(() {});
  }

  Future<void> _openPasse() async {
    widget.services.feedback.click();
    _abriu(DestinoNovidade.passe);
    unawaited(widget.services.store.markSeen(TemaDica.passe.aberto));
    await showPasse(context, widget.services);
    if (mounted) setState(() {});
  }

  /// The game's own ranking; where there is none (the web), the stores'
  /// boards or, without them, the player's own records.
  Future<void> _openRanking() async {
    Analytics.event('screen_open', {'screen': 'ranking'});
    widget.services.feedback.click();
    _abriu(DestinoNovidade.ranking);
    unawaited(widget.services.store.markSeen(TemaDica.ranking.aberto));
    if (RankingServidor.atual != null) {
      await RankingScreen.show(context, widget.services);
      // The places were seen: the arrows start over from here.
      await RankingResumo.visto(widget.services.store);
      if (mounted) setState(() {});
      unawaited(_lerPosicao());
      return;
    }
    if (Placares.ativo &&
        await Placares.mostrar(widget.services.store) &&
        mounted) {
      return;
    }
    if (mounted) await showStats(context, widget.services);
  }

  /// Now and then Capi shows himself in something from the wardrobe: on
  /// the first menu of a session and then every third, when nothing else
  /// is being said.
  static int _menus = 0;
  Cosmetic? _sugestao;
  Timer? _sugestaoTimer;

  void _talvezSugerir() {
    // Browser tests keep Capi as he is (they look at the menu around him).
    if (kTestBridge || _menus++ % 3 != 0) return;
    _sugestaoTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted || _capiLine != null || _dica != null) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final item = _escolherSugestao(widget.services.store);
      if (item == null) return;
      Analytics.event('capi_sugestao', {'item': item.id});
      setState(() => _sugestao = item);
      _sugestaoTimer = Timer(const Duration(seconds: 7), () {
        if (mounted) setState(() => _sugestao = null);
      });
    });
  }

  /// Something the player doesn't have yet, best one they can buy now.
  static Cosmetic? _escolherSugestao(ProgressStore store) {
    final faltam = [
      for (final c in Wardrobe.catalog)
        if (!Wardrobe.owns(store, c) && c.preco != null) c,
    ];
    if (faltam.isEmpty) return null;
    final cabe = [
      for (final c in faltam)
        if (c.preco! <= store.stars) c,
    ];
    final lista = cabe.isNotEmpty ? cabe : faltam;
    return lista[Random().nextInt(lista.length)];
  }

  Future<void> _verSugestao() async {
    _sugestaoTimer?.cancel();
    setState(() => _sugestao = null);
    await _openWardrobe();
  }

  /// Capi asking the player to bring friends (core/cartao_convite.dart),
  /// back on a quiet menu after a match won or a new record. True when the
  /// card was shown.
  Future<bool> _talvezCartaoConvite(bool momentoBom) async {
    final store = widget.services.store;
    // Browser tests keep the menu clear, except the one about the card.
    if (kTestBridge && !store.hasSeen('testar_convite')) return false;
    bool livre() =>
        mounted &&
        !_filaRodando &&
        _capiLine == null &&
        _sugestao == null &&
        _dica == null &&
        ModalRoute.of(context)?.isCurrent == true;
    if (!livre()) return false;
    if (!CartaoConvite.deveMostrar(
      store,
      DateTime.now(),
      momentoBom: momentoBom,
    )) {
      return false;
    }
    // Let the menu come back first.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!livre()) return false;
    final arte = await CartaoConvite.mostrado(store, DateTime.now());
    Analytics.event('convite_cartao', {'arte': arte.name});
    if (!mounted) return true;
    final convidar = await mostrarCartaoConvite(context, store, arte);
    if (convidar) {
      Analytics.event('convite_cartao_convidar', {'arte': arte.name});
      final copiou = await compartilharConvite(
        widget.services,
        dados: {'origem': 'cartao'},
      );
      // The code on the server, in case the menu's sync didn't get to it.
      unawaited(_sincronizarConvites());
      if (copiou && mounted) {
        mostrarPremio(
          context,
          tr('Convite copiado! Cole no WhatsApp.'),
          icon: Icons.share_rounded,
        );
      }
    } else {
      Analytics.event('convite_cartao_recusa', {'arte': arte.name});
      await CartaoConvite.recusado(store);
    }
    return true;
  }

  /// Capi's tip of the day (core/dica_do_dia.dart): once a day, back on a
  /// quiet menu, about something open that the player never used.
  TemaDica? _dica;
  Timer? _dicaTimer;

  void _talvezDica() {
    final store = widget.services.store;
    // Browser tests keep the menu clear, except the one about the tip.
    if (kTestBridge && !store.hasSeen('testar_dica')) return;
    if (_filaRodando) return;
    _dicaTimer?.cancel();
    _dicaTimer = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted || _capiLine != null || _sugestao != null) return;
      if (_dica != null || ModalRoute.of(context)?.isCurrent != true) return;
      final agora = DateTime.now();
      final tema = DicaDoDia.paraHoje(
        store,
        agora,
        lojaExiste: widget.services.loja.existe,
      );
      if (tema == null) return;
      await DicaDoDia.mostrada(store, tema, agora);
      if (!mounted) return;
      Analytics.event('dica_capi', {'tema': tema.name});
      setState(() => _dica = tema);
      _dicaTimer = Timer(const Duration(seconds: 12), () {
        if (mounted) setState(() => _dica = null);
      });
    });
  }

  Future<void> _verDica() async {
    final tema = _dica;
    _dicaTimer?.cancel();
    setState(() => _dica = null);
    if (tema == null) return;
    Analytics.event('dica_capi_ver', {'tema': tema.name});
    await switch (tema) {
      TemaDica.guardaRoupa => _openWardrobe(),
      TemaDica.loja => _openLoja(),
      TemaDica.passe => _openPasse(),
      TemaDica.blitz => _openBlitz(),
      TemaDica.ranking => _openRanking(),
      TemaDica.duelo => _openDuelo(),
      TemaDica.missoes => _openDailyMissions(),
      TemaDica.torre => _openTower(),
      TemaDica.infinito => _open(GameMode.endless),
      TemaDica.vila => _openVillage(),
      TemaDica.obras => _openObras(),
      TemaDica.desafioDiario => _open(GameMode.daily),
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final today = DateTime.now();
    final dailyDone = store.dailyDone(today);
    final streak = store.dailyStreak(today);
    final dailyOpen = Onboarding.dailyUnlocked(store);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = MediaQuery.sizeOf(context).height < 720;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 20.0;
    final buttonGap = screenWidth < 360 ? 4.0 : 6.0;
    final capiLine = _capiLine;
    final hoje = ProgressStore.dayKey(today);
    // Why the shop button calls: an offer, the piggy bank, today's offers.
    final motivoLoja = MenuEstado.motivoLoja(
      ofertaNoAr:
          Entrega.mostraPacoteInicial(store, today) ||
          OfertaBoasVindas.noAr(store, today),
      cofrinhoCheio: Cofrinho.cheio(store),
      lojaVistaDia: store.lojaVistaDia,
      hoje: hoje,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBlocks()),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: menuMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Semantics(
                              button: true,
                              label: tr('{n} estrelas, abrir a vila', {
                                'n': store.stars,
                              }),
                              excludeSemantics: true,
                              onTap: _openVillage,
                              child: GestureDetector(
                                onTap: _openVillage,
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  height: 44,
                                  child: Center(
                                    child: StatChip(
                                      icon: Icons.star_rounded,
                                      color: Palette.accent,
                                      value: formatInt(store.stars),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: buttonGap),
                            StatChip(
                              icon: Icons.local_fire_department_rounded,
                              color: Palette.accentDeep,
                              value: '$streak',
                            ),
                            const Spacer(),
                            RoundIconButton(
                              icon: Icons.assignment_turned_in_rounded,
                              label: tr('Missões Diárias'),
                              // Missions, chest and Passe rewards waiting.
                              badge: _waiting(store, today) > 0
                                  ? '${_waiting(store, today)}'
                                  : null,
                              onTap: _openDailyMissions,
                            ),
                            if (widget.services.loja.existe) ...[
                              SizedBox(width: buttonGap),
                              _LojaBotao(
                                badge: motivoLoja != null ? '!' : null,
                                fala:
                                    MenuEstado.lojaChama(
                                      motivoLoja,
                                      lojaVistaDia: store.lojaVistaDia,
                                      hoje: hoje,
                                    )
                                    ? motivoLoja!.fala
                                    : null,
                                onTap: _openLoja,
                              ),
                            ],
                            SizedBox(width: buttonGap),
                            RoundIconButton(
                              icon: Icons.settings_rounded,
                              label: tr('Configurações'),
                              onTap: () =>
                                  showSettings(context, widget.services),
                            ),
                          ],
                        ),
                        if (!isSmall) ...[
                          const SizedBox(height: 6),
                          Logo(compact: true, showCapi: false),
                        ],
                        SizedBox(height: isSmall ? 8 : 10),
                        // What the player looks at first: dressing Capi,
                        // the season's pass and the leaderboards.
                        Row(
                          children: [
                            Expanded(
                              child: _Destaque(
                                icon: Icons.checkroom_rounded,
                                cor: const Color(0xFFE8590C),
                                titulo: tr('Guarda-Roupa'),
                                subtitulo: tr('Vista o Capi'),
                                pendente: _pendente(
                                  DestinoNovidade.guardaRoupa,
                                ),
                                onTap: _openWardrobe,
                              ),
                            ),
                            SizedBox(width: buttonGap + 2),
                            Expanded(
                              child: _Destaque(
                                icon: Icons.military_tech_rounded,
                                cor: const Color(0xFF9C36B5),
                                titulo: tr('Passe do Capi'),
                                subtitulo: _passeSubtitulo(store),
                                pendente: _pendente(DestinoNovidade.passe),
                                onTap: _openPasse,
                              ),
                            ),
                            SizedBox(width: buttonGap + 2),
                            Expanded(
                              child: _Destaque(
                                icon: Icons.emoji_events_rounded,
                                cor: const Color(0xFF1971C2),
                                titulo: tr('Ranking'),
                                subtitulo: _rankingSubtitulo(store),
                                pendente: _pendente(DestinoNovidade.ranking),
                                seta: _posicao == null
                                    ? 0
                                    : _posicao!.caiu
                                    ? -1
                                    : _posicao!.subiu
                                    ? 1
                                    : 0,
                                onTap: _openRanking,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmall ? 6 : 8),
                        _ConviteFaixa(store: store, onTap: _openConvites),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmall ? 4 : 8,
                            ),
                            // Capi stands big by the road, in everything
                            // he wears; the road keeps clear of him.
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final capi = min(
                                  150.0,
                                  max(96.0, box.maxHeight * 0.42),
                                );
                                final sugestao = _sugestao;
                                final dica = _dica;
                                final look = sugestao == null
                                    ? CapiLook.of(store)
                                    : CapiLook.of(store).wearing(sugestao);
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: LevelPath(
                                        current: store.level,
                                        leftInset: capi * 0.78,
                                        onPlay: () => _open(GameMode.levels),
                                        starsFor: (n) =>
                                            Missions.count(store.levelStars(n)),
                                        onReplay: (n) => _open(
                                          GameMode.levels,
                                          replayLevel: n,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: -capi * 0.1,
                                      bottom: 0,
                                      child: Semantics(
                                        button: true,
                                        label: 'Capi',
                                        excludeSemantics: true,
                                        onTap: _tip,
                                        child: GestureDetector(
                                          onTap: dica != null
                                              ? _verDica
                                              : sugestao == null
                                              ? _tip
                                              : _verSugestao,
                                          child: Capi(size: capi, look: look),
                                        ),
                                      ),
                                    ),
                                    if (dica != null)
                                      Positioned(
                                        left: 0,
                                        bottom: capi * 0.98,
                                        child: _SugestaoBalao(
                                          key: ValueKey(dica),
                                          texto: dica.texto,
                                          acao: '${tr('Ver agora')} ›',
                                          rotulo: tr('Ver agora'),
                                          onTap: _verDica,
                                        ),
                                      )
                                    else if (sugestao != null)
                                      Positioned(
                                        left: 0,
                                        bottom: capi * 0.98,
                                        child: _SugestaoBalao(
                                          texto: tr(
                                            'Que tal {item}? Fica a minha cara!',
                                            {'item': sugestao.label},
                                          ),
                                          onTap: _verSugestao,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        ChunkyButton(
                          big: true,
                          icon: Icons.play_arrow_rounded,
                          label: tr('Jogar · Fase {n}', {'n': store.level}),
                          onTap: () => _open(GameMode.levels),
                        ),
                        SizedBox(height: isSmall ? 10 : 18),
                        Row(
                          children: [
                            Expanded(child: _villageCard(store)),
                            SizedBox(width: buttonGap + 4),
                            Expanded(
                              child: dailyOpen
                                  ? MenuCard(
                                      compact: true,
                                      icon: dailyDone
                                          ? Icons.check_circle_rounded
                                          : Icons.calendar_today_rounded,
                                      color: Palette.blocks[0],
                                      title: tr('Desafio diário'),
                                      // Not played today: said plainly.
                                      subtitle: dailyDone
                                          ? tr('Feito! Volte amanhã')
                                          : streak > 0
                                          ? tr('Falta hoje · sequência {n}', {
                                              'n': streak,
                                            })
                                          : tr('Ainda não jogado hoje'),
                                      badge: dailyDone ? null : tr('HOJE'),
                                      onTap: () => _open(GameMode.daily),
                                    )
                                  : MenuCard(
                                      compact: true,
                                      icon: Icons.lock_rounded,
                                      color: Palette.panelEdge,
                                      title: tr('Desafio diário'),
                                      subtitle: tr('Libera na fase {n}', {
                                        'n': Onboarding.dailyAt,
                                      }),
                                      onTap: () => _locked(
                                        'Desafio diário',
                                        Onboarding.dailyAt,
                                      ),
                                    ),
                            ),
                            SizedBox(width: buttonGap + 4),
                            Expanded(
                              child: MenuCard(
                                compact: true,
                                icon: Icons.sports_esports_rounded,
                                color: Palette.blocks[5],
                                title: tr('Modos'),
                                subtitle: MenuEstado.modosSubtitulo(
                                  _estadoModos(store),
                                  resultadosDuelo: _resultadosDueloNovos(store),
                                  dia: ProgressStore.dayKey(today),
                                ),
                                badge: _modoNovo(store) ? tr('NOVO') : null,
                                onTap: _openModos,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmall ? 10 : 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (capiLine != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _dismissCapi,
                  child: const ColoredBox(color: Color(0x88080A20)),
                ),
              ),
            if (capiLine != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24 + MediaQuery.paddingOf(context).bottom,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: menuMaxWidth),
                    child: CapiSays(
                      text: capiLine,
                      capiSize: 96,
                      action: _news.isNotEmpty ? tr('Bora!') : tr('Beleza!'),
                      onAction: _dismissCapi,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The shop button: glows gold, unlike the others, and now and then Capi's
/// balloon calls the player to it.
class _LojaBotao extends StatefulWidget {
  const _LojaBotao({required this.onTap, this.badge, this.fala});
  final VoidCallback onTap;
  final String? badge;

  /// What the balloon says, while there is something new in the shop
  /// (core/menu_estado.dart); null keeps it quiet.
  final String? fala;

  @override
  State<_LojaBotao> createState() => _LojaBotaoState();
}

class _LojaBotaoState extends State<_LojaBotao>
    with SingleTickerProviderStateMixin {
  /// Calls per visit to the menu, at most.
  static const _maxChamadas = 3;

  late final AnimationController _brilho = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  Timer? _timer;
  String? _fala;
  int _vez = 0;

  @override
  void initState() {
    super.initState();
    // The first call comes soon after opening the menu, then every so often.
    _timer = Timer(const Duration(seconds: 4), _chamar);
  }

  void _chamar() {
    if (!mounted) return;
    final fala = widget.fala;
    // Nothing new in the shop: no call this time.
    if (fala == null) {
      _timer = Timer(const Duration(seconds: 90), _chamar);
      return;
    }
    if (_vez++ >= _maxChamadas) return;
    // The balloon goes in the overlay, above the logo under the bar.
    if (!_portal.isShowing) _portal.show();
    setState(() => _fala = fala);
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _fala = null);
      // The overlay closes once the balloon has shrunk away.
      _timer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _fala == null && _portal.isShowing) _portal.hide();
        _timer = Timer(const Duration(seconds: 90), _chamar);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _brilho.dispose();
    super.dispose();
  }

  final _link = LayerLink();
  final _portal = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(8, 6),
          // Just decoration (the Loja button has its own label): kept out
          // of the semantics, where a full-screen overlay node would sit
          // over every button of the menu.
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _fala == null
                    ? const SizedBox.shrink()
                    : _Balao(key: ValueKey(_fala), texto: _fala!),
              ),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: AnimatedBuilder(
          animation: _brilho,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_brilho.value);
            final borda = BorderRadius.circular(14);
            return Container(
              decoration: BoxDecoration(
                borderRadius: borda,
                boxShadow: [
                  BoxShadow(
                    color: Palette.accent.withValues(alpha: 0.3 + 0.45 * t),
                    blurRadius: 6 + 12 * t,
                    spreadRadius: 1 + 2.5 * t,
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: borda,
                border: Border.all(
                  color: Color.lerp(
                    Palette.accent.withValues(alpha: 0.6),
                    const Color(0xFFFFF1B8),
                    t,
                  )!,
                  width: 2,
                ),
              ),
              child: child,
            );
          },
          child: RoundIconButton(
            icon: Icons.storefront_rounded,
            label: tr('Loja'),
            badge: widget.badge,
            iconColor: Palette.accent,
            fill: const Color(0xFF5A3A12),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

/// A small balloon pointing up at the shop button.
class _Balao extends StatelessWidget {
  const _Balao({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 18),
        child: CustomPaint(size: const Size(12, 7), painter: _PontaBalao()),
      ),
      Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: displayText(13, color: const Color(0xFF2A1458)),
        ),
      ),
    ],
  );
}

class _PontaBalao extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PontaBalao old) => false;
}

/// One of the three big buttons under the top bar: wardrobe, market,
/// leaderboards.
class _Destaque extends StatelessWidget {
  const _Destaque({
    required this.icon,
    required this.cor,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.pendente = false,
    this.seta = 0,
  });

  final IconData icon;
  final Color cor;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  /// Something new here that the player has not opened: a dot, like a
  /// notification.
  final bool pendente;

  /// By the subtitle: 1 for a green arrow up, -1 for a red one down.
  final int seta;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: titulo,
      hint: [
        subtitulo,
        if (seta > 0) tr('subiu'),
        if (seta < 0) tr('caiu'),
        if (pendente) tr('novidade'),
      ].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 62,
          foregroundDecoration: pendente ? const _Bolinha() : null,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(cor, Colors.white, 0.15)!, cor],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: Color.lerp(cor, Colors.black, 0.35)!,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        titulo,
                        maxLines: 1,
                        style: displayText(15, color: Colors.white),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            subtitulo,
                            maxLines: 1,
                            style: bodyText(12, color: const Color(0xDDFFFFFF)),
                          ),
                          if (seta != 0)
                            Icon(
                              seta > 0
                                  ? Icons.arrow_drop_up_rounded
                                  : Icons.arrow_drop_down_rounded,
                              size: 18,
                              color: seta > 0
                                  ? const Color(0xFF8CE99A)
                                  : const Color(0xFFFF6B6B),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Capi's balloon over his head when he shows himself in something new.
/// The red dot on the top right corner of a card with something new.
class _Bolinha extends Decoration {
  const _Bolinha();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _BolinhaPainter();
}

class _BolinhaPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final centro = offset + Offset(size.width - 7, 7);
    canvas.drawCircle(centro, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(centro, 5, Paint()..color = const Color(0xFFEF4444));
  }
}

class _SugestaoBalao extends StatelessWidget {
  const _SugestaoBalao({
    super.key,
    required this.texto,
    required this.onTap,
    this.acao,
    this.rotulo,
  });
  final String texto;
  final VoidCallback onTap;

  /// The line under the text (by default, to the wardrobe).
  final String? acao;

  /// The button's name for screen readers (the text goes as its hint);
  /// by default the text itself.
  final String? rotulo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo ?? texto,
      hint: rotulo == null ? null : texto,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(
            scale: v,
            alignment: Alignment.bottomLeft,
            child: child,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 190),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 6),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: displayText(13, color: const Color(0xFF2A1458)),
                ),
                const SizedBox(height: 2),
                Text(
                  acao ?? tr('Ver no guarda-roupa ›'),
                  style: bodyText(12, color: const Color(0xFF7048E8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Under the highlights: the invite call, with the next prize. Now and
/// then (like the shop) it gives a little shake and says something else,
/// inside the button itself (no overlay over the menu).
class _ConviteFaixa extends StatefulWidget {
  const _ConviteFaixa({required this.store, required this.onTap});
  final ProgressStore store;
  final VoidCallback onTap;

  @override
  State<_ConviteFaixa> createState() => _ConviteFaixaState();
}

class _ConviteFaixaState extends State<_ConviteFaixa>
    with SingleTickerProviderStateMixin {
  static const _lembretes = [
    'Seus amigos ganham 50 estrelas!',
    'Chame um amigo para a Vila!',
  ];

  late final AnimationController _balanco = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _timer;
  String? _lembrete;
  int _vez = 0;

  /// Shakes per visit to the menu, at most: a reminder, not a nag.
  static const _maxLembretes = 2;

  @override
  void initState() {
    super.initState();
    // Well after the shop's balloon (4 s), then seldom.
    _timer = Timer(const Duration(seconds: 25), _lembrar);
  }

  void _lembrar() {
    if (!mounted || _vez >= _maxLembretes) return;
    setState(() => _lembrete = tr(_lembretes[_vez++ % _lembretes.length]));
    _balanco.forward(from: 0);
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _lembrete = null);
      _timer = Timer(const Duration(minutes: 2), _lembrar);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _balanco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final proxima = Convites.proxima(store);
    final texto =
        _lembrete ??
        (proxima == null
            ? tr('Capi Embaixador! Continue chamando amigos')
            : tr('Convide amigos e ganhe: {premio}', {
                'premio': proxima.texto,
              }));
    return Semantics(
      button: true,
      label: tr('Convidar amigos'),
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _balanco,
          builder: (context, child) {
            final v = _balanco.value;
            // A short wiggle that settles.
            final angulo = sin(v * pi * 6) * 0.035 * (1 - v);
            return Transform.rotate(angle: angulo, child: child);
          },
          child: Container(
            // 44: the smallest comfortable tap target.
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B8A3E), Color(0xFF37B24D)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _lembrete != null
                    ? const Color(0xFFFFF1B8)
                    : const Color(0x55FFFFFF),
                width: _lembrete != null ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      texto,
                      key: ValueKey(texto),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: displayText(14, color: Colors.white),
                    ),
                  ),
                ),
                if (proxima != null)
                  Text(
                    '${store.conviteAmigos}/${proxima.amigos}',
                    style: displayText(14, color: const Color(0xFFD3F9D8)),
                  ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
