#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "📦 Сборка админ-панели..."
cd "$ROOT/admin_web"
npm install
npm run build

echo "🚀 Запуск API + админка на http://127.0.0.1:8080/panel/"
cd "$ROOT/backend"
source venv/bin/activate
exec uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
