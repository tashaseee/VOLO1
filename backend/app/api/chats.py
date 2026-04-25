from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.models.chat import Chat, ChatMessage
from app.models.user import User
from app.api.users import get_current_user

router = APIRouter(prefix="/api/chats", tags=["Chats"])


class SendMessageRequest(BaseModel):
    text: str


# ─── Мои чаты ────────────────────────────────────────────────────────────────

@router.get("/")
def get_my_chats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    chats = [c for c in current_user.chats]
    result = []
    for chat in chats:
        last_msg = chat.messages[-1] if chat.messages else None
        unread = sum(1 for m in chat.messages if not m.is_read and m.sender_id != current_user.id)
        result.append({
            "id": chat.id,
            "name": chat.name,
            "avatar_url": chat.avatar_url,
            "event_id": chat.event_id,
            "last_message": last_msg.text if last_msg else None,
            "last_message_time": last_msg.created_at.isoformat() if last_msg else None,
            "unread_count": unread,
            "participants_count": len(chat.participants),
        })
    result.sort(key=lambda x: x["last_message_time"] or "", reverse=True)
    return result


# ─── Сообщения чата ───────────────────────────────────────────────────────────

@router.get("/{chat_id}/messages")
def get_chat_messages(
    chat_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    chat = db.query(Chat).filter(Chat.id == chat_id).first()
    if not chat:
        raise HTTPException(status_code=404, detail="Чат не найден")

    if current_user not in chat.participants:
        raise HTTPException(status_code=403, detail="Вы не являетесь участником этого чата")

    # Помечаем все входящие как прочитанные
    for msg in chat.messages:
        if msg.sender_id != current_user.id:
            msg.is_read = True
    db.commit()

    return [
        {
            "id": msg.id,
            "sender_id": msg.sender_id,
            "sender_name": (msg.sender.profile.full_name if msg.sender and msg.sender.profile
                           else (msg.sender.org_profile.full_name if msg.sender and msg.sender.org_profile
                                 else "Пользователь")),
            "sender_avatar": (msg.sender.profile.avatar_url if msg.sender and msg.sender.profile
                              else (msg.sender.org_profile.avatar_url if msg.sender and msg.sender.org_profile
                                    else None)),
            "text": msg.text,
            "is_mine": msg.sender_id == current_user.id,
            "created_at": msg.created_at.isoformat(),
        }
        for msg in chat.messages
    ]


# ─── Отправить сообщение ─────────────────────────────────────────────────────

@router.post("/{chat_id}/messages")
def send_message(
    chat_id: int,
    body: SendMessageRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    chat = db.query(Chat).filter(Chat.id == chat_id).first()
    if not chat:
        raise HTTPException(status_code=404, detail="Чат не найден")

    if current_user not in chat.participants:
        raise HTTPException(status_code=403, detail="Вы не участник чата")

    msg = ChatMessage(
        chat_id=chat_id,
        sender_id=current_user.id,
        text=body.text.strip()
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)

    return {
        "id": msg.id,
        "sender_id": msg.sender_id,
        "text": msg.text,
        "is_mine": True,
        "created_at": msg.created_at.isoformat(),
    }


# ─── Участники чата ───────────────────────────────────────────────────────────

@router.get("/{chat_id}/participants")
def get_participants(
    chat_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    chat = db.query(Chat).filter(Chat.id == chat_id).first()
    if not chat:
        raise HTTPException(status_code=404, detail="Чат не найден")
    if current_user not in chat.participants:
        raise HTTPException(status_code=403, detail="Доступ запрещён")

    return [
        {
            "id": p.id,
            "name": (p.profile.full_name if p.profile else (p.org_profile.full_name if p.org_profile else "Пользователь")),
            "avatar_url": (p.profile.avatar_url if p.profile else (p.org_profile.avatar_url if p.org_profile else None)),
            "role": p.role,
        }
        for p in chat.participants
    ]
