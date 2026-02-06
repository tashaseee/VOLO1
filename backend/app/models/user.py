from sqlalchemy import Column, Integer, String, Boolean, Date, Text, ForeignKey, Table, DateTime
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime

# Many-to-many associations
user_interests = Table(
    "user_interests",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("interest_id", Integer, ForeignKey("interests.id", ondelete="CASCADE"), primary_key=True),
)

user_skills = Table(
    "user_skills",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("skill_id", Integer, ForeignKey("skills.id", ondelete="CASCADE"), primary_key=True),
)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    is_approved = Column(Boolean, default=False) # For organizers
    verification_code = Column(String, nullable=True)
    role = Column(String, default="volunteer")

    profile = relationship("Profile", back_populates="user", uselist=False)
    interests = relationship("Interest", secondary=user_interests, back_populates="users")
    skills = relationship("Skill", secondary=user_skills, back_populates="users")
    applications = relationship("Application", back_populates="user")
    certificates = relationship("Certificate", back_populates="user")
    org_profile = relationship("OrganizationProfile", back_populates="user", uselist=False)

class Profile(Base):
    __tablename__ = "profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    full_name = Column(String)
    birth_date = Column(Date)
    gender = Column(String)
    city = Column(String)
    phone = Column(String)
    experience = Column(Text)
    motivation = Column(Text)
    avatar_url = Column(String)
    volo_hours = Column(Integer, default=0)
    events_done = Column(Integer, default=0)
    eco_score = Column(Integer, default=0)
    social_score = Column(Integer, default=0)
    sport_score = Column(Integer, default=0)
    cultural_score = Column(Integer, default=0)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="profile")

class OrganizationProfile(Base):
    __tablename__ = "organization_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    full_name = Column(String) # Legal Name
    bin = Column(String) # Business ID Number
    description = Column(Text)
    website = Column(String)
    address = Column(String)
    phone = Column(String)
    avatar_url = Column(String)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="org_profile")

class Interest(Base):
    __tablename__ = "interests"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    
    users = relationship("User", secondary=user_interests, back_populates="interests")

class Skill(Base):
    __tablename__ = "skills"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)

    users = relationship("User", secondary=user_skills, back_populates="skills")
