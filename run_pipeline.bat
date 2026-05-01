@echo off
setlocal
cd /d "%~dp0"
set "PYTHONIOENCODING=utf-8"

where py >nul 2>nul
if %errorlevel% neq 0 (
  echo Python launcher bulunamadi.
  echo Python 3.9 veya daha yeni bir surum kurup tekrar deneyin:
  echo https://www.python.org/downloads/windows/
  pause
  exit /b 1
)

py -3 --version >nul 2>nul
if %errorlevel% neq 0 (
  echo Python 3 bulunamadi.
  echo Python 3.9 veya daha yeni bir surum kurup tekrar deneyin:
  echo https://www.python.org/downloads/windows/
  pause
  exit /b 1
)

if not exist ".env" (
  copy ".env.example" ".env" >nul
)

set "PYTHON_CMD=python"
set "PIP_SCOPE=--user"

if not exist ".venv\Scripts\python.exe" (
  python -m venv .venv
)

if exist ".venv\Scripts\python.exe" (
  ".venv\Scripts\python.exe" --version >nul 2>nul
  if %errorlevel% equ 0 (
    set "PYTHON_CMD=.venv\Scripts\python.exe"
    set "PIP_SCOPE="
  ) else (
    echo Sanal ortam kullanilamadi, global Python ile devam ediliyor.
  )
)

%PYTHON_CMD% -m pip install %PIP_SCOPE% -r requirements.txt
%PYTHON_CMD% -m app.main
pause
