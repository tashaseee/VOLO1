from .user import UserOut
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class EventBase(BaseModel):
    title: str
    certificate_title: Optional[str] = None
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
    min_age: int = 0


class EventCreate(EventBase):
    pass


class EventOut(EventBase):
    id: int
    is_active: bool
    created_at: Optional[datetime] = None
    organizer_id: Optional[int] = None
    chat_id: Optional[int] = None
    approved_count: int = 0

    class Config:
        from_attributes = True


class ApplicationBase(BaseModel):
    event_id: int


class ApplicationCreate(ApplicationBase):
    pass


class ApplicationUpdate(BaseModel):
    status: str


class ApplicationOut(ApplicationBase):
    id: int
    user_id: Optional[int] = None
    status: Optional[str] = "pending"
    created_at: Optional[datetime] = None
    event: Optional[EventOut] = None
    user: Optional[UserOut] = None

    class Config:
        from_attributes = True


class CertificateOut(BaseModel):
    id: int
    event_id: Optional[int] = None
    event_name: str
    volunteer_name: Optional[str] = None
    organizer_name: Optional[str] = None
    hours: int = 0
    issue_date: Optional[datetime] = None
    certificate_url: Optional[str] = None

    class Config:
        from_attributes = True


class ReviewCreate(BaseModel):
    rating: int
    text: Optional[str] = None


class ReviewOut(BaseModel):
    id: int
    event_id: int
    user_id: int
    user_name: Optional[str] = None
    rating: int
    text: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
