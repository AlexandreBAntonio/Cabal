@echo off
setlocal
cd /d "%~dp0"
title Cabal ARPG - Sessao 1

REM ------------------------------------------------------------------
REM Baixa o Godot 4.3 (portatil, oficial) na primeira execucao e abre
REM o projeto no editor. Nao instala nada no sistema: tudo fica na
REM pasta .\godot\ dentro do projeto.
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
echo  Abrindo o projeto no editor Godot (aperte F5 para jogar)...
start "" "%GODOT_EXE%" --path . -e
exit /b 0
