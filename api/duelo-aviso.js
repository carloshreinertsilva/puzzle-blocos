// Avisa um jogador, por notificação no celular, que algo aconteceu num
// duelo (lib/services/duelo_aviso.dart chama esta função):
//
// - tipo "resposta": um amigo jogou o desafio dele (ou melhorou a
//   pontuação). `id` é a resposta (respostas/{duelo}_{uid}), de quem chama.
// - tipo "revanche": quem chama desafiou de volta um amigo que já tinha
//   jogado um desafio seu. `id` é o desafio novo (duelos/{id}, com `para` e
//   `origem`).
//
// Quem chama manda o token de login do Firebase (anônimo, o mesmo do
// ranking); a função confere tudo no Firestore antes de avisar, e avisa uma
// vez por pontuação (avisos/{id}). O endereço de notificação de cada
// jogador fica em aparelhos/{uid} (o jogo grava).
//
// Usa a conta de serviço do Firebase na variável FIREBASE_SERVICE_ACCOUNT
// (o JSON inteiro), configurada na Vercel. Sem dependências: só Node.
const crypto = require('crypto');

const PROJETO = 'capiblocks';
const FIRESTORE = `https://firestore.googleapis.com/v1/projects/${PROJETO}/databases/(default)/documents`;

const TEXTOS = {
  pt: {
    passou: (n, p, m) => [`${n} passou você!`, `${p} × ${m} no seu desafio. Bora revanche?`],
    jogou: (n, p, m) => [`${n} jogou seu desafio`, `Você venceu: ${m} × ${p}.`],
    revanche: (n, m) => [`${n} te desafiou de volta!`, `Faça mais de ${m} pontos para vencer.`],
  },
  en: {
    passou: (n, p, m) => [`${n} beat you!`, `${p} × ${m} on your challenge. Rematch?`],
    jogou: (n, p, m) => [`${n} played your challenge`, `You won: ${m} × ${p}.`],
    revanche: (n, m) => [`${n} challenged you back!`, `Score more than ${m} points to win.`],
  },
  es: {
    passou: (n, p, m) => [`¡${n} te superó!`, `${p} × ${m} en tu desafío. ¿Revancha?`],
    jogou: (n, p, m) => [`${n} jugó tu desafío`, `Ganaste: ${m} × ${p}.`],
    revanche: (n, m) => [`¡${n} te desafió de vuelta!`, `Haz más de ${m} puntos para ganar.`],
  },
};

const num = (n) => Number(n).toLocaleString('pt-BR');

// --- Login de quem chama (token do Firebase Auth) ---

let certificados = { ate: 0, pem: {} };

async function chavesDoGoogle() {
  if (Date.now() < certificados.ate) return certificados.pem;
  const r = await fetch(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
  );
  const idade = /max-age=(\d+)/.exec(r.headers.get('cache-control') || '');
  certificados = {
    ate: Date.now() + (idade ? Number(idade[1]) * 1000 : 3600000),
    pem: await r.json(),
  };
  return certificados.pem;
}

const b64url = (s) => Buffer.from(s, 'base64url');

/** O uid de quem chama, ou null se o token não vale. */
async function uidDoToken(token) {
  if (typeof token !== 'string') return null;
  const partes = token.split('.');
  if (partes.length !== 3) return null;
  let cabeca, corpo;
  try {
    cabeca = JSON.parse(b64url(partes[0]).toString());
    corpo = JSON.parse(b64url(partes[1]).toString());
  } catch {
    return null;
  }
  if (cabeca.alg !== 'RS256') return null;
  const pem = (await chavesDoGoogle())[cabeca.kid];
  if (!pem) return null;
  const ok = crypto
    .createVerify('RSA-SHA256')
    .update(`${partes[0]}.${partes[1]}`)
    .verify(pem, b64url(partes[2]));
  const agora = Date.now() / 1000;
  if (
    !ok ||
    corpo.aud !== PROJETO ||
    corpo.iss !== `https://securetoken.google.com/${PROJETO}` ||
    !(corpo.exp > agora) ||
    typeof corpo.sub !== 'string' ||
    !corpo.sub
  ) {
    return null;
  }
  return corpo.sub;
}

// --- Acesso de servidor (conta de serviço) ---

let acesso = { ate: 0, token: null };

async function tokenDeServidor() {
  if (Date.now() < acesso.ate) return acesso.token;
  const conta = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  const agora = Math.floor(Date.now() / 1000);
  const enc = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const dados = `${enc({ alg: 'RS256', typ: 'JWT' })}.${enc({
    iss: conta.client_email,
    scope:
      'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: agora,
    exp: agora + 3600,
  })}`;
  const assinatura = crypto
    .createSign('RSA-SHA256')
    .update(dados)
    .sign(conta.private_key)
    .toString('base64url');
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${dados}.${assinatura}`,
    }),
  });
  const j = await r.json();
  if (!j.access_token) throw new Error(`token: ${r.status}`);
  acesso = { ate: Date.now() + 50 * 60 * 1000, token: j.access_token };
  return acesso.token;
}

/** Um documento do Firestore como objeto simples, ou null. */
async function ler(caminho) {
  const r = await fetch(`${FIRESTORE}/${caminho}`, {
    headers: { Authorization: `Bearer ${await tokenDeServidor()}` },
  });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error(`ler ${caminho}: ${r.status}`);
  const campos = (await r.json()).fields || {};
  const o = {};
  for (const [k, v] of Object.entries(campos)) {
    o[k] = v.stringValue ?? v.booleanValue ?? (v.integerValue != null ? Number(v.integerValue) : v.doubleValue);
  }
  return o;
}

async function gravar(caminho, campos) {
  const fields = {};
  for (const [k, v] of Object.entries(campos)) {
    fields[k] = typeof v === 'number' ? { integerValue: String(v) } : { stringValue: String(v) };
  }
  const r = await fetch(`${FIRESTORE}/${caminho}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${await tokenDeServidor()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });
  if (!r.ok) throw new Error(`gravar ${caminho}: ${r.status}`);
}

/** Manda a notificação ao celular de [uid]. Diz se foi entregue ao Firebase. */
async function notificar(uid, montar, rota) {
  const aparelho = await ler(`aparelhos/${uid}`);
  if (!aparelho || !aparelho.token) return false;
  const [title, body] = montar(TEXTOS[aparelho.idioma] || TEXTOS.pt);
  const r = await fetch(`https://fcm.googleapis.com/v1/projects/${PROJETO}/messages:send`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${await tokenDeServidor()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: aparelho.token,
        notification: { title, body },
        data: { rota },
        android: {
          priority: 'high',
          notification: { channel_id: 'duelos', icon: 'ic_notificacao', color: '#FFC94D' },
        },
      },
    }),
  });
  return r.ok;
}

const ID = /^[A-Za-z0-9_]{1,90}$/;

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ ok: false });
  try {
    const { token, tipo, id } = req.body || {};
    const uid = await uidDoToken(token);
    if (!uid) return res.status(401).json({ ok: false });
    if (typeof id !== 'string' || !ID.test(id)) return res.status(400).json({ ok: false });

    if (tipo === 'resposta') {
      const r = await ler(`respostas/${id}`);
      if (!r || r.uid !== uid || id !== `${r.duelo}_${uid}`) {
        return res.status(403).json({ ok: false });
      }
      const aviso = await ler(`avisos/${id}`);
      if (aviso && aviso.pontos >= r.pontos) return res.json({ ok: true, repetido: true });
      await gravar(`avisos/${id}`, { pontos: r.pontos });
      const passou = r.pontos > r.meta;
      const enviado = await notificar(
        r.dono,
        (t) => (passou ? t.passou : t.jogou)(r.nome, num(r.pontos), num(r.meta)),
        '/',
      );
      return res.json({ ok: true, enviado });
    }

    if (tipo === 'revanche') {
      const d = await ler(`duelos/${id}`);
      if (!d || d.dono !== uid || !d.para || !d.origem) {
        return res.status(403).json({ ok: false });
      }
      // Só dá para desafiar de volta quem já jogou um desafio seu.
      const antes = await ler(`respostas/${d.origem}_${d.para}`);
      if (!antes || antes.dono !== uid) return res.status(403).json({ ok: false });
      if (await ler(`avisos/r_${id}`)) return res.json({ ok: true, repetido: true });
      await gravar(`avisos/r_${id}`, { pontos: d.pontos });
      const rota =
        `/duelo?s=${d.semente}&p=${d.pontos}&d=${id}&n=${encodeURIComponent(d.nome)}` +
        (d.blitz ? '&m=blitz' : '');
      const enviado = await notificar(d.para, (t) => t.revanche(d.nome, num(d.pontos)), rota);
      return res.json({ ok: true, enviado });
    }

    return res.status(400).json({ ok: false });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ ok: false });
  }
};
