# backend/test_api.py
import requests
import json

BASE_URL = "http://localhost:8000"

def test_connection():
    """Проверка подключения к серверу"""
    print("🔗 Проверка подключения к серверу...")
    try:
        response = requests.get(f"{BASE_URL}/")
        print(f"✅ Сервер работает: {response.json()}")
        return True
    except:
        print("❌ Не могу подключиться к серверу")
        print("   Запустите сервер: python -m uvicorn app.main:app --reload")
        return False

def test_registration():
    """Тест регистрации нового пользователя"""
    print("\n📝 Тест регистрации...")
    
    user_data = {
        "email": "test_new_user@example.com",
        "password": "password123",
        "role": "volunteer"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=user_data)
        
        if response.status_code == 200:
            print(f"✅ Регистрация успешна!")
            print(f"   Email: {user_data['email']}")
            print(f"   Проверьте консоль сервера для получения кода")
            return response.json()
        else:
            print(f"❌ Ошибка регистрации: {response.status_code}")
            print(f"   {response.json()}")
            return None
            
    except Exception as e:
        print(f"🚫 Ошибка: {e}")
        return None

def test_login():
    """Тест входа"""
    print("\n🔐 Тест входа...")
    
    login_data = {
        "email": "test@example.com",
        "password": "password123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        
        if response.status_code == 200:
            token = response.json()["access_token"]
            print(f"✅ Вход успешен!")
            print(f"   Токен получен ({len(token)} символов)")
            return token
        else:
            print(f"❌ Ошибка входа: {response.status_code}")
            print(f"   {response.json()}")
            return None
            
    except Exception as e:
        print(f"🚫 Ошибка: {e}")
        return None

def test_user_profile(token):
    """Тест получения профиля"""
    print("\n👤 Тест получения профиля...")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        response = requests.get(f"{BASE_URL}/users/me", headers=headers)
        
        if response.status_code == 200:
            user_data = response.json()
            print(f"✅ Профиль получен!")
            print(f"   Email: {user_data['email']}")
            print(f"   Роль: {user_data['role']}")
            return user_data
        else:
            print(f"❌ Ошибка: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"🚫 Ошибка: {e}")
        return None

if __name__ == "__main__":
    print("🧪 ТЕСТИРОВАНИЕ VOLO API")
    print("="*50)
    
    if test_connection():
        print("\nВыберите тест:")
        print("1. Регистрация нового пользователя")
        print("2. Вход тестового пользователя")
        print("3. Все тесты")
        
        choice = input("\nВаш выбор (1-3): ").strip()
        
        if choice == "1":
            test_registration()
        elif choice == "2":
            token = test_login()
            if token:
                test_user_profile(token)
        elif choice == "3":
            test_registration()
            token = test_login()
            if token:
                test_user_profile(token)
        else:
            print("❌ Неверный выбор")