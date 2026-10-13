from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import user as models
from ..models import event as event_models  # Import Event models
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
            detail="У вас нет прав администратора",
        )
    return current_user


@router.get("/pending-organizations")
def get_pending_organizations(
        db: Session = Depends(get_db),
        current_user: models.User = Depends(check_admin_role)):
    # Получаем всех организаторов, которые еще не одобрены
    pending = (
        db.query(
            models.User) .filter(
            models.User.role == "organizer",
            models.User.is_approved == False) .all())

    results = []
    for user in pending:
        # Пытаемся найти профиль организации для получения названия
        org_profile = (
            db.query(models.OrganizationProfile)
            .filter(models.OrganizationProfile.user_id == user.id)
            .first()
        )

        results.append(
            {
                "id": user.id,
                "email": user.email,
                "org_name": org_profile.full_name if org_profile else "Не указано",
                "bin": org_profile.bin if org_profile else "Не указано",
                "description": org_profile.description if org_profile else "Не указано",
                "phone": org_profile.phone if org_profile else "Не указано",
                "website": org_profile.website if org_profile else "Не указано",
                "created_at": user.created_at,
            })

    return results


@router.post("/approve-organization/{user_id}")
async def approve_organization(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    if user.role != "organizer":
        raise HTTPException(
            status_code=400,
            detail="Этот пользователь не является организатором")

    if user.is_approved:
        return {"message": "Организация уже одобрена"}

    user.is_approved = True

    # Extract profile details for contract generation
    org_profile = (
        db.query(models.OrganizationProfile)
        .filter(models.OrganizationProfile.user_id == user.id)
        .first()
    )
    org_name = org_profile.full_name if org_profile else "Партнер"
    org_bin = org_profile.bin if org_profile else "123456789012"

    # Generate contract PDF
    from app.services.contract_generator import generate_organization_contract
    import os

    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    contract_dir = os.path.join(base_dir, "uploads", "contracts")

    try:
        contract_pdf_path = generate_organization_contract(
            org_name=org_name,
            org_bin=org_bin,
            org_email=user.email,
            output_dir=contract_dir,
        )
    except Exception as e:
        print(f"❌ Ошибка генерации контракта: {e}")
        contract_pdf_path = None

    # Create notification
    from app.models.notification import Notification

    org_notif = Notification(
        user_id=user.id,
        title="Профиль одобрен",
        message="Ваш профиль организации успешно одобрен! Теперь вы можете создавать мероприятия. Копия официального договора отправлена на вашу почту.",
        type="success",
    )
    db.add(org_notif)
    db.commit()

    # Отправляем письмо об одобрении с договором
    await send_approval_email(
        user.email, org_name=org_name, contract_path=contract_pdf_path
    )

    return {"message": f"Организация {
            user.email} успешно одобрена, уведомление отправлено"}


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
def get_admin_stats(db: Session = Depends(get_db),
                    current_user: models.User = Depends(check_admin_role)):
    total_volunteers = (
        db.query(models.User).filter(models.User.role == "volunteer").count()
    )
    total_organizers = (
        db.query(models.User).filter(models.User.role == "organizer").count()
    )
    total_events = db.query(event_models.Event).count()

    # Calculate total hours (this assumes we track hours in profiles, or sum from events)
    # For now, let's sum 'hours' column from Events as 'offered hours' or sum
    # completed events
    total_hours_query = db.query(func.sum(event_models.Event.hours)).scalar()
    total_hours = total_hours_query if total_hours_query else 0

    pending_orgs = (
        db.query(models.User)
        .filter(
            models.User.role == "organizer",
            models.User.is_active,
            models.User.is_approved == False,
        )
        .count()
    )

    return {
        "volunteers": total_volunteers,
        "organizers": total_organizers,
        "events": total_events,
        "hours": total_hours,
        "pending_orgs": pending_orgs,
    }


@router.get("/activity")
def get_recent_activity(db: Session = Depends(get_db),
                        current_user: models.User = Depends(check_admin_role)):
    # Fetch 10 most recent important events
    activities = []

    # New registrations
    new_users = (
        db.query(
            models.User).order_by(
            models.User.created_at.desc()).limit(5).all())
    for u in new_users:
        name = "Пользователь"
        if u.role == "organizer" and u.org_profile:
            name = u.org_profile.full_name
        elif u.profile:
            name = u.profile.full_name

        activities.append(
            {
                "type": "registration",
                "user": name,
                "action": f"зарегистрировался как {u.role}",
                "time": u.created_at,
                "id": u.id,
            }
        )

    # New applications
    apps = (
        db.query(event_models.Application)
        .order_by(event_models.Application.created_at.desc())
        .limit(5)
        .all()
    )
    for a in apps:
        name = a.user.profile.full_name if a.user and a.user.profile else "Волонтер"
        event_title = a.event.title if a.event else "мероприятие"
        activities.append(
            {
                "type": "application",
                "user": name,
                "action": f'подал заявку на "{event_title}"',
                "time": a.created_at,
                "id": a.id,
            }
        )

    # New Events
    events = (
        db.query(event_models.Event)
        .order_by(event_models.Event.created_at.desc())
        .limit(5)
        .all()
    )
    for e in events:
        activities.append(
            {
                "type": "event",
                "user": e.organizer or "Организация",
                "action": f'создали новое мероприятие "{e.title}"',
                "time": e.created_at,
                "id": e.id,
            }
        )

    # Sort all by time
    activities.sort(key=lambda x: x["time"], reverse=True)
    return activities[:10]


@router.get("/reports")
def get_reports_data(db: Session = Depends(get_db),
                     current_user: models.User = Depends(check_admin_role)):
    # Category distribution
    categories = (
        db.query(
            event_models.Event.category,
            func.count(
                event_models.Event.id)) .group_by(
            event_models.Event.category) .all())
    category_data = [
        {"name": c[0] if c[0] else "Прочее", "value": c[1]} for c in categories
    ]

    # Growth by month (mocking logic but with real query if dates were structured, let's just count total per role)
    # Volunteer hours by category
    hours_by_cat = (
        db.query(
            event_models.Event.category,
            func.sum(
                event_models.Event.hours)) .group_by(
            event_models.Event.category) .all())
    hours_data = [{"category": h[0] if h[0] else "Прочее",
                   "hours": h[1]} for h in hours_by_cat]

    return {
        "category_distribution": category_data,
        "hours_by_category": hours_data,
        "total_stats": {
            "pending_orgs": db.query(models.User)
            .filter(models.User.role == "organizer", models.User.is_approved == False)
            .count(),
            "active_events": db.query(event_models.Event)
            .filter(event_models.Event.is_active)
            .count(),
            "completed_applications": db.query(event_models.Application)
            .filter(event_models.Application.status == "completed")
            .count(),
        },
    }


@router.get("/users")
def get_all_users(
    skip: int = 0,
    limit: int = 100,
    role: str = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    query = db.query(models.User)

    if role:
        query = query.filter(models.User.role == role)

    users = (query.order_by(models.User.created_at.desc()
                            ).offset(skip).limit(limit).all())

    results = []
    for user in users:
        user_data = {
            "id": user.id,
            "email": user.email,
            "role": user.role,
            "is_active": user.is_active,
            "is_verified": user.is_verified,
            "is_approved": user.is_approved,
            "created_at": user.created_at,
        }

        # Add profile info if available
        if user.role == "organizer" and user.org_profile:
            user_data["name"] = user.org_profile.full_name
            user_data["avatar_url"] = user.org_profile.avatar_url
            user_data["bin"] = user.org_profile.bin
        elif user.profile:
            user_data["name"] = user.profile.full_name
            user_data["avatar_url"] = user.profile.avatar_url
        else:
            user_data["name"] = "Без имени"
            user_data["avatar_url"] = None

        results.append(user_data)

    return results


@router.get("/users/{user_id}")
def get_user_detail(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    result = {
        "id": user.id,
        "email": user.email,
        "role": user.role,
        "is_active": user.is_active,
        "is_verified": user.is_verified,
        "is_approved": user.is_approved,
        "created_at": user.created_at,
        "interests": [i.name for i in user.interests],
        "skills": [s.name for s in user.skills],
    }

    if user.role == "organizer" and user.org_profile:
        result.update(
            {
                "name": user.org_profile.full_name,
                "bin": user.org_profile.bin,
                "description": user.org_profile.description,
                "website": user.org_profile.website,
                "address": user.org_profile.address,
                "phone": user.org_profile.phone,
                "avatar_url": user.org_profile.avatar_url,
            }
        )
    elif user.profile:
        result.update(
            {
                "name": user.profile.full_name,
                "avatar_url": user.profile.avatar_url,
                "birth_date": user.profile.birth_date,
                "gender": user.profile.gender,
                "city": user.profile.city,
                "phone": user.profile.phone,
                "experience": user.profile.experience,
                "motivation": user.profile.motivation,
                "volo_hours": user.profile.volo_hours,
                "events_done": user.profile.events_done,
                "eco_score": user.profile.eco_score,
                "social_score": user.profile.social_score,
                "sport_score": user.profile.sport_score,
                "cultural_score": user.profile.cultural_score,
            }
        )

    return result


@router.post("/users/{user_id}/toggle-active")
def toggle_user_active(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    if user.id == current_user.id:
        raise HTTPException(status_code=400,
                            detail="Нельзя заблокировать самого себя")

    user.is_active = not user.is_active
    db.commit()
    return {
        "message": f"Статус пользователя изменен на {
            'активен' if user.is_active else 'заблокирован'}",
        "is_active": user.is_active,
    }


@router.get("/events")
def get_all_events(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    events = (
        db.query(event_models.Event)
        .order_by(event_models.Event.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return events


@router.get("/events/{event_id}")
def get_event_detail(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    event = (
        db.query(
            event_models.Event).filter(
            event_models.Event.id == event_id).first())
    if not event:
        raise HTTPException(status_code=404, detail="Мероприятие не найдено")
    return event


@router.post("/events/{event_id}/toggle-active")
def toggle_event_active(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    event = (
        db.query(
            event_models.Event).filter(
            event_models.Event.id == event_id).first())
    if not event:
        raise HTTPException(status_code=404, detail="Мероприятие не найдено")

    event.is_active = not event.is_active
    db.commit()
    return {
        "message": f"Статус мероприятия изменен на {
            'активно' if event.is_active else 'заблокировано'}",
        "is_active": event.is_active,
    }


@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    # Prevent deleting self
    if user.id == current_user.id:
        raise HTTPException(
            status_code=400,
            detail="Нельзя удалить самого себя")

    # Delete related reviews first to avoid ForeignKey NotNull Violation
    db.query(event_models.Review).filter(
        event_models.Review.user_id == user_id
    ).delete()

    db.delete(user)
    db.commit()
    return {"message": "Пользователь успешно удален"}


@router.delete("/events/{event_id}")
def delete_event(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_admin_role),
):
    event = (
        db.query(
            event_models.Event).filter(
            event_models.Event.id == event_id).first())
    if not event:
        raise HTTPException(status_code=404, detail="Мероприятие не найдено")

    db.delete(event)
    db.commit()
    return {"message": "Мероприятие успешно удалено"}
