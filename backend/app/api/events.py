from fastapi import APIRouter, Depends, HTTPException, Form, File, UploadFile
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
from datetime import datetime, timedelta

router = APIRouter(prefix="/events", tags=["events"])


def parse_event_datetime(date_text: str) -> Optional[datetime]:
    if not date_text:
        return None
    try:
        # Expected format: "DD.MM.YYYY | HH:MM"
        parts = date_text.split("|")
        date_str = parts[0].strip()
        time_str = parts[1].strip() if len(parts) > 1 else "00:00"
        return datetime.strptime(f"{date_str} {time_str}", "%d.%m.%Y %H:%M")
    except Exception:
        try:
            return datetime.fromisoformat(date_text)
        except Exception:
            return None


def get_event_time_range(event) -> tuple[datetime, datetime]:
    start_dt = event.full_date
    if not start_dt and event.date_text:
        start_dt = parse_event_datetime(event.date_text)
    if not start_dt:
        start_dt = datetime.min

    duration_hours = event.hours if event.hours else 0
    end_dt = start_dt + (timedelta(hours=duration_hours)
                         if start_dt != datetime.min else timedelta())
    return start_dt, end_dt


def check_time_overlap(
    start1: datetime, end1: datetime, start2: datetime, end2: datetime
) -> bool:
    if start1 == datetime.min or start2 == datetime.min:
        return False
    return start1 < end2 and start2 < end1


def _volunteer_display_name(user: user_models.User) -> str:
    if user.profile and user.profile.full_name:
        return user.profile.full_name
    return user.email.split("@")[0]


@router.post("/", response_model=schemas.EventOut)
async def create_event(
    title: str = Form(...),
    description: str = Form(...),
    location: str = Form(...),
    date_text: str = Form(...),
    hours: int = Form(...),
    category: str = Form(...),
    chat_link: str = Form(""),
    volunteer_count: int = Form(...),
    responsibilities: str = Form(""),
    benefits: str = Form(""),
    certificate_title: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    min_age: int = Form(0),
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
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

    cert_title = (certificate_title or "").strip() or title

    new_event = models.Event(
        title=title,
        certificate_title=cert_title,
        description=description,
        location=location,
        date_text=date_text,
        full_date=parse_event_datetime(date_text),
        hours=hours,
        category=category,
        chat_link=chat_link or "",
        volunteer_count=volunteer_count,
        responsibilities=responsibilities,
        benefits=benefits,
        image_url=image_url,
        organizer=organizer_name,
        organizer_id=current_user.id,
        min_age=min_age,
    )
    db.add(new_event)
    db.commit()
    db.refresh(new_event)

    # ─── СОЗДАЁМ ЧАТ ДЛЯ ИВЕНТА ──────────────────────────────────────────────
    from app.models.chat import Chat

    new_chat = Chat(
        event_id=new_event.id,
        name=new_event.title,
        avatar_url=new_event.image_url)
    db.add(new_chat)
    db.flush()  # Получаем ID

    # Добавляем организатора как первого участника
    new_chat.participants.append(current_user)
    db.commit()

    return new_event


@router.get("/", response_model=List[schemas.EventOut])
def get_events(db: Session = Depends(get_db)):
    events = db.query(models.Event).filter(models.Event.is_active).all()
    # If no events, create some mock events for demonstration if needed,
    # but now we want real DB events.
    # Keeping mock creation only if completely empty for backwards compatibility?
    # Better to just return empty list or real events.
    if not events:
        # Fallback to existing mocks if absolutely nothing exists, but better
        # to let them create.
        pass
    return events


@router.get("/my-events", response_model=List[schemas.EventOut])
def get_my_events(
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    events = (
        db.query(models.Event)
        .filter(models.Event.organizer_id == current_user.id)
        .all()
    )
    for event in events:
        event.approved_count = (
            db.query(models.Application)
            .filter(
                models.Application.event_id == event.id,
                models.Application.status == "approved",
            )
            .count()
        )
    return events


@router.get("/{event_id}/applications",
            response_model=List[schemas.ApplicationOut])
def get_event_applications(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    # Verify event belongs to user
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    if event.organizer_id != current_user.id:
        raise HTTPException(
            status_code=403, detail="Not authorized to view these applications"
        )

    return (
        db.query(models.Application)
        .filter(models.Application.event_id == event_id)
        .all()
    )


@router.put("/applications/{application_id}/status",
            response_model=schemas.ApplicationOut)
async def update_application_status(
    application_id: int,
    status_update: schemas.ApplicationUpdate,
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    application = (
        db.query(models.Application)
        .filter(models.Application.id == application_id)
        .with_for_update()
        .first()
    )
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")

    event = application.event
    if event.organizer_id != current_user.id:
        raise HTTPException(
            status_code=403, detail="Not authorized to manage this application"
        )

    # Idempotency check: if status is already updated, do not process
    # notifications/emails again
    if application.status == status_update.status:
        return application

    if status_update.status == "approved":
        # Check for time conflicts with other approved events for this
        # volunteer
        target_start, target_end = get_event_time_range(event)
        other_approved_apps = (
            db.query(models.Application)
            .filter(
                models.Application.user_id == application.user_id,
                models.Application.status == "approved",
                models.Application.id != application.id,
            )
            .all()
        )
        for other_app in other_approved_apps:
            other_start, other_end = get_event_time_range(other_app.event)
            if check_time_overlap(
                    target_start,
                    target_end,
                    other_start,
                    other_end):
                raise HTTPException(
                    status_code=400,
                    detail=f"Волонтер уже одобрен на другое пересекающееся мероприятие «{
                        other_app.event.title}» ({
                        other_app.event.date_text}).",
                )

    application.status = status_update.status
    db.commit()
    db.refresh(application)

    user = (
        db.query(user_models.User)
        .filter(user_models.User.id == application.user_id)
        .first()
    )
    if user:
        await send_application_status_email(
            user.email, event.title, status_update.status
        )

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
                organizer = (
                    db.query(user_models.User)
                    .filter(user_models.User.id == event.organizer_id)
                    .first()
                )
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
                message=f"Поздравляем! Вы стали волонтёром на мероприятии «{
                    event.title}». Вас добавили в чат участников — заходите и знакомьтесь с командой!",
                type="approved",
                related_id=chat.id,  # ← ID чата для прямого перехода
            )

        elif status_update.status == "rejected":
            notification = Notification(
                user_id=user.id,
                title="Заявка отклонена",
                message=f"К сожалению, ваша заявка на мероприятие «{
                    event.title}» была отклонена.",
                type="error",
                related_id=application.id,
            )
        else:
            notification = Notification(
                user_id=user.id,
                title="Статус заявки обновлён",
                message=f"Статус вашей заявки на «{
                    event.title}» изменился на: {
                    status_update.status}.",
                type="info",
                related_id=application.id,
            )

        db.add(notification)
        db.commit()

    return application


@router.post("/{event_id}/apply", response_model=schemas.ApplicationOut)
def apply_to_event(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    # Check if event exists
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Check age restriction
    if event.min_age and event.min_age > 0:
        if not current_user.profile or not current_user.profile.birth_date:
            raise HTTPException(
                status_code=400,
                detail="Для подачи заявки необходимо указать дату рождения в профиле",
            )
        birth = current_user.profile.birth_date
        today = datetime.utcnow().date()
        age = (
            today.year
            - birth.year
            - ((today.month, today.day) < (birth.month, birth.day))
        )
        if age < event.min_age:
            raise HTTPException(
                status_code=400,
                detail=f"Для участия в этом мероприятии вам должно быть не менее {
                    event.min_age} лет. Ваш возраст: {age}.",
            )

    # Check if already applied
    existing_application = (
        db.query(models.Application)
        .filter(
            models.Application.event_id == event_id,
            models.Application.user_id == current_user.id,
        )
        .first()
    )
    if existing_application:
        raise HTTPException(status_code=400,
                            detail="Already applied to this event")

    # Check for time conflicts with other approved events
    target_start, target_end = get_event_time_range(event)
    approved_apps = (
        db.query(models.Application)
        .filter(
            models.Application.user_id == current_user.id,
            models.Application.status == "approved",
        )
        .all()
    )
    for app in approved_apps:
        other_start, other_end = get_event_time_range(app.event)
        if check_time_overlap(
                target_start,
                target_end,
                other_start,
                other_end):
            raise HTTPException(
                status_code=400,
                detail=f"Вы уже одобрены на мероприятие «{
                    app.event.title}» в этот же промежуток времени ({
                    app.event.date_text}).",
            )

    new_application = models.Application(
        user_id=current_user.id, event_id=event_id)
    db.add(new_application)
    db.commit()
    db.refresh(new_application)

    # Create notification for the volunteer
    from app.models.notification import Notification

    user_notif = Notification(
        user_id=current_user.id,
        title="Заявка подана",
        message=f"Ваша заявка на мероприятие '{
            event.title}' успешно отправлена. Ожидайте ответа от организатора.",
        type="info",
        related_id=new_application.id,
    )
    db.add(user_notif)

    # Create notification for the organizer
    org_notif = Notification(
        user_id=event.organizer_id,
        title="Новая заявка",
        message=f"Поступила новая заявка на ваше мероприятие '{event.title}'.",
        type="info",
        related_id=new_application.id,
    )
    db.add(org_notif)
    db.commit()

    return new_application


@router.get("/my-applications", response_model=List[schemas.ApplicationOut])
def get_my_applications(
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    return (
        db.query(models.Application)
        .filter(models.Application.user_id == current_user.id)
        .all()
    )


@router.post("/{application_id}/complete")
def complete_event(application_id: int, db: Session = Depends(get_db)):
    # This would normally be an organizer action (or admin)
    application = (
        db.query(models.Application)
        .filter(models.Application.id == application_id)
        .first()
    )
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")

    if application.status == "completed":
        return {"message": "Event already completed"}

    application.status = "completed"

    # Grant hours and update stats
    event = application.event
    user_profile = (
        db.query(user_models.Profile)
        .filter(user_models.Profile.user_id == application.user_id)
        .first()
    )
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
        certificate_url=f"https://volo.kz/certs/{application.id}",
    )
    db.add(certificate)
    db.commit()

    return {"message": "Success", "hours_added": event.hours}


@router.post("/{event_id}/finish")
async def finish_event(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    from app.services.certificate_generator import generate_personalized_certificate

    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    if event.organizer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    event.is_active = False

    org_profile = current_user.org_profile
    template_url = org_profile.certificate_template_url if org_profile else None
    org_name = (
        org_profile.full_name
        if org_profile and org_profile.full_name
        else event.organizer
    )
    org_bin = org_profile.bin if org_profile and org_profile.bin else "123456789012"
    cert_event_title = event.certificate_title or event.title

    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    cert_output_dir = os.path.join(base_dir, "uploads", "certificates")

    approved_apps = (
        db.query(models.Application)
        .filter(
            models.Application.event_id == event_id,
            models.Application.status == "approved",
        )
        .all()
    )

    count_finished = 0
    for app in approved_apps:
        if app.status != "approved":
            continue
        app.status = "completed"

        profile = app.user.profile
        if profile:
            profile.volo_hours += event.hours
            profile.events_done += 1
            cat = (event.category or "").lower()
            if "эко" in cat or "eco" in cat:
                profile.eco_score += 1
            elif "спорт" in cat or "sport" in cat:
                profile.sport_score += 1
            elif "социал" in cat or "social" in cat:
                profile.social_score += 1
            elif "культур" in cat or "cultural" in cat:
                profile.cultural_score += 1

        volunteer_name = _volunteer_display_name(app.user)

        cert_url, _ = await generate_personalized_certificate(
            template_url=template_url,
            volunteer_name=volunteer_name,
            event_title=cert_event_title,
            org_name=org_name or "VOLO",
            org_bin=org_bin,
            event_date=event.date_text or datetime.now().strftime("%d.%m.%Y"),
            hours=event.hours,
            output_dir=cert_output_dir,
            base_dir=base_dir,
        )

        cert = models.Certificate(
            user_id=app.user_id,
            event_id=event.id,
            event_name=cert_event_title,
            volunteer_name=volunteer_name,
            organizer_name=org_name,
            hours=event.hours,
            certificate_url=cert_url,
        )
        db.add(cert)

        notif = Notification(
            user_id=app.user_id,
            title="Ваш сертификат готов! 🎓",
            message=(
                f"Ивент «{event.title}» завершён. +{event.hours} ч. "
                f"Персональный сертификат уже в профиле — откройте «Мои сертификаты»."
            ),
            type="success",
            related_id=event.id,
        )
        db.add(notif)
        count_finished += 1

    db.commit()
    return {
        "success": True,
        "message": f"Ивент завершён. {count_finished} волонтёров получили часы и AI-сертификаты.",
        "certificates_issued": count_finished,
    }


@router.put("/{event_id}/toggle-status")
def toggle_event_status(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
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
def get_my_certificates(
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    return (
        db.query(models.Certificate)
        .filter(models.Certificate.user_id == current_user.id)
        .all()
    )


@router.post("/{event_id}/reviews", response_model=dict)
def create_event_review(
    event_id: int,
    review: schemas.ReviewCreate,
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    # Check that event exists
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Мероприятие не найдено")

    # Check if the user has a completed application for this event
    app = (
        db.query(models.Application)
        .filter(
            models.Application.event_id == event_id,
            models.Application.user_id == current_user.id,
            models.Application.status == "completed",
        )
        .first()
    )
    if not app:
        raise HTTPException(
            status_code=403,
            detail="Вы можете оставлять отзывы только для мероприятий, в которых вы принимали участие",
        )

    # Check if user already reviewed
    existing_review = (
        db.query(
            models.Review) .filter(
            models.Review.event_id == event_id,
            models.Review.user_id == current_user.id) .first())
    if existing_review:
        raise HTTPException(
            status_code=400,
            detail="Вы уже оставили отзыв для этого мероприятия")

    # Create the review
    db_review = models.Review(
        event_id=event_id,
        user_id=current_user.id,
        rating=review.rating,
        text=review.text,
    )
    db.add(db_review)
    db.commit()
    return {"success": True, "message": "Отзыв успешно добавлен"}


@router.get("/{event_id}/reviews", response_model=List[schemas.ReviewOut])
def get_event_reviews(event_id: int, db: Session = Depends(get_db)):
    reviews = (
        db.query(models.Review)
        .filter(models.Review.event_id == event_id)
        .order_by(models.Review.created_at.desc())
        .all()
    )

    result = []
    for r in reviews:
        user_name = (
            r.user.profile.full_name
            if (r.user and r.user.profile)
            else (r.user.email if r.user else "Волонтер")
        )
        result.append(
            schemas.ReviewOut(
                id=r.id,
                event_id=r.event_id,
                user_id=r.user_id,
                user_name=user_name,
                rating=r.rating,
                text=r.text,
                created_at=r.created_at,
            )
        )
    return result
