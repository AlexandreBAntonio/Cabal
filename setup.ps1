# setup.ps1 — Instalação com um comando (Windows):
#   irm https://raw.githubusercontent.com/AlexandreBAntonio/Cabal/claude/execute-markdown-file-00nar8/setup.ps1 | iex
#
# Baixa o projeto para %USERPROFILE%\Cabal, baixa o Godot 4.3 portátil
# (release oficial) para a subpasta godot\ e abre o editor.
# Nada é instalado no sistema: apagar a pasta remove tudo.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Branch = 'claude/execute-markdown-file-00nar8'
$Dest = Join-Path $HOME 'Cabal'
$RepoZip = "https://codeload.github.com/AlexandreBAntonio/Cabal/zip/refs/heads/$Branch"
$GodotZip = 'https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip'
$GodotExe = Join-Path $Dest 'godot\Godot_v4.3-stable_win64.exe'

Write-Host ''
Write-Host '=== Cabal ARPG - Sessao 1: instalacao local ===' -ForegroundColor Cyan

# --- 1/3: projeto ---
Write-Host "[1/3] Baixando o projeto para $Dest ..."
$tmp = Join-Path $env:TEMP "cabal_setup_$PID"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
Invoke-WebRequest -Uri $RepoZip -OutFile (Join-Path $tmp 'projeto.zip')
Expand-Archive -Path (Join-Path $tmp 'projeto.zip') -DestinationPath $tmp -Force
$inner = Get-ChildItem -Directory $tmp | Where-Object { $_.Name -like 'Cabal-*' } | Select-Object -First 1
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item -Path (Join-Path $inner.FullName '*') -Destination $Dest -Recurse -Force
Remove-Item -Recurse -Force $tmp

# --- 2/3: Godot portátil ---
if (Test-Path $GodotExe) {
    Write-Host '[2/3] Godot ja presente, pulando download.'
} else {
    Write-Host '[2/3] Baixando Godot 4.3 portatil (~55 MB, release oficial)...'
    Invoke-WebRequest -Uri $GodotZip -OutFile (Join-Path $Dest 'godot.zip')
    Expand-Archive -Path (Join-Path $Dest 'godot.zip') -DestinationPath (Join-Path $Dest 'godot') -Force
    Remove-Item (Join-Path $Dest 'godot.zip')
}

# --- 3/3: abrir o editor ---
Write-Host '[3/3] Abrindo o projeto no editor Godot... (aperte F5 para jogar)'
Start-Process -FilePath $GodotExe -ArgumentList "--path `"$Dest`" -e"

Write-Host ''
Write-Host "Pronto! Projeto instalado em $Dest" -ForegroundColor Green
Write-Host 'Nas proximas vezes, use o play.bat dessa pasta (ou rode este comando de novo).'
