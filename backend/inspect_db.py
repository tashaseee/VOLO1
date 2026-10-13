
from app.database import SessionLocal
from app.models.user import User, Profile, OrganizationProfile, Interest, Skill
from app.models.event import Event, Application, Certificate
from app.models.chat import Chat, ChatMessage
from app.models.notification import Notification

db = SessionLocal()
users = db.query(User).all()

print(f"Total users: {len(users)}")
for user in users:
    print(f"ID: {user.id}, Email: '{user.email}', Role: {user.role}")

db.close()
