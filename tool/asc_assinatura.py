"""Signing for the TestFlight workflow (.github/workflows/testflight.yml).

    python3 tool/asc_assinatura.py criar <pasta>
    python3 tool/asc_assinatura.py revogar <pasta>

`criar` makes a fresh key and, through the App Store Connect API, an Apple
Distribution certificate and an App Store profile named "CapiBlocks CI" for
com.capiblocks.app (the Release build of ios/Runner is set to sign with
them). It writes key.pem, cert.der, perfil.mobileprovision and ids.txt to
<pasta>. `revogar` revokes that certificate and deletes the profile once the
build is uploaded: no private key outlives the run, and builds already sent
are not affected (Apple re-signs them).

Needs ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (the .p8 file), and the
PyJWT and cryptography packages.
"""
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

API = "https://api.appstoreconnect.apple.com/v1"
BUNDLE = "com.capiblocks.app"
PERFIL = "CapiBlocks CI"


def _token():
    with open(os.environ["ASC_KEY_PATH"]) as f:
        chave = f.read()
    agora = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": agora, "exp": agora + 900, "aud": "appstoreconnect-v1"},
        chave,
        algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"},
    )


def _api(metodo, caminho, corpo=None):
    req = urllib.request.Request(
        API + caminho,
        method=metodo,
        data=json.dumps(corpo).encode() if corpo is not None else None,
        headers={"Authorization": "Bearer " + _token(), "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as r:
            texto = r.read()
    except urllib.error.HTTPError as e:
        sys.exit(f"App Store Connect: {metodo} {caminho}: {e.code} {e.read().decode()}")
    return json.loads(texto) if texto else None


def _apagar_perfis():
    for p in _api("GET", f"/profiles?filter[name]={urllib.parse.quote(PERFIL)}&limit=200")["data"]:
        _api("DELETE", f"/profiles/{p['id']}")


def criar(pasta):
    os.makedirs(pasta, exist_ok=True)
    chave = os.path.join(pasta, "key.pem")
    csr = os.path.join(pasta, "pedido.csr")
    subprocess.run(["openssl", "genrsa", "-out", chave, "2048"], check=True, capture_output=True)
    subprocess.run(
        ["openssl", "req", "-new", "-key", chave, "-out", csr, "-subj", "/CN=CapiBlocks CI/O=CHS/C=BR"],
        check=True,
        capture_output=True,
    )
    with open(csr) as f:
        pedido = f.read()
    cert = _api(
        "POST",
        "/certificates",
        {"data": {"type": "certificates", "attributes": {"certificateType": "DISTRIBUTION", "csrContent": pedido}}},
    )["data"]
    with open(os.path.join(pasta, "cert.der"), "wb") as f:
        f.write(base64.b64decode(cert["attributes"]["certificateContent"]))

    bundles = _api("GET", f"/bundleIds?filter[identifier]={BUNDLE}")["data"]
    bundle = next(b for b in bundles if b["attributes"]["identifier"] == BUNDLE)
    _apagar_perfis()
    perfil = _api(
        "POST",
        "/profiles",
        {
            "data": {
                "type": "profiles",
                "attributes": {"name": PERFIL, "profileType": "IOS_APP_STORE"},
                "relationships": {
                    "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}},
                    "certificates": {"data": [{"type": "certificates", "id": cert["id"]}]},
                },
            }
        },
    )["data"]
    with open(os.path.join(pasta, "perfil.mobileprovision"), "wb") as f:
        f.write(base64.b64decode(perfil["attributes"]["profileContent"]))
    with open(os.path.join(pasta, "ids.txt"), "w") as f:
        f.write(cert["id"])
    os.remove(csr)
    print("certificado e perfil criados")


def revogar(pasta):
    ids = os.path.join(pasta, "ids.txt")
    if os.path.exists(ids):
        with open(ids) as f:
            _api("DELETE", f"/certificates/{f.read().strip()}")
        print("certificado revogado")
    _apagar_perfis()


if __name__ == "__main__":
    {"criar": criar, "revogar": revogar}[sys.argv[1]](sys.argv[2])
