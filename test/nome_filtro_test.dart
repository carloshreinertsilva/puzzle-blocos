import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/nome_filtro.dart';

void main() {
  test('nomes comuns passam', () {
    for (final nome in [
      'Carlos',
      'Ana Paula',
      'João_2014',
      'Capi Veloz',
      'Zé',
      'Deputado Rex',
      'Pintor.Leo',
      'Rolando',
      'Killer Bee',
      'Sexta Feira',
      'Escola 12',
      'María-José',
      'Concha Azul',
      'Pinta Brava',
    ]) {
      expect(
        NomeFiltro.recusar(nome),
        nome == 'Zé' ? NomeRecusado.curto : isNull,
        reason: nome,
      );
    }
  });

  test('tamanho e caracteres', () {
    expect(NomeFiltro.recusar('  ab '), NomeRecusado.curto);
    expect(NomeFiltro.recusar('a' * 17), NomeRecusado.longo);
    expect(NomeFiltro.recusar('Ana<script>'), NomeRecusado.caracteres);
    expect(NomeFiltro.recusar('😀😀😀'), NomeRecusado.caracteres);
    expect(NomeFiltro.recusar('12345'), NomeRecusado.caracteres);
    expect(NomeFiltro.limpar('  Ana   Paula '), 'Ana Paula');
  });

  test('palavrões são recusados, mesmo disfarçados', () {
    for (final nome in [
      'merda',
      'M3RD4',
      'meeerda',
      'p.u.t.a',
      'p u t a',
      'Puta Madre',
      'xXfuckXx',
      'sh1t',
      'b1tch',
      'cuzão',
      'vai tomar no cu',
      'FDP',
      'Hitler',
      'n1gg3r',
      'pendejo',
      'Admin',
      'CapiBlocks',
      'Moderador',
    ]) {
      expect(NomeFiltro.recusar(nome), NomeRecusado.improprio, reason: nome);
    }
  });

  test('a lista cresce pelo servidor, sem versão nova', () {
    expect(NomeFiltro.recusar('Zureta'), isNull);
    NomeFiltro.extras = {'zureta'};
    expect(NomeFiltro.recusar('Zureta'), NomeRecusado.improprio);
    expect(NomeFiltro.recusar('xZur3taX'), NomeRecusado.improprio);
    NomeFiltro.extras = {};
  });
}
