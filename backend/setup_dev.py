# backend/setup_dev.py
import os
import sys
from pathlib import Path

# Добавляем путь для импортов
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'app'))

def setup_development():
    """Настройка среды разработки"""
    print("🚀 НАСТРОЙКА VOLO ДЛЯ РАЗРАБОТКИ")
    print("="*50)
    
    # Проверяем .env
    env_file = Path(".env")
    if env_file.exists():
        print("✅ Файл .env найден")
        
        # Проверяем ENVIRONMENT
        with open(env_file, 'r') as f:
            content = f.read()
            if "ENVIRONMENT=development" in content:
                print("✅ Режим разработки включен")
            else:
                print("⚠️  Добавьте 'ENVIRONMENT=development' в .env")
    else:
        print("❌ Файл .env не найден!")
        return False
    
    # Проверяем импорты
    try:
        from app.database import SessionLocal
        from app.models.user import User, Profile, OrganizationProfile, Interest, Skill
        from app.models.event import Event, Application, Certificate
        from app.models.chat import Chat, ChatMessage
        from app.models.notification import Notification
        from app.auth_utils import get_password_hash
        
        print("✅ Импорты работают правильно")
        
        # Проверяем БД
        db = SessionLocal()
        try:
            users = db.query(User).all()
            print(f"✅ Подключение к БД успешно. Пользователей: {len(users)}")
            
            # Создаем тестового пользователя если нет
            test_email = "test@example.com"
            existing = db.query(User).filter(User.email == test_email).first()
            
            if not existing:
                print(f"\n➕ Создаю тестового пользователя: {test_email}")
                test_user = User(
                    email=test_email,
                    hashed_password=get_password_hash("password123"),
                    role="volunteer",
                    is_verified=True
                )
                db.add(test_user)
                db.commit()
                print(f"✅ Тестовый пользователь создан")
                print(f"   Email: {test_email}")
                print(f"   Пароль: password123")
            else:
                print(f"✅ Тестовый пользователь уже существует")
                
        except Exception as e:
            print(f"❌ Ошибка при работе с БД: {e}")
        finally:
            db.close()
            
    except ImportError as e:
        print(f"❌ Ошибка импорта: {e}")
        return False
    
    print("\n" + "="*50)
    print("🎯 ИНСТРУКЦИЯ ДЛЯ РАЗРАБОТКИ")
    print("="*50)
    print("\n📋 КАК РАБОТАТЬ:")
    print("1. Запустите сервер из папки 'backend':")
    print("   cd backend")
    print("   python -m uvicorn app.main:app --reload")
    print("\n2. Тестируйте регистрацию:")
    print("   Email: aminakazanbasova@icloud.com")
    print("   Или любой другой email")
    print("\n3. Код верификации появится в консоли сервера")
    print("   (не будет отправляться на реальный email)")
    print("\n4. Для API документации откройте:")
    print("   http://localhost:8000/docs")
    print("\n" + "="*50)
    
    return True

if __name__ == "__main__":
    setup_development()