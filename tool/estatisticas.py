"""CapiBlocks numbers from Google Analytics (Firebase), straight in the terminal.

    python tool/estatisticas.py            # last 7 days
    python tool/estatisticas.py 28         # last 28 days
    python tool/estatisticas.py 2026-11-25 2026-11-26
    python tool/estatisticas.py 7 --eventos   # also every event

Reads with the service account capiblocks-estatisticas (Leitor role on the
Analytics property only; it changes nothing). The key stays outside git, in
tool/.ga-estatisticas.json (or the path in GA_CHAVE). See
docs/estatisticas.md. Needs the google-auth and requests packages.
"""
import os
import sys
from datetime import date, timedelta

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PROPRIEDADE = "561834092"
API = f"https://analyticsdata.googleapis.com/v1beta/properties/{PROPRIEDADE}"
CHAVE = os.environ.get(
    "GA_CHAVE", os.path.join(os.path.dirname(__file__), ".ga-estatisticas.json")
)

# The first minute of a new player, in order (see docs/estatisticas.md).
# The share is shown only for the tutorial's own steps.
NO_TUTORIAL = {"primeira_peca", "tutorial_passo", "tutorial_fim", "tutorial_pulado"}

FUNIL = [
    ("first_open", "abriu o app pela 1ª vez"),
    ("abertura", "o jogo apareceu na tela"),
    ("tutorial_begin", "começou o tutorial"),
    ("primeira_peca", "pôs a primeira peça"),
    ("tutorial_passo", "acertou um passo do tutorial"),
    ("tutorial_fim", "terminou o tutorial"),
    ("tutorial_pulado", "pulou o tutorial"),
    ("level_end", "terminou uma fase"),
    ("tutorial_complete", "terminou as fases de introdução"),
]


def _token():
    cred = service_account.Credentials.from_service_account_file(
        CHAVE, scopes=["https://www.googleapis.com/auth/analytics.readonly"]
    )
    cred.refresh(Request())
    return cred.token


def _relatorio(token, corpo):
    r = requests.post(
        f"{API}:runReport",
        headers={"Authorization": f"Bearer {token}"},
        json=corpo,
        timeout=60,
    )
    if r.status_code != 200:
        sys.exit(f"Analytics respondeu {r.status_code}: {r.text[:500]}")
    dados = r.json()
    linhas = []
    for linha in dados.get("rows", []):
        dims = [d["value"] for d in linha.get("dimensionValues", [])]
        mets = [m["value"] for m in linha.get("metricValues", [])]
        linhas.append((dims, mets))
    return linhas


def _tabela(titulo, cabecalho, linhas):
    print(f"\n== {titulo} ==")
    if not linhas:
        print("(sem dados)")
        return
    larg = [
        max(len(str(x)) for x in col) for col in zip(cabecalho, *linhas)
    ]
    for i, linha in enumerate([cabecalho, *linhas]):
        print("  ".join(str(x).ljust(w) for x, w in zip(linha, larg)))
        if i == 0:
            print("  ".join("-" * w for w in larg))


def _min(segundos):
    s = int(float(segundos))
    return f"{s // 60} min {s % 60:02d} s"


def _periodo(args):
    datas = [a for a in args if "-" in a and not a.startswith("--")]
    if len(datas) == 2:
        return datas[0], datas[1]
    numeros = [a for a in args if a.isdigit()]
    dias = int(numeros[0]) if numeros else 7
    hoje = date.today()
    return (hoje - timedelta(days=dias - 1)).isoformat(), hoje.isoformat()


def main(args):
    # Accents on the Windows terminal too.
    sys.stdout.reconfigure(encoding="utf-8")
    inicio, fim = _periodo(args)
    periodo = [{"startDate": inicio, "endDate": fim}]
    token = _token()
    print(f"CapiBlocks: {inicio} a {fim} (Android e iOS juntos)")

    [(_, m)] = _relatorio(token, {
        "dateRanges": periodo,
        "metrics": [
            {"name": "activeUsers"}, {"name": "newUsers"},
            {"name": "sessions"}, {"name": "userEngagementDuration"},
        ],
    }) or [([], ["0", "0", "0", "0"])]
    ativos = int(m[0]) or 1
    _tabela("Resumo", ["ativos", "novos", "sessões", "engajamento/ativo"], [
        [m[0], m[1], m[2], _min(float(m[3]) / ativos)],
    ])

    linhas = _relatorio(token, {
        "dateRanges": periodo,
        "dimensions": [{"name": "eventName"}],
        "metrics": [{"name": "totalUsers"}, {"name": "eventCount"}],
        "dimensionFilter": {"filter": {
            "fieldName": "eventName",
            "inListFilter": {"values": [e for e, _ in FUNIL]},
        }},
    })
    por_evento = {d[0]: (int(mm[0]), int(mm[1])) for d, mm in linhas}
    base = por_evento.get("tutorial_begin", (0, 0))[0]
    _tabela(
        "Primeiro minuto (jogadores; nos passos do tutorial, % de quem o começou)",
        ["evento", "jogadores", "%", "eventos", "o que é"],
        [
            [
                e,
                por_evento.get(e, (0, 0))[0],
                f"{100 * por_evento.get(e, (0, 0))[0] / base:.0f}%"
                if base and e in NO_TUTORIAL
                else "",
                por_evento.get(e, (0, 0))[1],
                texto,
            ]
            for e, texto in FUNIL
        ],
    )

    linhas = _relatorio(token, {
        "dateRanges": periodo,
        "dimensions": [{"name": "firstUserMedium"}],
        "metrics": [
            {"name": "totalUsers"}, {"name": "newUsers"},
            {"name": "userEngagementDuration"}, {"name": "activeUsers"},
        ],
        "orderBys": [{"metric": {"metricName": "totalUsers"}, "desc": True}],
    })
    _tabela("Origem do jogador (cpc = anúncio)", ["origem", "usuários", "novos", "engajamento/ativo"], [
        [d[0], mm[0], mm[1], _min(float(mm[2]) / max(int(mm[3]), 1))]
        for d, mm in linhas
    ])

    linhas = _relatorio(token, {
        "dateRanges": periodo,
        "dimensions": [{"name": "date"}],
        "metrics": [{"name": "activeUsers"}, {"name": "newUsers"}],
        "orderBys": [{"dimension": {"dimensionName": "date"}}],
    })
    _tabela("Por dia", ["dia", "ativos", "novos"], [
        [f"{d[0][6:8]}/{d[0][4:6]}", mm[0], mm[1]] for d, mm in linhas
    ])

    linhas = _relatorio(token, {
        "dateRanges": periodo,
        "dimensions": [{"name": "appVersion"}],
        "metrics": [{"name": "activeUsers"}],
        "orderBys": [{"metric": {"metricName": "activeUsers"}, "desc": True}],
    })
    _tabela("Versão do app", ["versão", "ativos"], [[d[0], mm[0]] for d, mm in linhas])

    _retencao(token, fim)

    if "--eventos" in args:
        linhas = _relatorio(token, {
            "dateRanges": periodo,
            "dimensions": [{"name": "eventName"}],
            "metrics": [{"name": "eventCount"}, {"name": "totalUsers"}],
            "orderBys": [{"metric": {"metricName": "eventCount"}, "desc": True}],
            "limit": 200,
        })
        _tabela("Todos os eventos", ["evento", "eventos", "jogadores"], [
            [d[0], mm[0], mm[1]] for d, mm in linhas
        ])


def _retencao(token, fim):
    """Of the players who arrived on each of the last 7 days, how many came
    back on the next day (D1)."""
    ultimo = date.fromisoformat(fim) - timedelta(days=1)
    coortes = [
        {
            "name": (ultimo - timedelta(days=i)).strftime("%d/%m"),
            "dimension": "firstSessionDate",
            "dateRange": {
                "startDate": (ultimo - timedelta(days=i)).isoformat(),
                "endDate": (ultimo - timedelta(days=i)).isoformat(),
            },
        }
        for i in range(6, -1, -1)
    ]
    linhas = _relatorio(token, {
        "dimensions": [{"name": "cohort"}, {"name": "cohortNthDay"}],
        "metrics": [{"name": "cohortActiveUsers"}],
        "cohortSpec": {
            "cohorts": coortes,
            "cohortsRange": {"granularity": "DAILY", "startOffset": 0, "endOffset": 1},
        },
    })
    dados = {}
    for d, mm in linhas:
        dados.setdefault(d[0], {})[int(d[1])] = int(mm[0])
    tabela = []
    for c in coortes:
        dia0 = dados.get(c["name"], {}).get(0, 0)
        dia1 = dados.get(c["name"], {}).get(1, 0)
        dia = date.fromisoformat(c["dateRange"]["startDate"])
        incompleto = dia + timedelta(days=1) >= date.today()
        tabela.append([
            c["name"], dia0, dia1,
            "dia seguinte ainda não acabou" if incompleto
            else f"{100 * dia1 / dia0:.0f}%" if dia0 else "-",
        ])
    _tabela("Retenção D1 (chegaram no dia; voltaram no dia seguinte)",
            ["chegada", "jogadores", "voltaram", "D1"], tabela)


if __name__ == "__main__":
    main(sys.argv[1:])
