import sys
from app.database import SessionLocal
from app.models.user import User, Profile, OrganizationProfile, Interest, Skill
from app.models.event import Event, Application, Certificate
from app.models.chat import Chat, ChatMessage
from app.models.notification import Notification

def approve_organizer(email):
    db = SessionLocal()
    user = db.query(User).filter(User.email == email.lower()).first()
    if not user:
        print(f"User with email {email} not found")
        return
    
    if user.role != 'organizer':
        print(f"User {email} is not an organizer (role: {user.role})")
        return
    
    user.is_approved = True
    db.commit()
    print(f"Organizer {email} has been approved successfully!")
    db.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python approve_org.py <email>")
    else:
        approve_organizer(sys.argv[1])
