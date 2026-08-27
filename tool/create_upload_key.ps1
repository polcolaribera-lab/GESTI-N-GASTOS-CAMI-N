$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$androidDirectory = Join-Path $workspaceRoot "android"
$documentsDirectory = [Environment]::GetFolderPath("MyDocuments")
$keyDirectory = Join-Path $documentsDirectory "RutaClara-claves"
$keyStorePath = Join-Path $keyDirectory "ruta-clara-upload.jks"
$certificatePath = Join-Path $keyDirectory "ruta-clara-upload-certificate.pem"
$credentialsPath = Join-Path $keyDirectory "LEEME-CREDENCIALES-FIRMA.txt"
$keyPropertiesPath = Join-Path $androidDirectory "key.properties"
$keyAlias = "ruta-clara-upload"

if (-not (Test-Path -LiteralPath (Join-Path $workspaceRoot "pubspec.yaml") -PathType Leaf)) {
    throw "No se ha encontrado la raiz del proyecto Flutter."
}

$existingFiles = @(
    $keyStorePath,
    $certificatePath,
    $credentialsPath,
    $keyPropertiesPath
) | Where-Object { Test-Path -LiteralPath $_ }

if ($existingFiles.Count -gt 0) {
    throw "No se ha modificado nada porque ya existe una clave o configuracion de firma: $($existingFiles -join ', ')"
}

$keytoolCommand = Get-Command "keytool" -ErrorAction Stop
New-Item -ItemType Directory -Force -Path $keyDirectory | Out-Null

$randomBytes = New-Object byte[] 32
$randomGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try {
    $randomGenerator.GetBytes($randomBytes)
}
finally {
    $randomGenerator.Dispose()
}
$password = [Convert]::ToBase64String($randomBytes).TrimEnd("=").Replace("+", "A").Replace("/", "B")

& $keytoolCommand.Source `
    -genkeypair `
    -v `
    -keystore $keyStorePath `
    -storetype JKS `
    -keyalg RSA `
    -keysize 4096 `
    -validity 10000 `
    -alias $keyAlias `
    -storepass $password `
    -keypass $password `
    -dname "CN=Ruta Clara, OU=Desarrollo, O=Ruta Clara, C=ES" `
    -noprompt

if ($LASTEXITCODE -ne 0) {
    throw "keytool no ha podido crear la clave de subida."
}

& $keytoolCommand.Source `
    -exportcert `
    -rfc `
    -alias $keyAlias `
    -keystore $keyStorePath `
    -storepass $password `
    -file $certificatePath

if ($LASTEXITCODE -ne 0) {
    throw "keytool no ha podido exportar el certificado publico."
}

$javaStorePath = $keyStorePath.Replace("\", "/")
$keyProperties = @"
storePassword=$password
keyPassword=$password
keyAlias=$keyAlias
storeFile=$javaStorePath
"@

$credentials = @"
RUTA CLARA - CREDENCIALES DE FIRMA DE GOOGLE PLAY

IMPORTANTE: guarda este archivo y el .jks en dos copias privadas. No los subas a GitHub ni los compartas.
Google Play exigira esta clave de subida para publicar futuras versiones de la misma aplicacion.

Alias: $keyAlias
Contrasena: $password
Almacen de claves: $keyStorePath
Certificado publico: $certificatePath
Creada: $([DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss"))
"@

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($keyPropertiesPath, $keyProperties, $utf8WithoutBom)
[System.IO.File]::WriteAllText($credentialsPath, $credentials, $utf8WithoutBom)

Write-Host "Clave de subida creada en: $keyStorePath"
Write-Host "Credenciales privadas guardadas en: $credentialsPath"
Write-Host "Configuracion local creada en: $keyPropertiesPath"
