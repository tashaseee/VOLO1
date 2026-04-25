from fastapi import APIRouter, Depends, HTTPException, status, Form, File, UploadFile
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import event as models
from ..models import user as user_models
from ..models.notification import Notification
from ..schemas import event as schemas
from .users import get_current_user
from ..auth_utils import send_application_status_email
from typing import List, Optional
import os
import shutil
from datetime import datetime

router = APIRouter(prefix="/events", tags=["events"])

@router.post("/", response_model=schemas.EventOut)
async def create_event(
    title: str = Form(...),
    description: str = Form(...),
    location: str = Form(...),
    date_text: str = Form(...),
    hours: int = Form(...),
    category: str = Form(...),
    chat_link: str = Form(...),
    volunteer_count: int = Form(...),
    responsibilities: str = Form(...),
    benefits: str = Form(...),
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user)
):
    # Use organization name from profile
    organizer_name = ""
    if current_user.org_profile:
        organizer_name = current_user.org_profile.full_name
    if not organizer_name:
        organizer_name = "Unknown Organization"

    # Handle image upload
    image_url = None
    if image:
        # Create uploads directory if it doesn't exist
        upload_dir = "uploads/events"
        os.makedirs(upload_dir, exist_ok=True)
        
        # Generate unique filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_extension = os.path.splitext(image.filename)[1]
        filename = f"event_{timestamp}_{current_user.id}{file_extension}"
        file_path = os.path.join(upload_dir, filename)
        
        # Save file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        # Store relative path for URL
        image_url = f"/uploads/events/{filename}"

    new_event = models.Event(
        title=title,
        description=description,
        location=location,
        date_text=date_text,
        hours=hours,
        category=category,
        chat_link=chat_link,
        volunteer_count=volunteer_count,
        responsibilities=responsibilities,
        benefits=benefits,
        image_url=image_url,
        organizer=organizer_name,
        organizer_id=current_user.id
    )
    db.add(new_event)
    db.commit()
    db.refresh(new_event)
    return new_event

@router.get("/", response_model=List[schemas.EventOut])
def get_events(db: Session = Depends(get_db)):
    events = db.query(models.Event).filter(models.Event.is_active == True).all()
    # If no events, create some mock events for demonstration if needed, 
    # but now we want real DB events. 
    # Keeping mock creation only if completely empty for backwards compatibility? 
    # Better to just return empty list or real events.
    if not events: 
       # Fallback to existing mocks if absolutely nothing exists, but better to let them create.
       pass
    return events

@router.get("/my-events", response_model=List[schemas.EventOut])
def get_my_events(db: Session = Depends(get_db), current_user: user_models.User = Depends(get_current_user)):
    events = db.query(models.Event).filter(models.Event.organizer_id == current_user.id).all()
    for event in events:
        event.approved_count = db.query(models.Application).filter(
            models.Application.event_id == event.id,
            models.Application.status == "approved"
        ).count()
    return events

@router.get("/{event_id}/applications", response_model=List[schemas.ApplicationOut])
def get_event_applications(event_id: int, db: Session = Depends(get_db), current_user: user_models.User = Depends(get_current_user)):
    # Verify event belongs to user
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    if event.organizer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view these applications")
    
    return db.query(models.Application).filter(models.Application.event_id == event_id).all()

@router.put("/applications/{application_id}/status", response_model=schemas.ApplicationOut)
async def update_application_status(
    application_id: int, 
    status_update: schemas.ApplicationUpdate,
    db: Session = Depends(get_db), 
    current_user: user_models.User = Depends(get_current_user)
):
    application = db.query(models.Application).filter(models.Application.id == application_id).first()
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")
    
    event = application.event
    if event.organizer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to manage this application")
    
    application.status = status_update.status
    db.commit()
    db.refresh(application)
    
    user = db.query(user_models.User).filter(user_models.User.id == application.user_id).first()
    if user:
        await send_application_status_email(user.email, event.title, status_update.status)
        
        from app.models.notification import Notification
        from app.models.chat import Chat

        if status_update.status == "approved":
            # ── 1. Создаём или находим чат события ──────────────────────────
            chat = db.query(Chat).filter(Chat.event_id == event.id).first()
            if not chat:
                chat = Chat(
                    event_id=event.id,
                    name=event.title,
                    avatar_url=event.image_url,
                )
                db.add(chat)
                db.flush()  # получаем chat.id

                # Добавляем организатора в чат
                organizer = db.query(user_models.User).filter(user_models.User.id == event.organizer_id).first()
                if organizer and organizer not in chat.participants:
                    chat.participants.append(organizer)

            # Добавляем волонтёра в чат
            if user not in chat.participants:
                chat.participants.append(user)

            db.commit()

            # ── 2. Красивое уведомление ─────────────────────────────────────
            notification = Notification(
                user_id=user.id,
                title="Вы приняты! 🎉",
                message=f"Поздравляем! Вы стали волонтёром на мероприятии «{event.title}». Вас добавили в чат участников — заходите и знакомьтесь с командой!",
                type="approved",
                related_id=chat.id,   # ← ID чата для прямого перехода
            )

        elif status_update.status == "rejected":
            notification = Notification(
                user_id=user.id,
                title="Заявка отклонена",
                message=f"К сожалению, ваша заявка на мероприятие «{event.title}» была отклонена.",
                type="error",
                related_id=application.id,
            )
        else:
            notification = Notification(
                user_id=user.id,
                title="Статус заявки обновлён",
                message=f"Статус вашей заявки на «{event.title}» изменился на: {status_update.status}.",
                type="info",
                related_id=application.id,
            )

        db.add(notification)
        db.commit()
    
    return application

@router.post("/{event_id}/apply", response_model=schemas.ApplicationOut)
def apply_to_event(event_id: int, db: Session = Depends(get_db), current_user: user_models.User = Depends(get_current_user)):
    # Check if event exists
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check if already applied
    existing_application = db.query(models.Application).filter(
        models.Application.event_id == event_id,
        models.Application.user_id == current_user.id
    ).first()
    if existing_application:
        raise HTTPException(status_code=400, detail="Already applied to this event")
    
    new_application = models.Application(user_id=current_user.id, event_id=event_id)
    db.add(new_application)
    db.commit()
    db.refresh(new_application)
    
    # Create notification for the volunteer
    from app.models.notification import Notification
    user_notif = Notification(
        user_id=current_user.id,
        title="Заявка подана",
        message=f"Ваша заявка на мероприятие '{event.title}' успешно отправлена. Ожидайте ответа от организатора.",
        type="info",
        related_id=new_application.id
    )
    db.add(user_notif)
    
    # Create notification for the organizer
    org_notif = Notification(
        user_id=event.organizer_id,
        title="Новая заявка",
        message=f"Поступила новая заявка на ваше мероприятие '{event.title}'.",
        type="info",
        related_id=new_application.id
    )
    db.add(org_notif)
    db.commit()
    
    return new_application

@router.get("/my-applications", response_model=List[schemas.ApplicationOut])
def get_my_applications(db: Session = Depends(get_db), current_user: user_models.User = Depends(get_current_user)):
    return db.query(models.Application).filter(models.Application.user_id == current_user.id).all()

@router.post("/{application_id}/complete")
def complete_event(application_id: int, db: Session = Depends(get_db)):
    # This would normally be an organizer action (or admin)
    application = db.query(models.Application).filter(models.Application.id == application_id).first()
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")
    
    if application.status == "completed":
        return {"message": "Event already completed"}
    
    application.status = "completed"
    
    # Grant hours and update stats
    event = application.event
    user_profile = db.query(user_models.Profile).filter(user_models.Profile.user_id == application.user_id).first()
    if user_profile:
        user_profile.volo_hours += event.hours
        user_profile.events_done += 1
        
        # Increment category specific score
        cat = (event.category or "").lower()
        if "eco" in cat:
            user_profile.eco_score += 1
        elif "sport" in cat:
            user_profile.sport_score += 1
        elif "social" in cat:
            user_profile.social_score += 1
        elif "cultural" in cat:
            user_profile.cultural_score += 1
    
    # Generate certificate record
    certificate = models.Certificate(
        user_id=application.user_id,
        event_name=event.title,
        certificate_url=f"https://volo.kz/certs/{application.id}"
    )
    db.add(certificate)
    db.commit()
    
    return {"message": "Success", "hours_added": event.hours}

@router.post("/{event_id}/finish")
def finish_event(event_id: int, db: Session = Depends(get_db), current_user: user_models.User = Depends(get_current_user)):
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Verify organizer
    if event.organizer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # If already inactive/completed, maybe return error or success?
    if not event.is_active:
         pass # Already finished
         
    event.is_active = False
    
    # Process all approved applications
    approved_apps = db.query(models.Application).filter(
        models.Application.event_id == event_id,
        models.Application.status == "approved"
    ).all()
    
    count_finished = 0
    for app in approved_apps:
        # Avoid double counting if run multiple times
        # We can introduce a new status 'completed_pending_review' or just 'completed'
        if app.status == "approved":
            app.status = "completed" # Mark as completed so we don't grant hours again
            
            # Grant hours
            profile = app.user.profile
            if profile:
                profile.volo_hours += event.hours
                profile.events_done += 1
            
            # Create Notification
            msg = f"Ивент '{event.title}' завершен! Вам начислено {event.hours} часов. Пожалуйста, оцените организатора, чтобы получить сертификат."
            notif = Notification(
                user_id=app.user_id,
                title="Ивент завершен! 🎉",
                message=msg,
                type="success", # Using success type for green color
                related_id=event.id
            )
            db.add(notif)
            
            # Create Certificate (Initially visible but maybe locked? For simplicity unlocked now)
            # User requirement: "they must assess event first".
            # So maybe we creates a "Pending Certificate" logic or just rely on frontend check.
            # Let's create the certificate record but frontend will block "Download" until rated.
            cert = models.Certificate(
                user_id=app.user_id,
                event_name=event.title,
                certificate_url="generated_id_123" # Mock ID
            )
            db.add(cert)
            
            count_finished += 1
            
    db.commit()
    return {"success": True, "message": f"Ивент завершен. {count_finished} волонтеров получили часы."}

@router.put("/{event_id}/toggle-status")
def toggle_event_status(event_id: int, db: Session = Depends(get_db), current_user: user_models.User = Depends(get_current_user)):
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    if event.organizer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    event.is_active = not event.is_active
    db.commit()
    db.refresh(event)
    return {"id": event.id, "is_active": event.is_active}

@router.get("/my-certificates", response_model=List[schemas.CertificateOut])
def get_my_certificates(db: Session = Depends(get_db), current_user: user_models.User = Depends(get_current_user)):
    return db.query(models.Certificate).filter(models.Certificate.user_id == current_user.id).all()
