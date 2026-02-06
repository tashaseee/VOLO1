# VOLO API Reference

Base URL: `http://127.0.0.1:8000`

## Authentication

All protected endpoints require JWT token in header:
```
Authorization: Bearer <token>
```

## Endpoints

### 🔐 Auth

#### Register
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123",
  "role": "volunteer",  // or "organization"
  "org_name": "Org Name",  // required if role=organization
  "bin": "123456789012"    // required if role=organization
}

Response: 201
{
  "message": "User created. Please verify email.",
  "email": "user@example.com"
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123"
}

Response: 200
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "role": "volunteer",
  "is_approved": true,
  "is_verified": true
}
```

#### Verify Email
```http
POST /auth/verify
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "123456"
}

Response: 200
{
  "message": "Email verified successfully"
}
```

---

### 🎯 Events

#### Get All Events
```http
GET /events/

Response: 200
[
  {
    "id": 1,
    "title": "Посадка деревьев",
    "organizer": "Eco Group",
    "organizer_id": 5,
    "description": "Озеленение города",
    "date_text": "25 Jan",
    "full_date": "2026-01-25T10:00:00",
    "location": "Парк Горького, Алматы",
    "hours": 5,
    "category": "Экология и природа",
    "image_url": null,
    "is_active": true,
    "created_at": "2026-01-30T12:00:00"
  }
]
```

#### Create Event (Organization only)
```http
POST /events/
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Посадка деревьев",
  "description": "Озеленение города",
  "category": "Экология и природа",
  "location": "Парк Горького, Алматы",
  "hours": 5,
  "date_text": "25 Jan",
  "full_date": "2026-01-25T10:00:00",
  "image_url": null
}

Response: 200
{
  "id": 1,
  "title": "Посадка деревьев",
  "organizer": "Eco Group",
  "organizer_id": 5,
  ...
}
```

#### Get My Events (Organization only)
```http
GET /events/my-events
Authorization: Bearer <token>

Response: 200
[
  {
    "id": 1,
    "title": "Посадка деревьев",
    ...
  }
]
```

---

### 📝 Applications

#### Apply to Event (Volunteer only)
```http
POST /events/{event_id}/apply
Authorization: Bearer <token>

Response: 200
{
  "id": 1,
  "user_id": 3,
  "event_id": 1,
  "status": "pending",
  "created_at": "2026-01-30T12:00:00",
  "event": { ... }
}
```

#### Get My Applications (Volunteer only)
```http
GET /events/my-applications
Authorization: Bearer <token>

Response: 200
[
  {
    "id": 1,
    "user_id": 3,
    "event_id": 1,
    "status": "pending",
    "created_at": "2026-01-30T12:00:00",
    "event": {
      "id": 1,
      "title": "Посадка деревьев",
      ...
    }
  }
]
```

#### Get Event Applications (Organization only)
```http
GET /events/{event_id}/applications
Authorization: Bearer <token>

Response: 200
[
  {
    "id": 1,
    "user_id": 3,
    "event_id": 1,
    "status": "pending",
    "created_at": "2026-01-30T12:00:00",
    "user": {
      "id": 3,
      "email": "volunteer@example.com",
      "role": "volunteer",
      "profile": {
        "full_name": "John Doe",
        "avatar_url": "http://...",
        ...
      }
    },
    "event": { ... }
  }
]
```

#### Update Application Status (Organization only)
```http
PUT /events/applications/{application_id}/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "approved"  // or "rejected", "completed"
}

Response: 200
{
  "id": 1,
  "user_id": 3,
  "event_id": 1,
  "status": "approved",
  ...
}

Note: Sends email notification to volunteer
```

---

### 👤 Users

#### Get Current User
```http
GET /users/me
Authorization: Bearer <token>

Response: 200
{
  "id": 1,
  "email": "user@example.com",
  "role": "volunteer",
  "is_verified": true,
  "is_approved": true,
  "created_at": "2026-01-30T12:00:00",
  "profile": {
    "id": 1,
    "full_name": "John Doe",
    "birth_date": "1990-01-01",
    "gender": "male",
    "city": "Almaty",
    "phone": "+77771234567",
    "avatar_url": "http://...",
    "volo_hours": 25,
    "events_done": 5,
    ...
  },
  "interests": [
    {"name": "Экология"},
    {"name": "Спорт"}
  ],
  "skills": [
    {"name": "Фотография"},
    {"name": "Организация"}
  ]
}
```

#### Update Profile (Volunteer)
```http
PUT /users/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "full_name": "John Doe",
  "birth_date": "1990-01-01",
  "gender": "male",
  "city": "Almaty",
  "phone": "+77771234567",
  "experience": "2 years of volunteering",
  "motivation": "Want to help the community",
  "interests": ["Экология", "Спорт"],
  "skills": ["Фотография", "Организация"]
}

Response: 200
{
  "message": "Profile updated successfully"
}
```

#### Update Organization Profile
```http
PUT /users/org-profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "full_name": "Eco Group KZ",
  "bin": "123456789012",
  "description": "Environmental organization",
  "website": "https://ecogroup.kz",
  "address": "Almaty, Kazakhstan",
  "phone": "+77771234567"
}

Response: 200
{
  "message": "Organization profile updated successfully"
}
```

---

### 🔧 Admin

#### Get Pending Organizations
```http
GET /admin/pending-organizations
Authorization: Bearer <admin_token>

Response: 200
[
  {
    "id": 5,
    "email": "org@example.com",
    "role": "organization",
    "is_approved": false,
    "org_profile": {
      "full_name": "Test Org",
      "bin": "123456789012",
      ...
    }
  }
]
```

#### Approve Organization
```http
POST /admin/approve-organization/{user_id}
Authorization: Bearer <admin_token>

Response: 200
{
  "message": "Organization approved and notified"
}

Note: Sends email notification to organization
```

---

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `422` - Unprocessable Entity (validation error)
- `500` - Internal Server Error

## Application Statuses

- `pending` - Заявка на рассмотрении
- `approved` - Заявка одобрена
- `rejected` - Заявка отклонена
- `completed` - Мероприятие завершено

## Event Categories

- Экология и природа
- Социальная помощь
- Образование
- Культура и искусство
- Спорт и здоровье
- Медицина
- Животные
- Дети и молодежь

## Error Response Format

```json
{
  "detail": "Error message here"
}
```

## Rate Limiting

Currently no rate limiting implemented.
Recommended: 100 requests per minute per IP.

## CORS

Allowed origins:
- `http://localhost:*`
- `http://127.0.0.1:*`

## Testing with cURL

### Login and get token
```bash
TOKEN=$(curl -s -X POST http://127.0.0.1:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Password123"}' \
  | jq -r '.access_token')
```

### Use token in requests
```bash
curl http://127.0.0.1:8000/users/me \
  -H "Authorization: Bearer $TOKEN"
```

## Webhooks

Not implemented yet.

## WebSockets

Not implemented yet.

---

For more details, see [Swagger UI](http://127.0.0.1:8000/docs) when server is running.
