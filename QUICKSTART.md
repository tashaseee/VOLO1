# 🚀 VOLO - Быстрый старт

## За 5 минут

### 1. Запустите Backend (30 сек)
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload
```
✅ Backend работает на http://127.0.0.1:8000

### 2. Запустите Frontend (30 сек)
```bash
cd volo
flutter run
```
✅ Приложение запущено

### 3. Создайте тестовые аккаунты (2 мин)

**Организация:**
- Email: `org@test.com`
- Password: `Test1234`
- Role: organization
- Name: Test Org
- BIN: 123456789012

**Волонтер:**
- Email: `volunteer@test.com`
- Password: `Test1234`
- Role: volunteer

### 4. Одобрите организацию (30 сек)
```bash
cd backend
source venv/bin/activate
python approve_org.py
```

### 5. Тестируйте! (2 мин)

**Как организация:**
1. Войдите → Нажмите "+" → Создайте ивент
2. Перейдите в "История" → Посмотрите свои ивенты

**Как волонтер:**
1. Войдите → Найдите ивент → Подайте заявку
2. Перейдите в "Мои заявки" → Проверьте статус

**Как организация:**
1. "История" → Выберите ивент → Посмотрите заявки
2. Нажмите "Принять" → Проверьте email волонтера

## Что работает

✅ Создание ивентов (6-шаговая форма)
✅ Подача заявок волонтерами
✅ Управление заявками организацией
✅ Email-уведомления (зеленые/красные письма)
✅ Отслеживание статусов с цветными индикаторами
✅ Сохранение всех данных в PostgreSQL

## Основные страницы

### Организация
- **Главная** - дашборд
- **+** - создать ивент
- **История** - мои ивенты → заявки
- **Волонтёры** - список
- **Профиль** - настройки

### Волонтер
- **Уведомления** - все уведомления
- **Поиск** - поиск ивентов
- **Главная** - каталог ивентов
- **Мои заявки** - статусы заявок
- **Профиль** - настройки

## Цветные индикаторы

🟠 **Оранжевый** - На рассмотрении
🟢 **Зеленый** - Принята
🔴 **Красный** - Отклонена
⚪ **Серый** - Завершена

## Полезные команды

### Backend
```bash
# Запуск
uvicorn app.main:app --reload

# Пересоздать БД
python reset_db.py

# Одобрить организацию
python approve_org.py

# Тест API
python test_workflow.py
```

### Frontend
```bash
# Запуск
flutter run

# Очистка
flutter clean
flutter pub get
```

### База данных
```bash
# Подключиться
psql -U postgres -d volo

# Посмотреть таблицы
\dt

# Посмотреть ивенты
SELECT * FROM events;

# Посмотреть заявки
SELECT * FROM applications;
```

## Документация

📖 [README.md](./README.md) - Общее описание
📋 [IMPLEMENTATION.md](./IMPLEMENTATION.md) - Детальная документация
🧪 [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Руководство по тестированию
🔧 [API.md](./API.md) - API Reference
🏗️ [ARCHITECTURE.md](./ARCHITECTURE.md) - Архитектура
✅ [CHECKLIST.md](./CHECKLIST.md) - Чеклист проверки
📊 [SUMMARY.md](./SUMMARY.md) - Итоговый отчет

## Проблемы?

### Backend не запускается
```bash
pip install -r requirements.txt
```

### БД не работает
```bash
createdb volo
python reset_db.py
```

### Flutter ошибки
```bash
flutter clean
flutter pub get
```

### Email не отправляются
Проверьте `.env`:
```
MAIL_USERNAME=volo.2025.kz@gmail.com
MAIL_PASSWORD=lgul vwtr wkmj nsbe
```

## Swagger UI

Откройте http://127.0.0.1:8000/docs для интерактивной документации API

## Контакты

📧 volo.2025.kz@gmail.com

---

**Готово! Можно тестировать! 🎉**
