from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
import os
import uuid
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import user as models
from ..schemas import user as schemas
from .auth import SECRET_KEY, ALGORITHM
from jose import jwt, JWTError
from fastapi.security import OAuth2PasswordBearer

router = APIRouter(prefix="/users", tags=["users"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    return user


@router.get("/me", response_model=schemas.UserOut)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user


@router.put("/profile")
def update_profile(
    profile_data: schemas.ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    profile = (
        db.query(models.Profile)
        .filter(models.Profile.user_id == current_user.id)
        .first()
    )

    if not profile:
        profile = models.Profile(user_id=current_user.id)
        db.add(profile)

    # Update profile fields
    update_data = profile_data.dict(exclude_unset=True)

    # Handle interests and skills separately
    interests_names = update_data.pop("interests", None)
    skills_names = update_data.pop("skills", None)

    for key, value in update_data.items():
        setattr(profile, key, value)

    if interests_names is not None:
        interests = []
        for name in interests_names:
            interest = (
                db.query(
                    models.Interest).filter(
                    models.Interest.name == name).first())
            if not interest:
                interest = models.Interest(name=name)
                db.add(interest)
                db.flush()
            interests.append(interest)
        current_user.interests = interests

    if skills_names is not None:
        skills = []
        for name in skills_names:
            skill = db.query(
                models.Skill).filter(
                models.Skill.name == name).first()
            if not skill:
                skill = models.Skill(name=name)
                db.add(skill)
                db.flush()
            skills.append(skill)
        current_user.skills = skills

    db.commit()
    return {"message": "Profile updated successfully"}


@router.put("/org-profile")
def update_org_profile(
    profile_data: schemas.OrganizationProfileUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    profile = (
        db.query(models.OrganizationProfile)
        .filter(models.OrganizationProfile.user_id == current_user.id)
        .first()
    )

    if not profile:
        profile = models.OrganizationProfile(user_id=current_user.id)
        db.add(profile)

    update_data = profile_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(profile, key, value)

    db.commit()
    return {"message": "Organization profile updated successfully"}


@router.post("/upload-avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    # Debug info
    print("DEBUG: Попытка загрузки аватара")
    print(f"DEBUG: Filename: {file.filename}")
    print(f"DEBUG: Content-Type: {file.content_type}")
    print(f"DEBUG: User: {current_user.email}")

    # Create directory if not exists
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    static_dir = os.path.join(base_dir, "static", "avatars")

    try:
        if not os.path.exists(static_dir):
            os.makedirs(static_dir, exist_ok=True)
            print(f"DEBUG: Создана директория {static_dir}")
    except Exception as e:
        print(f"DEBUG: Ошибка создания директории: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка сервера: {
                str(e)}")

    # Generate unique filename
    try:
        file_extension = os.path.splitext(
            file.filename)[1] if file.filename else ".jpg"
        if not file_extension:
            file_extension = ".jpg"
        filename = f"{uuid.uuid4()}{file_extension}"
        file_path = os.path.join(static_dir, filename)
        print(f"DEBUG: Путь сохранения: {file_path}")
    except Exception as e:
        print(f"DEBUG: Ошибка генерации имени: {e}")
        raise HTTPException(status_code=400, detail="Неверное имя файла")

    # Save file
    try:
        content = await file.read()
        if not content:
            print("DEBUG: Файл пуст")
            raise HTTPException(status_code=400, detail="Файл пуст")

        with open(file_path, "wb") as buffer:
            buffer.write(content)
        print("DEBUG: Файл успешно сохранен")
    except Exception as e:
        print(f"DEBUG: Ошибка сохранения файла: {e}")
        raise HTTPException(
            status_code=500, detail=f"Не удалось сохранить файл: {str(e)}"
        )

    # Generate URL (relative path)
    avatar_url = f"/static/avatars/{filename}"

    # Update user profile based on role
    try:
        if current_user.role == "organizer":
            profile = (
                db.query(models.OrganizationProfile)
                .filter(models.OrganizationProfile.user_id == current_user.id)
                .first()
            )
            if not profile:
                profile = models.OrganizationProfile(user_id=current_user.id)
                db.add(profile)
            profile.avatar_url = avatar_url
        else:
            profile = (
                db.query(models.Profile)
                .filter(models.Profile.user_id == current_user.id)
                .first()
            )
            if not profile:
                profile = models.Profile(user_id=current_user.id)
                db.add(profile)
            profile.avatar_url = avatar_url

        db.commit()
        print(f"DEBUG: Профиль обновлен: {avatar_url}")
    except Exception as e:
        print(f"DEBUG: Ошибка БД: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка базы данных: {
                str(e)}")

    return {"avatar_url": avatar_url}
