from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List
from datetime import date, datetime


class UserBase(BaseModel):
    email: EmailStr


class UserCreate(UserBase):
    password: str

    @field_validator("password")
    @classmethod
    def password_complexity(cls, v):
        if len(v) < 8:
            raise ValueError("Пароль должен быть не менее 8 символов")
        if not any(char.isdigit() for char in v):
            raise ValueError("Пароль должен содержать хотя бы одну цифру")
        if not any(char.isupper() for char in v):
            raise ValueError(
                "Пароль должен содержать хотя бы одну заглавную букву")
        return v

    role: str = "volunteer"  # volunteer or organizer
    org_name: Optional[str] = None
    bin: Optional[str] = None

    @field_validator("bin")
    @classmethod
    def validate_bin(cls, v, values):
        if v and len(v) != 12:
            raise ValueError("БИН должен состоять из 12 цифр")
        if v and not v.isdigit():
            raise ValueError("БИН должен состоять только из цифр")
        return v


class UserVerify(BaseModel):
    email: EmailStr
    code: str


class UserLogin(UserBase):
    password: str


class UserForgot(BaseModel):
    email: EmailStr


class UserReset(BaseModel):
    email: EmailStr
    code: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_complexity(cls, v):
        if len(v) < 8:
            raise ValueError("Пароль должен быть не менее 8 символов")
        if not any(char.isdigit() for char in v):
            raise ValueError("Пароль должен содержать хотя бы одну цифру")
        if not any(char.isupper() for char in v):
            raise ValueError(
                "Пароль должен содержать хотя бы одну заглавную букву")
        return v


class ProfileBase(BaseModel):
    full_name: Optional[str] = None
    birth_date: Optional[date] = None
    gender: Optional[str] = None
    city: Optional[str] = None
    phone: Optional[str] = None
    experience: Optional[str] = None
    motivation: Optional[str] = None


class ProfileUpdate(ProfileBase):
    interests: Optional[List[str]] = None
    skills: Optional[List[str]] = None


class InterestOut(BaseModel):
    name: str

    class Config:
        from_attributes = True


class SkillOut(BaseModel):
    name: str

    class Config:
        from_attributes = True


class ProfileOut(ProfileBase):
    id: int
    avatar_url: Optional[str] = None
    volo_hours: int = 0
    events_done: int = 0
    eco_score: int = 0
    social_score: int = 0
    sport_score: int = 0
    cultural_score: int = 0
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class OrganizationProfileBase(BaseModel):
    full_name: Optional[str] = None
    bin: Optional[str] = None
    description: Optional[str] = None
    website: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None


class OrganizationProfileUpdate(OrganizationProfileBase):
    certificate_template_url: Optional[str] = None


class OrganizationProfileOut(OrganizationProfileBase):
    id: int
    avatar_url: Optional[str] = None
    certificate_template_url: Optional[str] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class UserOut(UserBase):
    id: int
    created_at: datetime
    role: str
    is_verified: bool
    is_approved: bool
    profile: Optional[ProfileOut] = None
    org_profile: Optional[OrganizationProfileOut] = None
    interests: List[InterestOut] = []
    skills: List[SkillOut] = []

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    is_approved: bool
    is_verified: bool


class TokenData(BaseModel):
    email: Optional[str] = None
