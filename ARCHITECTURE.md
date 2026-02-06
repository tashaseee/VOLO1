# 🏗️ Архитектура VOLO

## Общая схема

```
┌─────────────────────────────────────────────────────────────────┐
│                         VOLO Platform                            │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐
│                  │         │                  │
│   Организация    │         │    Волонтер      │
│                  │         │                  │
└────────┬─────────┘         └────────┬─────────┘
         │                            │
         │        Flutter App         │
         │    ┌──────────────────┐    │
         └────┤                  ├────┘
              │   Mobile UI      │
              │   (Dart/Flutter) │
              └────────┬─────────┘
                       │
                       │ HTTP/REST
                       │
              ┌────────▼─────────┐
              │                  │
              │   FastAPI        │
              │   Backend        │
              │   (Python)       │
              └────────┬─────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
    ┌────▼────┐   ┌────▼────┐   ┌───▼────┐
    │         │   │         │   │        │
    │ PostgreSQL  │  Gmail  │   │  JWT   │
    │ Database│   │  SMTP   │   │  Auth  │
    │         │   │         │   │        │
    └─────────┘   └─────────┘   └────────┘
```

## Компоненты системы

### 1. Frontend (Flutter)

```
volo/
├── lib/
│   ├── main.dart                          # Entry point
│   │
│   ├── services/
│   │   └── api_service.dart               # API client
│   │
│   ├── Организация:
│   │   ├── organizer_navigator.dart       # Bottom navigation
│   │   ├── organizer_home_page.dart       # Dashboard
│   │   ├── add_event_page.dart            # Create event (6 steps)
│   │   ├── organizer_events_page.dart     # My events list
│   │   ├── organizer_event_applications_page.dart  # Applications
│   │   ├── volunteers_page.dart           # Volunteers list
│   │   └── organizer_profile_page.dart    # Profile
│   │
│   ├── Волонтер:
│   │   ├── home_page.dart                 # Events catalog
│   │   ├── event_detail_page.dart         # Event details
│   │   ├── my_applications_page.dart      # My applications
│   │   ├── notifications_page.dart        # Notifications
│   │   ├── search_page.dart               # Search events
│   │   └── profile_page.dart              # Profile
│   │
│   └── Общие:
│       ├── login_page.dart                # Login
│       ├── register_page.dart             # Registration
│       └── bottom_nav_bar.dart            # Navigation bar
│
└── assets/
    ├── images/                            # Icons, logos
    └── fonts/                             # Poppins font
```

### 2. Backend (FastAPI)

```
backend/
├── app/
│   ├── main.py                            # FastAPI app
│   ├── database.py                        # DB connection
│   ├── auth_utils.py                      # Auth & Email
│   │
│   ├── models/
│   │   ├── user.py                        # User, Profile, OrgProfile
│   │   └── event.py                       # Event, Application
│   │
│   ├── schemas/
│   │   ├── user.py                        # Pydantic schemas
│   │   └── event.py                       # Pydantic schemas
│   │
│   └── api/
│       ├── auth.py                        # Auth endpoints
│       ├── users.py                       # User endpoints
│       ├── events.py                      # Event endpoints
│       └── admin.py                       # Admin endpoints
│
├── .env                                   # Environment variables
└── requirements.txt                       # Python dependencies
```

### 3. База данных (PostgreSQL)

```
┌─────────────────────────────────────────────────────────────┐
│                         Database: volo                       │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐
│    users     │         │   profiles   │
├──────────────┤         ├──────────────┤
│ id (PK)      │────────▶│ id (PK)      │
│ email        │         │ user_id (FK) │
│ password     │         │ full_name    │
│ role         │         │ birth_date   │
│ is_verified  │         │ city         │
│ is_approved  │         │ phone        │
└──────────────┘         │ volo_hours   │
       │                 │ events_done  │
       │                 └──────────────┘
       │
       │                 ┌──────────────────────┐
       │                 │ organization_profiles│
       │                 ├──────────────────────┤
       └────────────────▶│ id (PK)              │
                         │ user_id (FK)         │
                         │ full_name            │
                         │ bin                  │
                         │ description          │
                         └──────────────────────┘

┌──────────────┐         ┌──────────────────┐
│   events     │         │  applications    │
├──────────────┤         ├──────────────────┤
│ id (PK)      │◀────────│ id (PK)          │
│ title        │         │ user_id (FK)     │
│ organizer    │         │ event_id (FK)    │
│ organizer_id │         │ status           │
│ description  │         │ created_at       │
│ category     │         └──────────────────┘
│ location     │
│ date_text    │
│ full_date    │
│ hours        │
│ image_url    │
│ is_active    │
└──────────────┘

┌──────────────┐         ┌──────────────┐
│  interests   │         │   skills     │
├──────────────┤         ├──────────────┤
│ id (PK)      │         │ id (PK)      │
│ user_id (FK) │         │ user_id (FK) │
│ name         │         │ name         │
└──────────────┘         └──────────────┘
```

## Потоки данных

### 1. Создание ивента

```
Организация                Flutter               Backend              Database
    │                         │                     │                    │
    │  Заполняет форму        │                     │                    │
    │────────────────────────▶│                     │                    │
    │                         │                     │                    │
    │  Нажимает "Опубликовать"│                     │                    │
    │────────────────────────▶│                     │                    │
    │                         │                     │                    │
    │                         │ POST /events/       │                    │
    │                         │ + JWT token         │                    │
    │                         │────────────────────▶│                    │
    │                         │                     │                    │
    │                         │                     │ INSERT event       │
    │                         │                     │ organizer_id=user  │
    │                         │                     │───────────────────▶│
    │                         │                     │                    │
    │                         │                     │ Event created      │
    │                         │                     │◀───────────────────│
    │                         │                     │                    │
    │                         │ 200 OK + event data │                    │
    │                         │◀────────────────────│                    │
    │                         │                     │                    │
    │  Уведомление "Успех"    │                     │                    │
    │◀────────────────────────│                     │                    │
```

### 2. Подача заявки

```
Волонтер                  Flutter               Backend              Database
    │                         │                     │                    │
    │  Нажимает "Подать заявку"│                    │                    │
    │────────────────────────▶│                     │                    │
    │                         │                     │                    │
    │                         │ POST /events/1/apply│                    │
    │                         │ + JWT token         │                    │
    │                         │────────────────────▶│                    │
    │                         │                     │                    │
    │                         │                     │ INSERT application │
    │                         │                     │ status='pending'   │
    │                         │                     │───────────────────▶│
    │                         │                     │                    │
    │                         │                     │ Application created│
    │                         │                     │◀───────────────────│
    │                         │                     │                    │
    │                         │ 200 OK + app data   │                    │
    │                         │◀────────────────────│                    │
    │                         │                     │                    │
    │  Уведомление "Заявка подана"                  │                    │
    │◀────────────────────────│                     │                    │
```

### 3. Управление заявкой

```
Организация              Flutter               Backend              Database         Email
    │                         │                     │                    │              │
    │  Нажимает "Принять"     │                     │                    │              │
    │────────────────────────▶│                     │                    │              │
    │                         │                     │                    │              │
    │                         │ PUT /applications/1/status               │              │
    │                         │ {"status":"approved"}                    │              │
    │                         │ + JWT token         │                    │              │
    │                         │────────────────────▶│                    │              │
    │                         │                     │                    │              │
    │                         │                     │ UPDATE application │              │
    │                         │                     │ status='approved'  │              │
    │                         │                     │───────────────────▶│              │
    │                         │                     │                    │              │
    │                         │                     │ Updated            │              │
    │                         │                     │◀───────────────────│              │
    │                         │                     │                    │              │
    │                         │                     │ Send email         │              │
    │                         │                     │────────────────────────────────────▶│
    │                         │                     │                    │              │
    │                         │                     │                    │  Email sent  │
    │                         │                     │◀────────────────────────────────────│
    │                         │                     │                    │              │
    │                         │ 200 OK + app data   │                    │              │
    │                         │◀────────────────────│                    │              │
    │                         │                     │                    │              │
    │  Уведомление "Статус обновлен"                │                    │              │
    │◀────────────────────────│                     │                    │              │
    │                         │                     │                    │              │
    │                         │                     │                    │              │
Волонтер                      │                     │                    │              │
    │                         │                     │                    │              │
    │  Получает email         │                     │                    │              │
    │◀────────────────────────────────────────────────────────────────────────────────────│
    │                         │                     │                    │              │
    │  Открывает "Мои заявки" │                     │                    │              │
    │────────────────────────▶│                     │                    │              │
    │                         │                     │                    │              │
    │                         │ GET /my-applications│                    │              │
    │                         │────────────────────▶│                    │              │
    │                         │                     │                    │              │
    │                         │                     │ SELECT applications│              │
    │                         │                     │───────────────────▶│              │
    │                         │                     │                    │              │
    │                         │ 200 OK + apps       │                    │              │
    │                         │◀────────────────────│                    │              │
    │                         │                     │                    │              │
    │  Видит статус "Принята" (🟢)                  │                    │              │
    │◀────────────────────────│                     │                    │              │
```

## Безопасность

### Аутентификация

```
1. Регистрация:
   User → Flutter → Backend → Hash password → Save to DB

2. Логин:
   User → Flutter → Backend → Verify password → Generate JWT → Return token

3. Защищенные запросы:
   User → Flutter → Backend (with JWT) → Verify token → Process request
```

### Авторизация

```
Роли:
- volunteer: может подавать заявки, просматривать ивенты
- organization: может создавать ивенты, управлять заявками
- admin: может одобрять организации

Проверки:
- JWT token в каждом запросе
- Роль пользователя проверяется на backend
- organizer_id проверяется при доступе к заявкам
```

## Масштабирование

### Текущая архитектура
- Monolithic backend (FastAPI)
- Single PostgreSQL instance
- No caching
- No load balancing

### Возможные улучшения
1. **Redis** для кеширования
2. **Nginx** для load balancing
3. **Docker** для контейнеризации
4. **CDN** для статических файлов
5. **Message Queue** для email
6. **Microservices** для разделения логики

---

Made with ❤️ for VOLO
