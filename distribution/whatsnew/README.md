# Notas da versão (Google Play)

O texto de "O que há de novo" que o workflow **Android: Play Store** envia
junto com cada versão. Um arquivo por idioma da ficha da loja
(`whatsnew-<idioma>`), até 500 caracteres. Atualize antes de cada envio.

A ficha tem três idiomas (`pt-BR`, `en-US` e `es-419`, enviados por
`tool/play_ficha.py`), e há um arquivo de notas para cada um. Antes de
acrescentar outro idioma, confirme que a ficha da Play Store o tem: a API
recusa notas num idioma que a ficha não tem.
