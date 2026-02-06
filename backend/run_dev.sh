#!/bin/bash
clear

echo "========================================"
echo "🚀 ЗАПУСК VOLO В РЕЖИМЕ РАЗРАБОТКИ"
echo "========================================"
echo

echo "📊 Проверка настроек..."
if [ -f ".env" ]; then
    echo "✅ Файл .env найден"
else
    echo "❌ Файл .env не найден!"
    echo "   Создайте файл .env в папке backend"
    exit 1
fi

echo
echo "🔧 Запуск сервера FastAPI..."
echo "📧 Режим разработки: коды выводятся в консоль"
echo "🌐 Документация API: http://localhost:8000/docs"
echo "📱 Тестовый пользователь: test@example.com / password123"
echo

echo "🎯 Тестируйте регистрацию с email: aminakazanbasova@icloud.com"
echo "   Код подтверждения появится ниже ⬇️"
echo
echo "========================================"
echo

./venv/bin/python3 -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8080