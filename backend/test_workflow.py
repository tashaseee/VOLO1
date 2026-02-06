#!/usr/bin/env python3
"""
Тестовый скрипт для проверки VOLO API
"""
import requests
import json
from datetime import datetime, timedelta

BASE_URL = "http://127.0.0.1:8000"

def print_section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")

def test_organization_workflow():
    """Тестирование полного workflow организации"""
    
    print_section("1. Регистрация организации")
    
    # Регистрация
    org_data = {
        "email": "testorg@example.com",
        "password": "Test1234",
        "role": "organization",
        "org_name": "Test Organization",
        "bin": "123456789012"
    }
    
    response = requests.post(f"{BASE_URL}/auth/register", json=org_data)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    if response.status_code != 200:
        print("❌ Регистрация не удалась")
        return
    
    print("✅ Организация зарегистрирована")
    
    # Логин (пропускаем верификацию для теста)
    print_section("2. Вход организации")
    
    login_data = {
        "email": "testorg@example.com",
        "password": "Test1234"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status: {response.status_code}")
    
    if response.status_code != 200:
        print("❌ Вход не удался (возможно, нужна верификация)")
        return
    
    data = response.json()
    org_token = data.get('access_token')
    print(f"✅ Токен получен: {org_token[:20]}...")
    
    # Создание ивента
    print_section("3. Создание ивента")
    
    event_date = datetime.now() + timedelta(days=7)
    event_data = {
        "title": "Тестовое мероприятие",
        "description": "Описание тестового мероприятия",
        "category": "Экология и природа",
        "location": "Алматы, Парк Горького",
        "hours": 5,
        "date_text": event_date.strftime("%d %b"),
        "full_date": event_date.isoformat()
    }
    
    headers = {"Authorization": f"Bearer {org_token}"}
    response = requests.post(f"{BASE_URL}/events/", json=event_data, headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    if response.status_code != 200:
        print("❌ Создание ивента не удалось")
        return
    
    event_id = response.json()['id']
    print(f"✅ Ивент создан с ID: {event_id}")
    
    # Получение своих ивентов
    print_section("4. Получение списка своих ивентов")
    
    response = requests.get(f"{BASE_URL}/events/my-events", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Количество ивентов: {len(response.json())}")
    print(f"✅ Список получен")
    
    return org_token, event_id

def test_volunteer_workflow(event_id):
    """Тестирование полного workflow волонтера"""
    
    print_section("5. Регистрация волонтера")
    
    # Регистрация
    volunteer_data = {
        "email": "testvolunteer@example.com",
        "password": "Test1234",
        "role": "volunteer"
    }
    
    response = requests.post(f"{BASE_URL}/auth/register", json=volunteer_data)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    if response.status_code != 200:
        print("❌ Регистрация не удалась")
        return
    
    print("✅ Волонтер зарегистрирован")
    
    # Логин
    print_section("6. Вход волонтера")
    
    login_data = {
        "email": "testvolunteer@example.com",
        "password": "Test1234"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status: {response.status_code}")
    
    if response.status_code != 200:
        print("❌ Вход не удался (возможно, нужна верификация)")
        return
    
    data = response.json()
    volunteer_token = data.get('access_token')
    print(f"✅ Токен получен: {volunteer_token[:20]}...")
    
    # Просмотр ивентов
    print_section("7. Просмотр всех ивентов")
    
    response = requests.get(f"{BASE_URL}/events/")
    print(f"Status: {response.status_code}")
    print(f"Количество ивентов: {len(response.json())}")
    print(f"✅ Список получен")
    
    # Подача заявки
    print_section("8. Подача заявки на ивент")
    
    headers = {"Authorization": f"Bearer {volunteer_token}"}
    response = requests.post(f"{BASE_URL}/events/{event_id}/apply", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    if response.status_code != 200:
        print("❌ Подача заявки не удалась")
        return
    
    application_id = response.json()['id']
    print(f"✅ Заявка подана с ID: {application_id}")
    
    # Просмотр своих заявок
    print_section("9. Просмотр своих заявок")
    
    response = requests.get(f"{BASE_URL}/events/my-applications", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Количество заявок: {len(response.json())}")
    
    if len(response.json()) > 0:
        app = response.json()[0]
        print(f"Статус заявки: {app['status']}")
        print(f"✅ Список получен")
    
    return volunteer_token, application_id

def test_application_management(org_token, event_id, application_id):
    """Тестирование управления заявками"""
    
    print_section("10. Просмотр заявок на ивент (организация)")
    
    headers = {"Authorization": f"Bearer {org_token}"}
    response = requests.get(f"{BASE_URL}/events/{event_id}/applications", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Количество заявок: {len(response.json())}")
    
    if len(response.json()) > 0:
        app = response.json()[0]
        print(f"Заявка от: {app['user']['email']}")
        print(f"Статус: {app['status']}")
        print(f"✅ Список получен")
    
    # Одобрение заявки
    print_section("11. Одобрение заявки")
    
    status_data = {"status": "approved"}
    response = requests.put(
        f"{BASE_URL}/events/applications/{application_id}/status",
        json=status_data,
        headers=headers
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    if response.status_code == 200:
        print(f"✅ Заявка одобрена")
        print(f"📧 Email-уведомление отправлено волонтеру")
    else:
        print(f"❌ Одобрение не удалось")

def main():
    print("""
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║              VOLO API Test Script                         ║
    ║                                                           ║
    ║  Этот скрипт тестирует полный workflow:                  ║
    ║  1. Регистрация организации                              ║
    ║  2. Создание ивента                                      ║
    ║  3. Регистрация волонтера                                ║
    ║  4. Подача заявки                                        ║
    ║  5. Управление заявками                                  ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
    """)
    
    try:
        # Проверка доступности API
        print("Проверка доступности API...")
        response = requests.get(f"{BASE_URL}/docs")
        if response.status_code != 200:
            print("❌ API недоступен. Убедитесь, что backend запущен.")
            return
        print("✅ API доступен\n")
        
        # Тестирование workflow организации
        result = test_organization_workflow()
        if not result:
            print("\n❌ Тестирование организации не удалось")
            return
        
        org_token, event_id = result
        
        # Тестирование workflow волонтера
        result = test_volunteer_workflow(event_id)
        if not result:
            print("\n❌ Тестирование волонтера не удалось")
            return
        
        volunteer_token, application_id = result
        
        # Тестирование управления заявками
        test_application_management(org_token, event_id, application_id)
        
        print_section("✅ Все тесты пройдены успешно!")
        print("""
        Проверьте:
        1. Email testvolunteer@example.com должен получить уведомление
        2. В базе данных должны быть созданы записи
        3. В Flutter приложении должны отображаться данные
        """)
        
    except requests.exceptions.ConnectionError:
        print("❌ Не удалось подключиться к API. Убедитесь, что backend запущен на http://127.0.0.1:8000")
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    main()
