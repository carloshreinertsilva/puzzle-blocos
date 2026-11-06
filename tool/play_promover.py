"""Promotes the release on one Google Play track to another, without
building or uploading again (a version code can only be uploaded once).

    python3 tool/play_promover.py <de> <para> [porcentagem]

e.g. `internal production 1`: the build being tested internally goes to
production, with its release notes, for everyone (or for a fraction, like
0.1 for 10%, as a staged rollout). Uses the service account in
PLAY_SERVICE_ACCOUNT_JSON. Needs the google-auth and requests packages.
"""
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PACOTE = "com.capiblocks.app"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACOTE}"


def _sessao():
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


def main():
    de, para = sys.argv[1], sys.argv[2]
    fracao = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
    s = _sessao()
    edit = _ok(s.post(f"{API}/edits", timeout=60), "abrir edição")["id"]
    try:
        origem = _ok(s.get(f"{API}/edits/{edit}/tracks/{de}", timeout=60), f"ler {de}")
        lancadas = [r for r in origem.get("releases", []) if r.get("status") == "completed"]
        if not lancadas:
            sys.exit(f"Nada publicado em {de} para promover.")
        rel = max(lancadas, key=lambda r: max(int(v) for v in r["versionCodes"]))
        nova = {
            "name": rel.get("name"),
            "versionCodes": rel["versionCodes"],
            "releaseNotes": rel.get("releaseNotes", []),
            "status": "completed" if fracao >= 1 else "inProgress",
        }
        if fracao < 1:
            nova["userFraction"] = fracao
        _ok(
            s.put(
                f"{API}/edits/{edit}/tracks/{para}",
                json={"track": para, "releases": [nova]},
                timeout=60,
            ),
            f"atualizar {para}",
        )
        _ok(s.post(f"{API}/edits/{edit}:commit", timeout=60), "confirmar edição")
        edit = None
        print(f"{rel.get('name')} {rel['versionCodes']}: {de} → {para} ({fracao:.0%}).")
    finally:
        if edit:
            s.delete(f"{API}/edits/{edit}", timeout=60)


if __name__ == "__main__":
    main()
