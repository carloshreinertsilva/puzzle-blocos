# Publicação Android (Google Play)

## Identificador do app

`com.capiblocks.app` (Android `applicationId` e iOS bundle id). **Nunca mude
depois do primeiro envio à Play Store**: para a loja, outro identificador é
outro app.

## Chave de envio (upload key)

A Play Store exige que o pacote (.aab) seja assinado com uma chave sua. Com a
"Assinatura de apps do Google Play" (padrão), a Google guarda a chave final e
você só usa a *chave de envio*; se ela se perder, dá para pedir a troca ao
suporte, mas dá trabalho. Guarde bem.

1. Instale o Android Studio (traz o Java/keytool).
2. Na pasta do projeto, no PowerShell:
   `powershell -ExecutionPolicy Bypass -File tool\gerar_chave_android.ps1`
3. Guarde `%USERPROFILE%\capiblocks-chave\capiblocks-upload.jks` e a senha
   (gerenciador de senhas + uma cópia de segurança). **Não** coloque no
   repositório (o `.gitignore` já bloqueia `*.jks`).
4. No GitHub: *Settings → Secrets and variables → Actions → New repository
   secret*, crie:
   - `CAPI_KEYSTORE_BASE64`: conteúdo de `capiblocks-upload.base64.txt`
   - `CAPI_KEYSTORE_PASSWORD`: a senha
   - `CAPI_KEY_PASSWORD`: a mesma senha
   - `CAPI_KEY_ALIAS`: `upload`

Pronto: a cada push, o job **Android (.aab)** do CI gera
`capiblocks-aab` (aba *Actions* → execução → *Artifacts*), já assinado e pronto
para subir na Play Console. Sem os segredos, o job só confirma que o app
compila (assinado com chave de teste, que a loja recusa).

## Build no seu computador (opcional)

Crie `android/key.properties` (fora do git):

```
storeFile=C:/Users/<você>/capiblocks-chave/capiblocks-upload.jks
storePassword=<senha>
keyAlias=upload
keyPassword=<senha>
```

e rode `flutter build appbundle --release`.

## Versão

`version: 1.0.0+1` no `pubspec.yaml`: o número depois do `+` (versionCode)
precisa subir a cada envio à loja.
