from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import random
import string
from ..database import get_db
from ..models import user as models
from ..schemas import user as schemas
from ..auth_utils import get_password_hash, verify_password, send_verification_email, send_reset_email
from jose import jwt
import os
from datetime import datetime, timedelta

router = APIRouter(prefix="/auth", tags=["auth"])

SECRET_KEY = os.getenv("SECRET_KEY", "yoursecretkeyhere")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

@router.post("/register", response_model=schemas.UserOut)
async def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    email = user.email.lower()
    db_user = db.query(models.User).filter(models.User.email == email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email уже зарегистрирован")
    
    hashed_password = get_password_hash(user.password)
    
    # Generate 6-digit code
    verification_code = ''.join(random.choices(string.digits, k=6))
    
    new_user = models.User(
        email=email, 
        hashed_password=hashed_password, 
        verification_code=verification_code,
        role=user.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Create empty profile for the new user based on role
    if user.role == "organizer":
        if not user.bin or not user.org_name:
            raise HTTPException(status_code=400, detail="Название организации и БИН обязательны для организаторов")
        
        new_profile = models.OrganizationProfile(
            user_id=new_user.id, 
            full_name=user.org_name,
            bin=user.bin
        )
    else:
        new_profile = models.Profile(user_id=new_user.id)
        
    db.add(new_profile)
    db.commit()
    
    print(f"КОД ВЕРИФИКАЦИИ для {email}: {verification_code}") # Для разработки
    await send_verification_email(email, verification_code)
    
    return new_user

@router.post("/verify")
def verify_email(data: schemas.UserVerify, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == data.email.lower()).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
    if user.verification_code == data.code:
        user.is_verified = True
        user.verification_code = None
        db.commit()
        return {"message": "Email успешно подтвержден"}
    else:
        raise HTTPException(status_code=400, detail="Неверный код подтверждения")

@router.post("/forgot-password")
async def forgot_password(data: schemas.UserForgot, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == data.email.lower()).first()
    if not user:
        # Для безопасности не раскрываем существование пользователя
        return {"message": "Если этот email зарегистрирован, код был отправлен."}
    
    # Generate code
    reset_code = ''.join(random.choices(string.digits, k=6))
    user.verification_code = reset_code # Используем verification_code для сброса
    db.commit()
    
    print(f"КОД СБРОСА ПАРОЛЯ для {data.email}: {reset_code}")
    await send_reset_email(data.email, reset_code)
    
    return {"message": "Код сброса отправлен"}

@router.post("/reset-password")
def reset_password(data: schemas.UserReset, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == data.email.lower()).first()
    if not user:
         raise HTTPException(status_code=404, detail="Пользователь не найден")
         
    if user.verification_code != data.code:
        raise HTTPException(status_code=400, detail="Неверный код")
        
    user.hashed_password = get_password_hash(data.new_password)
    user.verification_code = None
    user.is_verified = True # Автоматически подтверждаем email после сброса пароля
    db.commit()
    
    return {"message": "Пароль успешно обновлен"}

@router.post("/login", response_model=schemas.Token)
def login(user_credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    email = user_credentials.email.lower()
    print(f"Попытка входа для email: {email}")
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        print(f"Пользователь не найден: {email}")
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Неверные учетные данные")
    
    if not verify_password(user_credentials.password, user.hashed_password):
        print(f"Неверный пароль для пользователя: {email}")
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Неверные учетные данные")
    
    if not user.is_verified:
        raise HTTPException(status_code=400, detail="Email не подтвержден")
    
    # Мы разрешаем логин даже если не одобрено, чтобы приложение могло показать страницу ожидания
    # if user.role == "organizer" and not user.is_approved:
    #     raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Ваша организация ожидает одобрения администратором")

    print(f"Успешный вход для пользователя: {user_credentials.email}")
    access_token = create_access_token(data={"sub": user.email})
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "role": user.role,
        "is_approved": user.is_approved,
        "is_verified": user.is_verified
    }