from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    Text,
    ForeignKey,
    DateTime,
)
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime


class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    certificate_title = Column(
        String, nullable=True
    )  # Text printed on volunteer certificates
    organizer = Column(
        String, nullable=True
    )  # Display name of organization (optional if we use relation)
    organizer_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE")
    )  # Link to the user who created it
    description = Column(Text)
    date_text = Column(String)  # For display like "25 Oct"
    full_date = Column(DateTime)
    location = Column(String)
    hours = Column(Integer, default=0)
    category = Column(String)  # e.g., 'Eco', 'Sport', 'Social', 'Cultural'
    image_url = Column(String)
    chat_link = Column(String)
    volunteer_count = Column(Integer, default=0)
    responsibilities = Column(Text)
    benefits = Column(Text)
    is_active = Column(Boolean, default=True)
    min_age = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    @property
    def chat_id(self):
        return self.chat.id if self.chat else None

    organizer_user = relationship("User", backref="organized_events")
    applications = relationship("Application", back_populates="event")


class Application(Base):
    __tablename__ = "applications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    event_id = Column(Integer, ForeignKey("events.id", ondelete="CASCADE"))
    # pending, approved, rejected, completed
    status = Column(String, default="pending")
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="applications")
    event = relationship("Event", back_populates="applications")


class Certificate(Base):
    __tablename__ = "certificates"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    event_id = Column(
        Integer, ForeignKey("events.id", ondelete="SET NULL"), nullable=True
    )
    event_name = Column(String)
    volunteer_name = Column(String, nullable=True)
    organizer_name = Column(String, nullable=True)
    hours = Column(Integer, default=0)
    issue_date = Column(DateTime, default=datetime.utcnow)
    certificate_url = Column(String)

    user = relationship("User", back_populates="certificates")
    event = relationship("Event", backref="certificates")


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(
        Integer, ForeignKey("events.id", ondelete="CASCADE"), nullable=False
    )
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    rating = Column(Integer, nullable=False)
    text = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    event = relationship("Event", backref="reviews")
    user = relationship("User", backref="reviews")
