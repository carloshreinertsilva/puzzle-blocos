# Skills deste projeto

Instaladas aqui (e não na máquina) para valerem em qualquer sessão do Claude
Code neste repositório. Cada pasta mantém a licença original.

| Skill | Origem | Licença | Para quê |
|---|---|---|---|
| `grill-me` / `grilling` | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT | Entrevista em rodadas para fechar um plano antes de implementar (`/grill-me`) |
| `find-skills` | [vercel-labs/skills](https://github.com/vercel-labs/skills) | MIT | Procurar e avaliar outras skills no ecossistema (`npx skills find`) |
| `frontend-design` | [anthropics/skills](https://github.com/anthropics/skills) | Apache 2.0 | Direção visual distinta (tipografia, cores, layout) para telas e páginas |
| `ui-ux-pro-max` | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | MIT | Base local de estilos, paletas, fontes e regras de UX, com regras para Flutter. Caminho do script ajustado para `$CLAUDE_PROJECT_DIR` |

Proteção de git: `.claude/hooks/block-dangerous-git.sh` (ligada em
`.claude/settings.json`), adaptada de `git-guardrails-claude-code`
(mattpocock/skills, MIT). Bloqueia push forçado, `reset --hard`, `clean -f`,
`branch -D`, `checkout .`, `restore .` e `stash drop/clear`. O `git push`
normal continua liberado.

Avaliadas e não instaladas:

- **Vercel React Best Practices** e **Vercel Composition Patterns**: só para
  React/Next.js; o jogo é Flutter.
- **Vercel Web Design Guidelines** e **Impeccable**: revisam HTML/CSS; o
  Flutter desenha num canvas, então quase nada se aplicaria. Úteis se
  fizermos um site (página da loja, política de privacidade).
- **GSD** e **Planning with Files**: frameworks de fluxo de trabalho que se
  sobrepõem ao Superpowers (abaixo). O GSD original foi arquivado (mudou para
  open-gsd/gsd-core) e o Planning with Files adiciona ganchos que rodam a cada
  ação.

Plugin habilitado em `.claude/settings.json`: **Superpowers**
([obra/superpowers](https://github.com/obra/superpowers), MIT), via o
marketplace `obra/superpowers-marketplace`. Traz brainstorming, planos,
desenvolvimento orientado a testes, depuração sistemática e revisão de código.
O Claude Code oferece instalar o plugin ao abrir o projeto (é preciso confiar
na pasta). Para instalar à mão: `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install
superpowers@superpowers-marketplace`.
