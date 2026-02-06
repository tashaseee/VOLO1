from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import user as models
from ..schemas import user as schemas
from ..models import event as event_models # Import Event models
from .users import get_current_user
from ..auth_utils import send_approval_email
from sqlalchemy import func

router = APIRouter(prefix="/admin", tags=["admin"])

def check_admin_role(current_user: models.User = Depends(get_current_user)):
    if current_user.role != "admin":
        # Для удобства тестирования, если в базе еще нет админов, 
        # мы можем временно разрешить доступ или просто выкидывать ошибку.
        # Но по правилам - только админ.
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="У вас нет прав администратора"
        )
    return current_user

@router.get("/pending-organizations")
def get_pending_organizations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role)
):
    # Получаем всех организаторов, которые еще не одобрены
    pending = db.query(models.User).filter(
        models.User.role == "organizer",
        models.User.is_approved == False
    ).all()
    
    results = []
    for user in pending:
        # Пытаемся найти профиль организации для получения названия
        org_profile = db.query(models.OrganizationProfile).filter(
            models.OrganizationProfile.user_id == user.id
        ).first()
        
        results.append({
            "id": user.id,
            "email": user.email,
            "org_name": org_profile.full_name if org_profile else "Не указано",
            "bin": org_profile.bin if org_profile else "Не указано",
            "description": org_profile.description if org_profile else "Не указано",
            "phone": org_profile.phone if org_profile else "Не указано",
            "website": org_profile.website if org_profile else "Не указано",
            "created_at": user.created_at
        })
    
    return results

@router.post("/approve-organization/{user_id}")
async def approve_organization(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
    if user.role != "organizer":
        raise HTTPException(status_code=400, detail="Этот пользователь не является организатором")
    
    if user.is_approved:
        return {"message": "Организация уже одобрена"}
    
    user.is_approved = True
    db.commit()
    
    # Отправляем письмо об одобрении с правилами
    await send_approval_email(user.email)
    
    return {"message": f"Организация {user.email} успешно одобрена, уведомление отправлено"}

@router.post("/make-admin/{email}")
def make_admin(email: str, db: Session = Depends(get_db)):
    """Временный эндпоинт для создания первого админа"""
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
    user.role = "admin"
    db.commit()
    return {"message": f"Пользователь {email} теперь администратор"}

@router.get("/stats")
def get_admin_stats(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role)
):
    total_volunteers = db.query(models.User).filter(models.User.role == "volunteer").count()
    total_organizers = db.query(models.User).filter(models.User.role == "organizer").count()
    total_events = db.query(event_models.Event).count()
    
    # Calculate total hours (this assumes we track hours in profiles, or sum from events)
    # For now, let's sum 'hours' column from Events as 'offered hours' or sum completed events
    total_hours_query = db.query(func.sum(event_models.Event.hours)).scalar()
    total_hours = total_hours_query if total_hours_query else 0
    
    return {
        "volunteers": total_volunteers,
        "organizers": total_organizers,
        "events": total_events,
        "hours": total_hours
    }

@router.get("/users")
def get_all_users(
    skip: int = 0,
    limit: int = 100,
    role: str = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role)
):
    query = db.query(models.User)
    
    if role:
        query = query.filter(models.User.role == role)
        
    users = query.order_by(models.User.created_at.desc()).offset(skip).limit(limit).all()
    
    results = []
    for user in users:
        user_data = {
            "id": user.id,
            "email": user.email,
            "role": user.role,
            "is_active": user.is_active,
            "is_verified": user.is_verified,
            "is_approved": user.is_approved,
            "created_at": user.created_at
        }
        
        # Add profile info if available
        if user.role == "organizer" and user.org_profile:
            user_data["name"] = user.org_profile.full_name
        elif user.profile:
             user_data["name"] = user.profile.full_name
        else:
            user_data["name"] = "Без имени"
            
        results.append(user_data)
        
    return results

@router.get("/events")
def get_all_events(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role)
):
    events = db.query(event_models.Event).order_by(event_models.Event.created_at.desc()).offset(skip).limit(limit).all()
    return events

@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
    # Prevent deleting self
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Нельзя удалить самого себя")
        
    db.delete(user)
    db.commit()
    return {"message": "Пользователь успешно удален"}

@router.delete("/events/{event_id}")
def delete_event(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role)
):
    event = db.query(event_models.Event).filter(event_models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Мероприятие не найдено")
        
    db.delete(event)
    db.commit()
    return {"message": "Мероприятие успешно удалено"}
