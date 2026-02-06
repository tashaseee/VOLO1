from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class EventBase(BaseModel):
    title: str
    organizer: Optional[str] = None
    description: Optional[str] = None
    date_text: Optional[str] = None
    full_date: Optional[datetime] = None
    location: Optional[str] = None
    hours: int = 0
    category: Optional[str] = None
    image_url: Optional[str] = None
    chat_link: Optional[str] = None
    volunteer_count: int = 0
    responsibilities: Optional[str] = None
    benefits: Optional[str] = None

class EventCreate(EventBase):
    pass

class EventOut(EventBase):
    id: int
    is_active: bool
    created_at: datetime
    organizer_id: Optional[int] = None
    approved_count: int = 0

    class Config:
        from_attributes = True

class ApplicationBase(BaseModel):
    event_id: int

class ApplicationCreate(ApplicationBase):
    pass

class ApplicationUpdate(BaseModel):
    status: str

from .user import UserOut

class ApplicationOut(ApplicationBase):
    id: int
    user_id: int
    status: str
    created_at: datetime
    event: Optional[EventOut] = None
    user: Optional[UserOut] = None

    class Config:
        from_attributes = True

class CertificateOut(BaseModel):
    id: int
    event_name: str
    issue_date: datetime
    certificate_url: Optional[str] = None

    class Config:
        from_attributes = True
