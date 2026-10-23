# Gera a chave de envio (upload key) do CapiBlocks para a Google Play.
# Rode no PowerShell do Windows, na pasta do projeto:
#   powershell -ExecutionPolicy Bypass -File tool\gerar_chave_android.ps1
# Precisa do Java (vem com o Android Studio). Veja docs/publicacao-android.md.

$ErrorActionPreference = 'Stop'

$keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
if (-not $keytool) {
  $studio = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
  if (Test-Path $studio) { $keytool = $studio }
}
if (-not $keytool) {
  Write-Error 'Não achei o keytool. Instale o Android Studio (ou um Java 17) e rode de novo.'
}

$pasta = Join-Path $HOME 'capiblocks-chave'
New-Item -ItemType Directory -Force -Path $pasta | Out-Null
$jks = Join-Path $pasta 'capiblocks-upload.jks'
if (Test-Path $jks) { Write-Error "Já existe uma chave em $jks. Não sobrescrevo." }

$senha = Read-Host 'Escolha uma senha para a chave (mín. 6 caracteres)' -AsSecureString
$texto = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($senha))

& $keytool -genkeypair -v -keystore $jks -alias upload -keyalg RSA -keysize 2048 `
  -validity 10000 -storepass $texto -keypass $texto `
  -dname 'CN=CapiBlocks, O=CapiBlocks, C=BR'

[Convert]::ToBase64String([IO.File]::ReadAllBytes($jks)) |
  Set-Content -NoNewline (Join-Path $pasta 'capiblocks-upload.base64.txt')

Write-Host ''
Write-Host "Pronto! Chave em: $jks"
Write-Host 'GUARDE este arquivo e a senha num lugar seguro (ex.: gerenciador de senhas + backup).'
Write-Host 'Agora cadastre os 4 segredos no GitHub (veja docs/publicacao-android.md):'
Write-Host "  CAPI_KEYSTORE_BASE64 = conteúdo de $pasta\capiblocks-upload.base64.txt"
Write-Host '  CAPI_KEYSTORE_PASSWORD = a senha'
Write-Host '  CAPI_KEY_PASSWORD = a mesma senha'
Write-Host '  CAPI_KEY_ALIAS = upload'
