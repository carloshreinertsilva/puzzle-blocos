# Regras do Firestore (convites de amigos)

`../../firestore.rules` são as regras publicadas no console do Firebase
(projeto `capiblocks`). Para testar uma mudança antes de publicar, com Java
instalado:

```
cd tool/firestore
npm install
npm test
```

O teste sobe o emulador do Firestore e confere, com jogadores fictícios,
quem pode criar códigos e convites, marcar a fase 5 e contar amigos.
Toda linha deve sair `OK`.
