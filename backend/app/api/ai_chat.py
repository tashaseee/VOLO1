from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
import os
import re
from dotenv import load_dotenv
from openai import AsyncOpenAI

load_dotenv()

from app.database import get_db
from app.models.event import Event

router = APIRouter(prefix="/api/ai", tags=["AI Chat"])

from typing import List, Dict, Optional

class ChatRequest(BaseModel):
    message: str
    history: Optional[List[Dict[str, str]]] = []

@router.post("/chat")
async def chat_with_ai(request: ChatRequest, db: Session = Depends(get_db)):
    # 1. Достаем реальные мероприятия из базы
    events = db.query(Event).filter(Event.is_active == True).limit(15).all()
    
    # 2. Детальный контекст:
    events_list = []
    for e in events:
        benefits = str(e.benefits).replace('\n', ', ') if e.benefits else "Volo-часы"
        events_list.append(f"- ID: {e.id} | Название: '{e.title}'\n  Организатор: {e.organizer}\n  Дата: {e.date_text}\n  Адрес: {e.location}\n  Описание: {str(e.description)[:150]}...\n  Бонусы волонтерам: {benefits}")
    events_context = "\n\n".join(events_list)

    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("GROQ_API_KEY")
    is_groq = bool(os.getenv("GROQ_API_KEY"))

    # Инструкция (Промпт) для ИИ
    system_prompt = f"""
Ты — дружелюбный и современный ИИ-помощник платформы VOLO (волонтерское приложение Казахстана).
Твоя цель — подбирать волонтерам лучшие мероприятия, отвечать на вопросы и вовлекать их. 

Действующие ивенты из нашей базы (ПРЕДЛАГАЙ ТОЛЬКО ИХ):
{events_context if events_context else 'Сейчас нет доступных мероприятий. Скажи, что нужно подождать.'}

ПРАВИЛА:
1. Будь ОЧЕНЬ краток и лаконичен! Отвечай буквально 1-3 короткими предложениями. Не пиши длинные монологи!
2. Пиши как живой человек, дружелюбно, используй уместно 1-2 эмодзи.
3. Твой текст отображается в мобильном приложении без поддержки Markdown! НЕ ИСПОЛЬЗУЙ звездочки (**) для жирного текста или решетки (#). Пиши обычным чистым текстом, делай абзацы (переносы строк) для читаемости.
4. Учитывай историю переписки пользователя (она передана в контексте).
5. Опирайся на детали из базы: упоминай бонусы и организатора, ТОЛЬКО когда рассказываешь об ивенте.
6. ОЧЕНЬ ВАЖНО ПРО КАРТОЧКИ: Выводи тег [ID: ...] с номерами ивентов ТОЛЬКО если пользователь ЯВНО ПРОСИТ найти, подобрать или показать мероприятия. Если это обычный разговор (например "Привет", "Как дела?", "Спасибо"), отвечай просто текстом БЕЗ тега [ID: ...]. Не суй карточки в каждое сообщение!
"""

    if not api_key:
        # Если API ключ еще не добавлен, бот работает в "умном демо-режиме"
        return {
            "success": True, 
            "reply": f"Привет! Я работаю в демо-режиме (нужно добавить API-ключ на бэкенд).\nНо я уже вижу базу данных! 🤫\n\nМогу предложить тебе такие ивенты:\n{events_context}"
        }

    try:
        client = AsyncOpenAI(
            api_key=api_key,
            base_url="https://api.groq.com/openai/v1" if is_groq else "https://api.openai.com/v1"
        )
        
        # Формируем цепочку сообщений:
        messages = [{"role": "system", "content": system_prompt}]
        
        # Добавляем историю предыдущих сообщений (ограничиваем последние 6 для экономии токенов)
        if request.history:
            recent_history = request.history[-6:]
            for msg in recent_history:
                # Исключаем системное приветствие если необходимо, но для простоты добавляем все
                role = msg.get("role", "user")
                content = msg.get("content", "")
                if content and role in ["user", "assistant"]:
                    messages.append({"role": role, "content": content})
                    
        # Добавляем текущее сообщение (если оно не дублируется последним из истории)
        if not messages or messages[-1].get("content") != request.message:
            messages.append({"role": "user", "content": request.message})

        completion = await client.chat.completions.create(
            model="llama-3.3-70b-versatile" if is_groq else "gpt-3.5-turbo",
            messages=messages,
            temperature=0.7,
            max_tokens=400
        )
        
        reply = completion.choices[0].message.content
        
        # Парсим рекомендованные ID ивентов
        suggested_events = []
        match = re.search(r'\[ID:\s*([\d,\s]+)\]', reply)
        if match:
            ids_str = match.group(1)
            try:
                ids = [int(x.strip()) for x in ids_str.split(',') if x.strip().isdigit()]
                # Достаем полные данные для карточек
                suggested_db_events = db.query(Event).filter(Event.id.in_(ids)).all()
                for e in suggested_db_events:
                    suggested_events.append({
                        "id": e.id,
                        "title": e.title,
                        "date_text": e.date_text,
                        "location": e.location,
                        "organizer": e.organizer,
                        "image_url": e.image_url,
                        "chat_link": e.chat_link,
                        "description": e.description,
                        "responsibilities": e.responsibilities,
                        "benefits": e.benefits
                    })
            except Exception:
                pass
            
            # Удаляем тег [ID: ...] из ответа, чтобы пользователь его не видел
            reply = re.sub(r'\[ID:\s*[\d,\s]+\]', '', reply).strip()

        return {"success": True, "reply": reply, "events": suggested_events}
    except Exception as e:
        return {"success": False, "reply": f"Ой, произошла ошибка: {str(e)}"}
