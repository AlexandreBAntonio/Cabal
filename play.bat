@echo off
setlocal
cd /d "%~dp0"
title Cabal ARPG - Sessao 1

REM ------------------------------------------------------------------
REM play.bat        -> roda o JOGO direto
REM play.bat editor -> abre o projeto no editor Godot
REM Na primeira execucao baixa o Godot 4.3 portatil para .\godot\
REM (nada e instalado no sistema).
REM ------------------------------------------------------------------

set GODOT_EXE=godot\Godot_v4.3-stable_win64.exe

if exist "%GODOT_EXE%" goto :run

echo.
echo  Baixando Godot 4.3 (release oficial, ~55 MB)...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "Invoke-WebRequest -Uri 'https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip' -OutFile 'godot.zip';" ^
  "Expand-Archive -Path 'godot.zip' -DestinationPath 'godot' -Force;" ^
  "Remove-Item 'godot.zip'"

if not exist "%GODOT_EXE%" (
  echo.
  echo  ERRO: download falhou. Verifique a conexao e rode de novo,
  echo  ou baixe manualmente em https://godotengine.org/download/windows
  echo  e extraia o .exe para a pasta godot\ deste projeto.
  pause
  exit /b 1
)

:run
if /i "%1"=="editor" (
  echo  Abrindo o editor Godot...
  start "" "%GODOT_EXE%" --path . -e
  exit /b 0
)
echo  Importando recursos (rapido) e abrindo o jogo...
REM passada do editor headless: constroi o cache de classes globais (class_name)
"%GODOT_EXE%" --headless --path . -e --quit >nul 2>&1
"%GODOT_EXE%" --headless --path . --import >nul 2>&1
start "" "%GODOT_EXE%" --path .
exit /b 0
