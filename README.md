# 🎯 VOLO - Платформа волонтерства в Казахстане

> Современная система управления волонтерскими мероприятиями с красивым дизайном и полным функционалом

![VOLO](https://img.shields.io/badge/VOLO-v1.0-purple)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue)

## ✨ Особенности

### Для Организаций
- 📝 **Создание ивентов** - красивая многошаговая форма с 6 этапами
- 👥 **Управление заявками** - просмотр и обработка заявок волонтеров
- ✅ **Принятие/отклонение** - одним кликом с автоматическими уведомлениями
- 📊 **Статистика** - дашборд с метриками и аналитикой
- 📧 **Email-уведомления** - автоматическая отправка красивых писем

### Для Волонтеров
- 🔍 **Поиск ивентов** - каталог с фильтрами по категориям
- 📱 **Подача заявок** - быстрая подача заявки в один клик
- 📋 **Отслеживание статуса** - мониторинг всех заявок в реальном времени
- 🎨 **Цветные индикаторы** - визуальное отображение статусов
- 🔔 **Уведомления** - push и email при изменении статуса
- 🏆 **Сертификаты** - получение сертификатов за участие

## 🎨 Дизайн

### Цветовая палитра
```
Primary:   #983296 (Фиолетовый VOLO)
Success:   #4CAF50 (Зеленый)
Warning:   #FFA726 (Оранжевый)
Error:     #EF4444 (Красный)
```

### UI/UX
- ✨ Современный Material Design
- 🎭 Плавные анимации и переходы
- 📱 Адаптивный дизайн
- 🎯 Интуитивная навигация
- 💫 Микро-анимации для лучшего UX

## 🚀 Технологии

### Backend
- **FastAPI** - современный Python веб-фреймворк
- **PostgreSQL** - надежная реляционная БД
- **SQLAlchemy** - ORM для работы с БД
- **JWT** - безопасная аутентификация
- **FastMail** - отправка email-уведомлений

### Frontend
- **Flutter** - кроссплатформенный UI фреймворк
- **Dart** - язык программирования
- **Google Fonts** - красивая типографика (Poppins)
- **SVG** - векторные иконки
- **HTTP** - REST API клиент

## 📦 Установка

### Требования
- Python 3.9+
- PostgreSQL 15+
- Flutter 3.0+
- Node.js 16+ (опционально)

### Backend

```bash
# Клонируйте репозиторий
git clone https://github.com/yourusername/volo.git
cd volo/backend

# Создайте виртуальное окружение
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# или
venv\Scripts\activate  # Windows

# Установите зависимости
pip install -r requirements.txt

# Создайте .env файл
cp .env.example .env
# Отредактируйте .env с вашими настройками

# Создайте базу данных
createdb volo

# Инициализируйте таблицы
python reset_db.py

# Запустите сервер
uvicorn app.main:app --reload
```

### Frontend

```bash
cd volo

# Установите зависимости
flutter pub get

# Запустите приложение
flutter run
```

## 🎯 Быстрый старт

### 1. Создайте организацию
```bash
Email: org@example.com
Password: Test1234
Role: organization
```

### 2. Одобрите организацию
```bash
cd backend
source venv/bin/activate
python approve_org.py
```

### 3. Создайте ивент
- Войдите как организация
- Нажмите "+" в навигации
- Заполните форму в 6 шагов
- Опубликуйте ивент

### 4. Подайте заявку как волонтер
- Зарегистрируйтесь как волонтер
- Найдите ивент на главной
- Нажмите "Подать заявку"

### 5. Управляйте заявками
- Войдите как организация
- Перейдите в "История"
- Выберите ивент
- Принимайте/отклоняйте заявки

## 📚 Документация

- [Полная документация](./IMPLEMENTATION.md)
- [Руководство по тестированию](./TESTING_GUIDE.md)
- [API Reference](./API.md)

## 🏗️ Архитектура

```
VOLO/
├── backend/                 # FastAPI Backend
│   ├── app/
│   │   ├── api/            # API endpoints
│   │   ├── models/         # SQLAlchemy models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── auth_utils.py   # Authentication
│   │   ├── database.py     # DB connection
│   │   └── main.py         # FastAPI app
│   ├── static/             # Static files
│   ├── requirements.txt    # Python dependencies
│   └── .env               # Environment variables
│
└── volo/                   # Flutter Frontend
    ├── lib/
    │   ├── services/       # API service
    │   ├── *_page.dart     # UI pages
    │   └── main.dart       # App entry
    ├── assets/             # Images, icons, fonts
    └── pubspec.yaml        # Flutter dependencies
```

## 🔐 Безопасность

- ✅ JWT токены для аутентификации
- ✅ Хеширование паролей (bcrypt)
- ✅ Валидация email
- ✅ Защита от SQL injection (SQLAlchemy ORM)
- ✅ CORS настройки
- ✅ Rate limiting (опционально)

## 📧 Email-уведомления

Система автоматически отправляет красиво оформленные email при:
- ✅ Одобрении заявки (зеленое письмо)
- ✅ Отклонении заявки (красное письмо)
- ✅ Одобрении организации (фиолетовое письмо)
- ✅ Сбросе пароля (синее письмо)

## 🎨 Скриншоты

### Организация
![Создание ивента](./screenshots/create_event.png)
![Управление заявками](./screenshots/manage_applications.png)

### Волонтер
![Каталог ивентов](./screenshots/events_catalog.png)
![Мои заявки](./screenshots/my_applications.png)

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие VOLO! 

1. Fork репозиторий
2. Создайте feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit изменения (`git commit -m 'Add some AmazingFeature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

## 📝 Лицензия

Этот проект лицензирован под MIT License - см. [LICENSE](LICENSE) для деталей.

## 👥 Команда

- **Амина Казанбасова** - Project Lead & Developer
- **VOLO Team** - Development Team

## 📞 Контакты

- Email: volo.2025.kz@gmail.com
- Telegram: @volo_kz
- Website: https://volo.kz

## 🙏 Благодарности

- Flutter Team за отличный фреймворк
- FastAPI за быстрый и современный backend
- Google Fonts за красивую типографику
- Сообщество open-source за вдохновение

---

Made with ❤️ in Kazakhstan 🇰🇿
