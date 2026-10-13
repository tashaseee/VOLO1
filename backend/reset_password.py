
from app.database import SessionLocal
from app.models.user import User, Profile, OrganizationProfile, Interest, Skill
from app.models.event import Event, Application, Certificate
from app.models.chat import Chat, ChatMessage
from app.models.notification import Notification
from app.auth_utils import get_password_hash

def reset_password(email, new_password):
    db = SessionLocal()
    user = db.query(User).filter(User.email == email.lower()).first()
    if user:
        user.hashed_password = get_password_hash(new_password)
        db.commit()
        print(f"Password reset successfully for {email}")
    else:
        print(f"User {email} not found")
    db.close()

if __name__ == "__main__":
    reset_password("amina@icloud.com", "password123")
