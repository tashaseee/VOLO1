from sqlalchemy import Column, Integer, String, Boolean, Date, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime

class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    organizer = Column(String, nullable=True) # Display name of organization (optional if we use relation)
    organizer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE")) # Link to the user who created it
    description = Column(Text)
    date_text = Column(String) # For display like "25 Oct"
    full_date = Column(DateTime)
    location = Column(String)
    hours = Column(Integer, default=0)
    category = Column(String) # e.g., 'Eco', 'Sport', 'Social', 'Cultural'
    image_url = Column(String)
    chat_link = Column(String)
    volunteer_count = Column(Integer, default=0)
    responsibilities = Column(Text)
    benefits = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    organizer_user = relationship("User", backref="organized_events")
    applications = relationship("Application", back_populates="event")

class Application(Base):
    __tablename__ = "applications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    event_id = Column(Integer, ForeignKey("events.id", ondelete="CASCADE"))
    status = Column(String, default="pending") # pending, approved, rejected, completed
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="applications")
    event = relationship("Event", back_populates="applications")

class Certificate(Base):
    __tablename__ = "certificates"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    event_name = Column(String)
    issue_date = Column(DateTime, default=datetime.utcnow)
    certificate_url = Column(String) # Link to PDF or just a record

    user = relationship("User", back_populates="certificates")
