"""Checks the Google Play key without publishing anything.

    python3 tool/play_verificar.py

Opens an edit of com.capiblocks.app with the service account in
PLAY_SERVICE_ACCOUNT_JSON (the secret's contents), reads the tracks and
deletes the edit. Fails if the key or its Play Console permissions are wrong.
Needs the google-auth and requests packages.
"""
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PACOTE = "com.capiblocks.app"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACOTE}"


def main():
    info = json.loads(os.environ["PLAY_SERVICE_ACCOUNT_JSON"])
    cred = service_account.Credentials.from_service_account_info(
        info, scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    cred.refresh(Request())
    h = {"Authorization": f"Bearer {cred.token}"}
    r = requests.post(f"{API}/edits", headers=h, timeout=60)
    if r.status_code != 200:
        sys.exit(f"Não deu para abrir uma edição: {r.status_code} {r.text}")
    edit = r.json()["id"]
    try:
        trilhas = requests.get(f"{API}/edits/{edit}/tracks", headers=h, timeout=60).json()
        for t in trilhas.get("tracks", []):
            for rel in t.get("releases", []):
                print(f"{t['track']}: {rel.get('name', '?')} {rel.get('versionCodes', [])} ({rel.get('status')})")
    finally:
        requests.delete(f"{API}/edits/{edit}", headers=h, timeout=60)
    print(f"Chave ok: {info.get('client_email')} acessa {PACOTE}.")


if __name__ == "__main__":
    main()
