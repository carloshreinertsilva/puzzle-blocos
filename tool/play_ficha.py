"""Updates the Play Store listing (texts, icon, banner and screenshots) from
docs/loja/play/, without a new version. Uses the service account in
PLAY_SERVICE_ACCOUNT_JSON. Needs the google-auth and requests packages.

    python3 tool/play_ficha.py            # only checks the files
    python3 tool/play_ficha.py --enviar   # sends them to the Play Store

docs/loja/play/textos.json has, per language (pt-BR, en-US, es-419), the
title, short and full description; docs/loja/play/<pt|en|es>/ has the
screenshots (*.jpg, in name order) and banner-1024x500.png; the icon is
docs/loja/play/icone-512.png. With YOUTUBE set, its link is the listing's video.
"""
import json
import os
import sys
from pathlib import Path

PACOTE = "com.capiblocks.app"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACOTE}"
UPLOAD = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACOTE}"
PASTA = Path(__file__).resolve().parent.parent / "docs" / "loja" / "play"
IDIOMAS = {"pt-BR": "pt", "en-US": "en", "es-419": "es"}


def _ficha():
    textos = json.loads((PASTA / "textos.json").read_text(encoding="utf-8"))
    icone = PASTA / "icone-512.png"
    erros, fichas = [], {}
    if not icone.exists():
        erros.append("falta icone-512.png")
    for idioma, pasta in IDIOMAS.items():
        t = textos[idioma]
        for campo, limite in (("titulo", 30), ("curta", 80), ("completa", 4000)):
            if len(t[campo]) > limite:
                erros.append(f"{idioma}: {campo} com {len(t[campo])} (máximo {limite})")
        capturas = sorted((PASTA / pasta).glob("*.jpg"))
        if not 2 <= len(capturas) <= 8:
            erros.append(f"{idioma}: {len(capturas)} capturas (de 2 a 8)")
        banner = PASTA / pasta / "banner-1024x500.png"
        if not banner.exists():
            erros.append(f"{idioma}: falta o banner")
        fichas[idioma] = (t, capturas, banner)
    if erros:
        sys.exit("Ficha com problemas:\n  " + "\n  ".join(erros))
    return fichas, icone


def _sessao():
    import requests
    from google.auth.transport.requests import Request
    from google.oauth2 import service_account

    info = json.loads(os.environ["PLAY_SERVICE_ACCOUNT_JSON"])
    cred = service_account.Credentials.from_service_account_info(
        info, scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    cred.refresh(Request())
    s = requests.Session()
    s.headers["Authorization"] = f"Bearer {cred.token}"
    return s


def _ok(r, o_que):
    if r.status_code >= 300:
        sys.exit(f"{o_que}: {r.status_code} {r.text}")
    return r.json() if r.text else {}


def _imagem(s, edit, idioma, tipo, arquivo):
    mime = "image/png" if arquivo.suffix == ".png" else "image/jpeg"
    _ok(
        s.post(
            f"{UPLOAD}/edits/{edit}/listings/{idioma}/{tipo}",
            params={"uploadType": "media"},
            data=arquivo.read_bytes(),
            headers={"Content-Type": mime},
            timeout=120,
        ),
        f"{idioma}: enviar {arquivo.name}",
    )


def main():
    fichas, icone = _ficha()
    for idioma, (t, capturas, _) in fichas.items():
        print(f"{idioma}: {t['titulo']!r}, {len(capturas)} capturas")
    if "--enviar" not in sys.argv:
        print("Tudo certo (nada enviado; use --enviar).")
        return
    video = os.environ.get("YOUTUBE", "").strip()
    s = _sessao()
    edit = _ok(s.post(f"{API}/edits", timeout=60), "abrir edição")["id"]
    try:
        for idioma, (t, capturas, banner) in fichas.items():
            ficha = {
                "language": idioma,
                "title": t["titulo"],
                "shortDescription": t["curta"],
                "fullDescription": t["completa"],
            }
            if video:
                ficha["video"] = video
            _ok(
                s.put(f"{API}/edits/{edit}/listings/{idioma}", json=ficha, timeout=60),
                f"{idioma}: textos",
            )
            for tipo in ("phoneScreenshots", "featureGraphic", "icon"):
                _ok(
                    s.delete(f"{API}/edits/{edit}/listings/{idioma}/{tipo}", timeout=60),
                    f"{idioma}: apagar {tipo}",
                )
            for c in capturas:
                _imagem(s, edit, idioma, "phoneScreenshots", c)
            _imagem(s, edit, idioma, "featureGraphic", banner)
            _imagem(s, edit, idioma, "icon", icone)
            print(f"{idioma}: enviado")
        _ok(s.post(f"{API}/edits/{edit}:commit", timeout=60), "confirmar edição")
        edit = None
        print("Ficha atualizada na Play Store.")
    finally:
        if edit:
            s.delete(f"{API}/edits/{edit}", timeout=60)


if __name__ == "__main__":
    main()
