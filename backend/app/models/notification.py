from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    type = Column(String, default="info")  # info, success, warning, error, application
    is_read = Column(Boolean, default=False)
    related_id = Column(Integer, nullable=True)  # ID связанной сущности (application, event)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", backref="notifications")
