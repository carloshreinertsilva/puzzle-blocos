import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/duelos.dart';
import 'package:puzzle_blocos/services/duelo_link.dart';
import 'package:puzzle_blocos/services/duelos_servidor.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One phone: its saved progress and its id on the server. The tests
/// switch between phones by loading each one's progress back.
Future<ProgressStore> _celular(
  DuelosDeTeste servidor,
  String uid, [
  Map<String, Object> dados = const {},
]) async {
  SharedPreferences.setMockInitialValues(dados);
  DuelosSync.limpar();
  servidor.uid = uid;
  return ProgressStore.load();
}

void main() {
  late DuelosDeTeste servidor;

  setUp(() {
    servidor = DuelosDeTeste();
    DuelosServidor.atual = servidor;
  });
  tearDown(() {
    DuelosServidor.atual = null;
    DuelosSync.limpar();
  });

  test('sem servidor ou sem nome, o link sai simples', () async {
    final ana = await _celular(servidor, 'ana');
    await DuelosSync.preparar();
    const convite = DueloConvite(semente: 7, meta: 1000);
    expect(DuelosSync.criar(ana, convite), isNull);
    DuelosServidor.atual = null;
    await ana.setRankingNome('Ana');
    expect(DuelosSync.criar(ana, convite), isNull);
  });

  test('o amigo joga, o resultado volta e o placar fica com os dois', () async {
    // Ana desafia com 1.000 pontos.
    var ana = await _celular(servidor, 'ana');
    await ana.setRankingNome('Ana');
    await DuelosSync.preparar();
    final convite = DuelosSync.criar(
      ana,
      const DueloConvite(semente: 7, meta: 1000),
    )!;
    expect(convite.nome, 'Ana');
    expect(convite.link.queryParameters['d'], convite.id);
    await Future<void>.delayed(Duration.zero);
    expect(servidor.duelos[convite.id]!.dono, 'ana');
    final dadosAna = ana.exportar();

    // Bia abre o link e faz 1.500.
    final bia = await _celular(servidor, 'bia');
    await bia.setRankingNome('Bia');
    final r = await DuelosSync.responder(bia, convite.id!, 1500);
    expect(r!.venci, isTrue);
    expect(r.nome, 'Ana');
    // Tentar de novo com menos não muda nada.
    await DuelosSync.responder(bia, convite.id!, 900);
    expect(servidor.respostas.values.single.pontos, 1500);
    final placarBia = Duelos.contra(bia, 'ana')!;
    expect((placarBia.vitorias, placarBia.derrotas), (1, 0));
    // A Bia viu o resultado na hora: nada a contar para ela.
    expect(Duelos.novos(bia), isEmpty);

    // Ana abre o jogo e fica sabendo.
    ana = await _celular(servidor, 'ana', dadosAna);
    final novos = await DuelosSync.buscar(ana);
    expect(novos.single.nome, 'Bia');
    expect(novos.single.perdi, isTrue);
    expect((novos.single.eu, novos.single.ele), (1000, 1500));
    final placarAna = Duelos.contra(ana, 'bia')!;
    expect((placarAna.vitorias, placarAna.derrotas), (0, 1));
    await Duelos.marcarVistos(ana);
    expect(await DuelosSync.buscar(ana), isEmpty);
  });

  test(
    'revanche: quem perdeu joga o mesmo tabuleiro e desafia o amigo de volta',
    () async {
      var ana = await _celular(servidor, 'ana');
      await ana.setRankingNome('Ana');
      await DuelosSync.preparar();
      final convite = DuelosSync.criar(
        ana,
        const DueloConvite(semente: 7, meta: 1000, blitz: true),
      )!;
      await Future<void>.delayed(Duration.zero);
      final dadosAna = ana.exportar();

      final bia = await _celular(servidor, 'bia');
      await bia.setRankingNome('Bia');
      await DuelosSync.responder(bia, convite.id!, 1500);

      ana = await _celular(servidor, 'ana', dadosAna);
      final perdido = (await DuelosSync.buscar(ana)).single;
      // O tabuleiro do desafio volta do servidor.
      final duelo = (await DuelosSync.ler(perdido.duelo))!;
      expect((duelo.semente, duelo.blitz), (7, true));

      expect(
        await DuelosSync.revanche(
          ana,
          r: perdido,
          semente: 7,
          blitz: true,
          pontos: 1800,
        ),
        isTrue,
      );
      final id = servidor.revanches.keys.single;
      expect(servidor.revanches[id], (para: 'bia', origem: convite.id!));
      expect(servidor.duelos[id]!.pontos, 1800);
      expect(servidor.duelos[id]!.semente, 7);
    },
  );

  test('o próprio desafio não conta como resposta', () async {
    final ana = await _celular(servidor, 'ana');
    await ana.setRankingNome('Ana');
    await DuelosSync.preparar();
    final c = DuelosSync.criar(ana, const DueloConvite(semente: 1, meta: 50))!;
    await Future<void>.delayed(Duration.zero);
    expect(await DuelosSync.responder(ana, c.id!, 80), isNull);
    expect(servidor.respostas, isEmpty);
  });

  test(
    'o placar soma os duelos de cada amigo, o mais recente primeiro',
    () async {
      final s = await _celular(servidor, 'eu');
      Future<void> duelo(String id, String rival, int eu, int ele, int em) =>
          Duelos.registrar(
            s,
            ResultadoDuelo(
              duelo: id,
              rival: rival,
              nome: rival.toUpperCase(),
              eu: eu,
              ele: ele,
              meu: true,
              em: em,
            ),
          );
      await duelo('d1', 'bia', 10, 5, 1);
      await duelo('d2', 'bia', 3, 5, 2);
      await duelo('d3', 'bia', 7, 7, 3);
      await duelo('d4', 'caio', 9, 1, 4);
      final p = Duelos.placar(s);
      expect(p.map((x) => x.nome), ['CAIO', 'BIA']);
      final bia = p.last;
      expect((bia.vitorias, bia.derrotas, bia.empates), (1, 1, 1));
      // A friend's better answer to the same duel replaces the old one.
      await duelo('d2', 'bia', 3, 2, 5);
      final depois = Duelos.contra(s, 'bia')!;
      expect((depois.vitorias, depois.derrotas), (2, 0));
      expect(Duelos.todos(s).length, 4);
    },
  );
}
