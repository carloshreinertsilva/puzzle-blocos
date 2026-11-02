import 'package:flutter/material.dart';

import '../core/passe.dart';
import '../core/wardrobe.dart';
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

class _Passe extends StatefulWidget {
  const _Passe({required this.services});
  final AppServices services;

  @override
  State<_Passe> createState() => _PasseState();
}

class _PasseState extends State<_Passe> {
  bool _comprando = false;
  String? _aviso;

  ProgressStore get _store => widget.services.store;
  LojaService get _loja => widget.services.loja;

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

  Future<void> _pegar(int n, {required bool premium}) async {
    final ok = await PasseDoCapi.pegar(
      _store,
      DateTime.now(),
      n,
      trilhaPremium: premium,
    );
    if (!ok || !mounted) return;
    widget.services.feedback.praise(2);
    final r = premium
        ? PasseDoCapi.trilha[n - 1].premium
        : PasseDoCapi.trilha[n - 1].gratis;
    setState(() => _aviso = 'Você ganhou: ${r.texto}!');
  }

  Future<void> _comprar() async {
    if (_comprando) return;
    setState(() => _comprando = true);
    final r = await _loja.comprar(Produto.passeCapi);
    if (!mounted) return;
    setState(() {
      _comprando = false;
      _aviso = switch (r) {
        ResultadoCompra.ok => 'Trilha premium liberada! Pegue seus prêmios.',
        ResultadoCompra.pendente =>
          'Pagamento pendente: a trilha libera quando ele for aprovado.',
        ResultadoCompra.cancelada => null,
        _ => 'Não deu para comprar agora. Tente de novo mais tarde.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final temporada = PasseDoCapi.temporada(agora);
    final nivel = PasseDoCapi.nivel(_store, agora);
    final pontos = PasseDoCapi.pontos(_store, agora);
    final premium = PasseDoCapi.premium(_store, agora);
    final dentro = nivel >= PasseDoCapi.niveis
        ? PasseDoCapi.pontosPorNivel
        : pontos % PasseDoCapi.pontosPorNivel;
    final dias = PasseDoCapi.diasRestantes(agora);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
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
                        'Passe do Capi',
                        style: displayText(22, color: Palette.text),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Fechar',
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
              _texto(
                'Temporada $temporada · termina em $dias '
                '${dias == 1 ? 'dia' : 'dias'}',
                bodyText(13, color: Palette.textDim),
              ),
              const SizedBox(height: 8),
              // Progress: level and points toward the next one.
              _texto(
                'Nível $nivel de ${PasseDoCapi.niveis}',
                displayText(16, color: Palette.accent),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: dentro / PasseDoCapi.pontosPorNivel,
                  minHeight: 10,
                  backgroundColor: const Color(0x22FFFFFF),
                  color: Palette.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nivel >= PasseDoCapi.niveis
                    ? 'Passe completo nesta temporada!'
                    : 'Cada estrela ganha jogando vale 1 ponto: '
                          '$dentro/${PasseDoCapi.pontosPorNivel} para o '
                          'próximo nível.',
                textAlign: TextAlign.center,
                style: bodyText(12, color: Palette.textDim),
              ),
              const SizedBox(height: 8),
              if (!premium) _premiumCta(),
              if (_aviso != null) ...[
                const SizedBox(height: 6),
                _texto(_aviso!, bodyText(13, color: Palette.good)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Grátis',
                      textAlign: TextAlign.center,
                      style: displayText(13, color: Palette.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Premium',
                      textAlign: TextAlign.center,
                      style: displayText(13, color: Palette.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: PasseDoCapi.niveis,
                  itemBuilder: (context, i) => _linha(i + 1, nivel, premium),
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

  Widget _premiumCta() {
    if (!_loja.disponivel) {
      return Text(
        'A trilha premium sai no app Android (Google Play).',
        textAlign: TextAlign.center,
        style: bodyText(12, color: Palette.textDim),
      );
    }
    final preco = _loja.preco(Produto.passeCapi);
    return Column(
      children: [
        Text(
          'Premium: 1 lendário exclusivo, 2 raros exclusivos, 140 estrelas e '
          'ferramentas. Você vê tudo antes de comprar.',
          textAlign: TextAlign.center,
          style: bodyText(12, color: Palette.text),
        ),
        const SizedBox(height: 6),
        ChunkyButton(
          label: _comprando
              ? 'Abrindo…'
              : PasseDoCapi.precoLancamento(DateTime.now())
              ? 'Premium · $preco (lançamento)'
              : 'Liberar premium · $preco',
          semanticLabel: 'Liberar a trilha premium do Passe por $preco',
          icon: Icons.workspace_premium_rounded,
          onTap: _comprando ? null : _comprar,
        ),
      ],
    );
  }

  Widget _linha(int n, int nivel, bool premium) {
    final alcancado = n <= nivel;
    final nivelPasse = PasseDoCapi.trilha[n - 1];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: alcancado
                  ? Palette.accent
                  : const Color(0x22FFFFFF),
              child: Text(
                '$n',
                style: displayText(
                  13,
                  color: alcancado ? const Color(0xFF3A2200) : Palette.text,
                ),
              ),
            ),
          ),
          Expanded(
            child: _celula(n, nivelPasse.gratis, premium: false, aberta: true),
          ),
          const SizedBox(width: 8),
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
    final trilha = premium ? 'premium' : 'grátis';
    final estado = pegou
        ? 'já pego'
        : pode
        ? 'pegar'
        : !aberta
        ? 'bloqueado'
        : 'nível $n';
    final borda =
        item?.raridade.color ??
        (premium
            ? Palette.accent.withValues(alpha: 0.6)
            : const Color(0x33FFFFFF));

    final celula = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: pode
            ? Palette.accent.withValues(alpha: 0.22)
            : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borda, width: pode ? 2 : 1),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 36,
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
                    size: 24,
                  ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              r.texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bodyText(11, color: Palette.text),
            ),
          ),
          if (pegou)
            const Icon(
              Icons.check_circle_rounded,
              color: Palette.good,
              size: 18,
            )
          else if (!aberta)
            const Icon(Icons.lock_rounded, color: Palette.textDim, size: 16)
          else if (pode)
            const Icon(Icons.redeem_rounded, color: Palette.accent, size: 20),
        ],
      ),
    );

    return Semantics(
      button: pode,
      label: 'Nível $n $trilha: ${r.texto}, $estado',
      excludeSemantics: true,
      onTap: pode ? () => _pegar(n, premium: premium) : null,
      child: GestureDetector(
        onTap: pode ? () => _pegar(n, premium: premium) : null,
        child: Opacity(opacity: aberta ? 1 : 0.6, child: celula),
      ),
    );
  }
}
