/// Why a ranking name was refused.
enum NomeRecusado { curto, longo, caracteres, improprio }

/// The names players choose for the ranking: what they may contain and the
/// filter against swearing and insults (Portuguese, English and Spanish).
///
/// The filter looks through the usual disguises: accents, capital letters,
/// digits and symbols in place of letters (`m3rd4`), repeated letters and
/// dots or spaces between the letters. It can't catch everything: players
/// can also report a name (see ranking_screen.dart), and the list grows
/// without a new version through [extras] (config/ranking in Firestore).
abstract final class NomeFiltro {
  static const minimo = 3;
  static const maximo = 16;

  /// Letters (with accents), digits, spaces and `_ . -`.
  static final _permitido = RegExp(r"^[\p{L}\p{N} _.\-]+$", unicode: true);
  static final _letra = RegExp(r'\p{L}', unicode: true);

  /// More words to refuse, from the server (already normalized).
  static Set<String> extras = {};

  /// [texto] as it is kept: no spaces around or doubled.
  static String limpar(String texto) =>
      texto.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Null when [texto] can be a ranking name.
  static NomeRecusado? recusar(String texto) {
    final nome = limpar(texto);
    if (nome.length < minimo) return NomeRecusado.curto;
    if (nome.length > maximo) return NomeRecusado.longo;
    if (!_permitido.hasMatch(nome)) return NomeRecusado.caracteres;
    if (_letra.allMatches(nome).length < 2) return NomeRecusado.caracteres;
    return improprio(nome) ? NomeRecusado.improprio : null;
  }

  static const _acentos = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  /// Digits and symbols that stand in for letters.
  static const _disfarces = {
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
    '8': 'b',
    '@': 'a',
    r'$': 's',
    '!': 'i',
    '|': 'i',
  };

  /// Lower case, no accents, disguises undone, repeated letters as one;
  /// what is not a letter becomes a space.
  static String normalizar(String texto) {
    final out = StringBuffer();
    String? anterior;
    for (final ch in texto.toLowerCase().split('')) {
      var c = _acentos[ch] ?? _disfarces[ch] ?? ch;
      if (!RegExp(r'[a-z]').hasMatch(c)) c = ' ';
      if (c == anterior && c != ' ') continue;
      out.write(c);
      anterior = c;
    }
    return out.toString();
  }

  static String _semRepetir(String s) => normalizar(s).replaceAll(' ', '');

  /// Refused anywhere in the name, even glued to other letters.
  static final _trechos = [
    // Português
    'caralh', 'porra', 'merda', 'bosta', 'puta', 'puto', 'viado', 'viadinh',
    'buceta', 'boceta', 'xoxota', 'xereca', 'piroca', 'pirocud',
    'cuzao', 'cuzinh', 'arrombad', 'fodase', 'foder', 'fodid', 'fudid',
    'fuder', 'punhet', 'boquete', 'siririca', 'vagabund', 'piranha',
    'corno', 'otario', 'babaca', 'idiota', 'imbecil', 'retardad',
    'desgracad', 'escrot', 'cacete', 'penis', 'vagina', 'tesao',
    'gozar', 'gozada', 'estupr', 'pedofil', 'nazi', 'hitler',
    'crioul', 'sapatao', 'traveco', 'bichona', 'baitola', 'safad',
    'vadia', 'prostitut', 'maconha', 'cocaina', 'suicid',
    // English
    'fuck', 'shit', 'bitch', 'cunt', 'dick', 'cock', 'pussy', 'asshole',
    'bastard', 'slut', 'whore', 'nigger', 'nigga', 'faggot', 'retard',
    'rapist', 'porn', 'sex', 'penis', 'boob', 'tits', 'wank',
    'jerkoff', 'blowjob', 'handjob', 'dildo', 'jizz', 'twat',
    'suicide', 'terror',
    // Español
    'mierda', 'puta', 'puto', 'pendej', 'cabron', 'cojone',
    'verga', 'polla', 'culo', 'chinga', 'joder', 'jodid', 'marica',
    'maricon', 'zorra', 'perra', 'gilipolla', 'pajer', 'culiad',
    'violar', 'violador', 'hdp',
    // Passing for the game's own staff
    'admin', 'moderador', 'moderator', 'oficial', 'official', 'suporte',
    'support', 'capiblocks', 'chstech',
  ].map(_semRepetir).toSet();

  /// Refused only as a whole word (they are part of harmless words too).
  static final _inteiras = [
    'cu',
    'cus',
    'pau',
    'fdp',
    'pqp',
    'vsf',
    'vtnc',
    'tnc',
    'ass',
    'fag',
    'gay',
    'nazi',
    'kkk',
    'hoe',
    'fap',
    'mod',
    'adm',
    'bot',
  ].map(_semRepetir).toSet();

  /// Harmless words that contain something from [_trechos].
  static final _inocentes = [
    'computa',
    'disputa',
    'reputa',
    'deputad',
    'amputa',
    'imputa',
    'pintor',
    'pintura',
    'pintas',
    'pintad',
    'rolando',
    'rolar',
    'rolad',
    'carola',
    'parola',
    'escola',
    'matara',
    'tomatar',
    'essex',
    'sussex',
    'sexta',
    'sexto',
    'dickens',
    'cockpit',
    'peacock',
    'hancock',
    'scum',
    'cumbia',
    'cumpr',
    'cumple',
    'cumulo',
    'document',
    'acum',
    'cucum',
    'skill',
    'killer',
    'macacao',
    'conoc',
    'econo',
    'icono',
    'cabronz',
    'calculo',
    'curriculo',
    'ridiculo',
    'veiculo',
    'circulo',
    'musculo',
    'articulo',
    'vinculo',
    'obstaculo',
    'espetaculo',
    'titulo',
    'analis',
    'grape',
    'drape',
    'scrape',
    'therap',
    'trapez',
    'corporat',
    'pornic',
    'conchas',
    'pedom',
    'pedol',
    'torpedo',
    'safadao',
  ].map(_semRepetir).toList();

  static bool improprio(String nome) {
    final norm = normalizar(nome);
    final palavras = norm.split(' ').where((p) => p.isNotEmpty).toList();
    if (palavras.any((p) => _inteiras.contains(p) || extras.contains(p))) {
      return true;
    }
    // Letters given one by one ("p u t a") count as one word.
    final juntas = <String>[];
    var solta = '';
    for (final p in palavras) {
      if (p.length == 1) {
        solta += p;
        continue;
      }
      if (solta.isNotEmpty) juntas.add(solta);
      solta = '';
      juntas.add(p);
    }
    if (solta.isNotEmpty) juntas.add(solta);
    for (final p in juntas) {
      if (_inteiras.contains(p)) return true;
      var resto = p;
      for (final ok in _inocentes) {
        resto = resto.replaceAll(ok, ' ');
      }
      if (_trechos.any(resto.contains)) return true;
      if (extras.any((e) => e.length >= 4 && resto.contains(e))) return true;
    }
    return false;
  }
}
