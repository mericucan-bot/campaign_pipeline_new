#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
export PYTHONIOENCODING=utf-8

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 bulunamadi."
  echo "Mac'e Python 3.9 veya daha yeni bir surum kurup tekrar deneyin."
  echo "Oneri: https://www.python.org/downloads/macos/"
  exit 1
fi

if [ ! -f ".env" ]; then
  cp ".env.example" ".env"
fi

if [ ! -x ".venv/bin/python" ]; then
  python3 -m venv .venv
fi

PYTHON_CMD=".venv/bin/python"

"$PYTHON_CMD" -m pip install --upgrade pip
"$PYTHON_CMD" -m pip install -r requirements.txt

echo
echo "Dashboard hazir: http://127.0.0.1:5050"
echo "Durdurmak icin Terminal'de Ctrl+C basabilirsiniz."
echo

if command -v open >/dev/null 2>&1; then
  open "http://127.0.0.1:5050" >/dev/null 2>&1 || true
fi

"$PYTHON_CMD" -m app.dashboard
