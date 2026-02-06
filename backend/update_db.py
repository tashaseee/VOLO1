#!/usr/bin/env python3
"""
Скрипт для обновления базы данных с таблицей уведомлений
"""
import sys
import os

# Добавляем путь к app в PYTHONPATH
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text
from app.models import user as user_models
from app.models import event as event_models
from app.models import notification as notification_models

def update_database():
    print("🔄 Обновление базы данных...")
    
    try:
        # Создаем все таблицы
        user_models.Base.metadata.create_all(bind=engine)
        event_models.Base.metadata.create_all(bind=engine)
        notification_models.Base.metadata.create_all(bind=engine)
        
        print("✅ База данных успешно обновлена!")
        
        # Add new columns manually if they don't exist
        with engine.begin() as conn:
            # chat_link
            try:
                conn.execute(text("ALTER TABLE events ADD COLUMN chat_link VARCHAR"))
                print("   + Добавлена колонка chat_link")
            except Exception as e:
                print(f"   - chat_link уже есть или ошибка: {e}")
            
            # volunteer_count
            try:
                conn.execute(text("ALTER TABLE events ADD COLUMN volunteer_count INTEGER DEFAULT 0"))
                print("   + Добавлена колонка volunteer_count")
            except Exception as e:
                print(f"   - volunteer_count уже есть или ошибка: {e}")
            
            # responsibilities
            try:
                conn.execute(text("ALTER TABLE events ADD COLUMN responsibilities TEXT"))
                print("   + Добавлена колонка responsibilities")
            except Exception as e:
                print(f"   - responsibilities уже есть или ошибка: {e}")
            
            # benefits
            try:
                conn.execute(text("ALTER TABLE events ADD COLUMN benefits TEXT"))
                print("   + Добавлена колонка benefits")
            except Exception as e:
                print(f"   - benefits уже есть или ошибка: {e}")
            
        print("📋 Таблицы:")
        print("   - users")
        print("   - profiles")
        print("   - organization_profiles")
        print("   - events")
        print("   - applications")
        print("   - notifications (новая)")
        print("   - interests")
        print("   - skills")
        
    except Exception as e:
        print(f"❌ Ошибка при обновлении базы данных: {e}")
        sys.exit(1)

if __name__ == "__main__":
    update_database()
