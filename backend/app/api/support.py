from fastapi import APIRouter, Depends, HTTPException, Form
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import user as user_models
from ..models.support import SupportRequest
from .users import get_current_user
from typing import List
from datetime import datetime

router = APIRouter(prefix="/support", tags=["support"])


@router.post("/", response_model=dict)
def create_support_request(
    message: str = Form(...),
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    if not message.strip():
        raise HTTPException(status_code=400,
                            detail="Сообщение не может быть пустым")

    req = SupportRequest(user_id=current_user.id, message=message.strip())
    db.add(req)
    db.commit()
    db.refresh(req)
    return {"success": True, "id": req.id, "message": "Запрос отправлен"}


@router.get("/my", response_model=List[dict])
def get_my_support_requests(
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(get_current_user),
):
    requests = (
        db.query(SupportRequest)
        .filter(SupportRequest.user_id == current_user.id)
        .order_by(SupportRequest.created_at.desc())
        .all()
    )
    return [
        {
            "id": r.id,
            "message": r.message,
            "reply": r.reply,
            "status": r.status,
            "created_at": r.created_at.isoformat(),
            "replied_at": r.replied_at.isoformat() if r.replied_at else None,
        }
        for r in requests
    ]


# Admin roles check
def check_admin_role(
        current_user: user_models.User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403,
                            detail="У вас нет прав администратора")
    return current_user


@router.get("/all", response_model=List[dict])
def get_all_support_requests(
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(check_admin_role),
):
    requests = db.query(SupportRequest).order_by(
        SupportRequest.created_at.desc()).all()
    result = []
    for r in requests:
        user_email = r.user.email if r.user else "Неизвестно"
        user_name = (r.user.profile.full_name if (
            r.user and r.user.profile) else user_email)
        result.append({"id": r.id,
                       "user_id": r.user_id,
                       "user_name": user_name,
                       "user_email": user_email,
                       "message": r.message,
                       "reply": r.reply,
                       "status": r.status,
                       "created_at": r.created_at.isoformat(),
                       "replied_at": r.replied_at.isoformat() if r.replied_at else None,
                       })
    return result


@router.post("/{request_id}/reply", response_model=dict)
def reply_to_support_request(
    request_id: int,
    reply: str = Form(...),
    db: Session = Depends(get_db),
    current_user: user_models.User = Depends(check_admin_role),
):
    req = db.query(SupportRequest).filter(
        SupportRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Запрос не найден")

    req.reply = reply.strip()
    req.status = "resolved"
    req.replied_at = datetime.utcnow()
    db.commit()

    # Create notification for the volunteer user
    from app.models.notification import Notification

    user_notif = Notification(
        user_id=req.user_id,
        title="Ответ техподдержки",
        message=f"На ваш запрос был отправлен ответ: {reply.strip()}",
        type="info",
        related_id=req.id,
    )
    db.add(user_notif)
    db.commit()

    return {"success": True, "message": "Ответ отправлен"}
