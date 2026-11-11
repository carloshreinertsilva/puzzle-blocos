"""Envia clipes do jogo para a caixa de entrada do TikTok (@_capiblocks).

Usa a Content Posting API no modo rascunho: o vídeo chega nas notificações
do app do TikTok e a conta escolhe a música e publica por lá. Só a
biblioteca padrão do Python.

Chaves (variáveis de ambiente ou o arquivo tool/.tiktok.env, fora do git):
  TIKTOK_CLIENT_KEY, TIKTOK_CLIENT_SECRET  do app em developers.tiktok.com
  TIKTOK_REFRESH_TOKEN                     sai do passo "codigo" (vale 1 ano)

Uso:
  python tool/tiktok.py link              # link para autorizar a conta (uma vez)
  python tool/tiktok.py codigo "<URL>"    # cola a URL para onde o TikTok voltou
  python tool/tiktok.py codigo "<URL>" --github   # e grava o token nos Secrets
  python tool/tiktok.py eu                # confere a conexão (nome da conta)
  python tool/tiktok.py enviar a.mp4 [b.mp4 ...]
"""

import json
import math
import os
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://open.tiktokapis.com"
AUTORIZAR = "https://www.tiktok.com/v2/auth/authorize/"
# Precisa ser exatamente a URL cadastrada no app do TikTok (Login Kit).
VOLTA = os.environ.get("TIKTOK_REDIRECT_URI", "https://capiblocks.vercel.app/")
ESCOPOS = "user.info.basic,video.upload"
ARQUIVO = Path(__file__).with_name(".tiktok.env")

MB = 1024 * 1024


def chaves() -> dict:
    valores = {}
    if ARQUIVO.exists():
        for linha in ARQUIVO.read_text(encoding="utf-8").splitlines():
            if "=" in linha and not linha.lstrip().startswith("#"):
                k, v = linha.split("=", 1)
                valores[k.strip()] = v.strip()
    for k in ("TIKTOK_CLIENT_KEY", "TIKTOK_CLIENT_SECRET", "TIKTOK_REFRESH_TOKEN"):
        if os.environ.get(k):
            valores[k] = os.environ[k]
    return valores


def guardar(chave: str, valor: str) -> None:
    linhas = []
    if ARQUIVO.exists():
        linhas = [
            l for l in ARQUIVO.read_text(encoding="utf-8").splitlines()
            if not l.startswith(chave + "=")
        ]
    linhas.append(f"{chave}={valor}")
    ARQUIVO.write_text("\n".join(linhas) + "\n", encoding="utf-8")


def exigir(c: dict, *nomes: str) -> None:
    faltam = [n for n in nomes if not c.get(n)]
    if faltam:
        sys.exit(f"Faltam as chaves: {', '.join(faltam)} (em {ARQUIVO} ou no ambiente).")


def pedir(metodo: str, url: str, corpo=None, token=None, form=False, cabecalhos=None):
    h = dict(cabecalhos or {})
    dados = None
    if form:
        h["Content-Type"] = "application/x-www-form-urlencoded"
        dados = urllib.parse.urlencode(corpo).encode()
    elif isinstance(corpo, (bytes, bytearray)):
        dados = bytes(corpo)
    elif corpo is not None:
        h["Content-Type"] = "application/json; charset=UTF-8"
        dados = json.dumps(corpo).encode()
    if token:
        h["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=dados, headers=h, method=metodo)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            texto = r.read().decode() or "{}"
    except urllib.error.HTTPError as e:
        texto = e.read().decode() or "{}"
        try:
            erro = json.loads(texto)
        except ValueError:
            sys.exit(f"Erro {e.code} em {url}: {texto[:300]}")
        sys.exit(f"Erro {e.code} em {url}: {json.dumps(erro.get('error', erro), ensure_ascii=False)}")
    return json.loads(texto) if texto.strip().startswith("{") else {}


def token_de_acesso(c: dict) -> str:
    """Troca o refresh token por um token de acesso (vale 24 h)."""
    exigir(c, "TIKTOK_CLIENT_KEY", "TIKTOK_CLIENT_SECRET", "TIKTOK_REFRESH_TOKEN")
    r = pedir("POST", f"{API}/v2/oauth/token/", {
        "client_key": c["TIKTOK_CLIENT_KEY"],
        "client_secret": c["TIKTOK_CLIENT_SECRET"],
        "grant_type": "refresh_token",
        "refresh_token": c["TIKTOK_REFRESH_TOKEN"],
    }, form=True)
    if "access_token" not in r:
        sys.exit(f"O TikTok recusou o refresh token: {r.get('error_description') or r}")
    novo = r.get("refresh_token")
    if novo and novo != c["TIKTOK_REFRESH_TOKEN"]:
        if ARQUIVO.exists() and not os.environ.get("TIKTOK_REFRESH_TOKEN"):
            guardar("TIKTOK_REFRESH_TOKEN", novo)
        else:
            print("Aviso: o TikTok trocou o refresh token; rode o passo 'codigo' de novo se ele parar de valer.")
    return r["access_token"]


def link() -> None:
    c = chaves()
    exigir(c, "TIKTOK_CLIENT_KEY")
    q = urllib.parse.urlencode({
        "client_key": c["TIKTOK_CLIENT_KEY"],
        "scope": ESCOPOS,
        "response_type": "code",
        "redirect_uri": VOLTA,
        "state": secrets.token_urlsafe(12),
    })
    print("Abra este link logado na conta @_capiblocks e autorize:\n")
    print(f"{AUTORIZAR}?{q}\n")
    print("Depois copie a URL inteira da página para onde o TikTok voltar e rode:")
    print('  python tool/tiktok.py codigo "<URL>"')


def codigo(colado: str, github: bool) -> None:
    c = chaves()
    exigir(c, "TIKTOK_CLIENT_KEY", "TIKTOK_CLIENT_SECRET")
    if "code=" in colado:
        params = urllib.parse.parse_qs(urllib.parse.urlparse(colado).query)
        if "error" in params:
            sys.exit(f"O TikTok não autorizou: {params.get('error_description', params['error'])[0]}")
        cod = params["code"][0]
    else:
        cod = urllib.parse.unquote(colado)
    r = pedir("POST", f"{API}/v2/oauth/token/", {
        "client_key": c["TIKTOK_CLIENT_KEY"],
        "client_secret": c["TIKTOK_CLIENT_SECRET"],
        "code": cod,
        "grant_type": "authorization_code",
        "redirect_uri": VOLTA,
    }, form=True)
    if "refresh_token" not in r:
        sys.exit(f"Não deu para trocar o código: {r.get('error_description') or r}")
    print(f"Autorizado. Escopos: {r.get('scope')}. O refresh token vale {r.get('refresh_expires_in', 0) // 86400} dias.")
    guardar("TIKTOK_REFRESH_TOKEN", r["refresh_token"])
    print(f"Refresh token guardado em {ARQUIVO}.")
    if github:
        subprocess.run(["gh", "secret", "set", "TIKTOK_REFRESH_TOKEN"], input=r["refresh_token"].encode(), check=True)
        print("E nos Secrets do GitHub (TIKTOK_REFRESH_TOKEN).")


def eu() -> None:
    token = token_de_acesso(chaves())
    r = pedir("GET", f"{API}/v2/user/info/?fields=open_id,display_name", token=token)
    usuario = r.get("data", {}).get("user", {})
    print(f"Conectado como: {usuario.get('display_name')} ({usuario.get('open_id')})")


def enviar(arquivos: list) -> None:
    token = token_de_acesso(chaves())
    for nome in arquivos:
        caminho = Path(nome)
        tamanho = caminho.stat().st_size
        # Até 64 MB vai num pedaço só; acima, pedaços de 10 MB (o último
        # leva a sobra). Regras do TikTok: 5 a 64 MB por pedaço.
        pedaco = tamanho if tamanho <= 64 * MB else 10 * MB
        total = max(1, math.floor(tamanho / pedaco))
        r = pedir("POST", f"{API}/v2/post/publish/inbox/video/init/", {
            "source_info": {
                "source": "FILE_UPLOAD",
                "video_size": tamanho,
                "chunk_size": pedaco,
                "total_chunk_count": total,
            },
        }, token=token)
        dados = r.get("data", {})
        if "upload_url" not in dados:
            sys.exit(f"{caminho.name}: o TikTok não aceitou o envio: {r.get('error')}")
        tipo = {".mov": "video/quicktime", ".webm": "video/webm"}.get(caminho.suffix.lower(), "video/mp4")
        with caminho.open("rb") as f:
            for i in range(total):
                inicio = i * pedaco
                fim = tamanho - 1 if i == total - 1 else inicio + pedaco - 1
                f.seek(inicio)
                corpo = f.read(fim - inicio + 1)
                pedir("PUT", dados["upload_url"], corpo, cabecalhos={
                    "Content-Type": tipo,
                    "Content-Range": f"bytes {inicio}-{fim}/{tamanho}",
                })
        estado = esperar(token, dados["publish_id"])
        print(f"{caminho.name}: {estado}")


def esperar(token: str, publish_id: str) -> str:
    for _ in range(60):
        r = pedir("POST", f"{API}/v2/post/publish/status/fetch/", {"publish_id": publish_id}, token=token)
        d = r.get("data", {})
        status = d.get("status")
        if status == "SEND_TO_USER_INBOX":
            return "na caixa de entrada do TikTok (abra o app para publicar)"
        if status == "PUBLISH_COMPLETE":
            return "publicado"
        if status == "FAILED":
            return f"falhou ({d.get('fail_reason')})"
        time.sleep(5)
    return "ainda processando (confira no app daqui a pouco)"


def main() -> None:
    # Acentos certos no terminal do Windows.
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    cmd = args[0]
    if cmd == "link":
        link()
    elif cmd == "codigo" and len(args) >= 2:
        codigo(args[1], "--github" in args)
    elif cmd == "eu":
        eu()
    elif cmd == "enviar" and len(args) >= 2:
        enviar(args[1:])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
