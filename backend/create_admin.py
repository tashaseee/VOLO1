from app.database import SessionLocal
# Import ALL models to ensure SQLAlchemy registry is populated
from app.models import user as user_models
from app.models import event as event_models
from app.models import notification as notification_models
import bcrypt

def create_admin_user():
    db = SessionLocal()
    email = "admin@volo.kz"
    password = "admin"
    
    # Generate hash directly to avoid passlib issues in script
    hashed_password_bytes = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    hashed_password = hashed_password_bytes.decode('utf-8')
    
    existing_user = db.query(user_models.User).filter(user_models.User.email == email).first()
    
    if existing_user:
        print(f"Пользователь {email} найден.")
        if existing_user.role != "admin":
            print(f"Обновляем роль на 'admin'.")
            existing_user.role = "admin"
        
        # Always reset password to 'admin' so the user definitely knows it
        existing_user.hashed_password = hashed_password
        db.commit()
        
        print(f"Пароль сброшен на '{password}'")
    else:
        print(f"Создаем нового администратора: {email}")
        new_user = user_models.User(
            email=email,
            hashed_password=hashed_password,
            role="admin",
            is_verified=True,
            is_approved=True
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        # Create profile
        profile = user_models.Profile(user_id=new_user.id, full_name="Admin")
        db.add(profile)
        db.commit()
        
    print("-" * 30)
    print("ДАННЫЕ ДЛЯ ВХОДА В АДМИН ПАНЕЛЬ:")
    print(f"Email:    {email}")
    print(f"Пароль:   {password}")
    print("-" * 30)

if __name__ == "__main__":
    create_admin_user()
