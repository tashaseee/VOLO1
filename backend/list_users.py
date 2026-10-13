from app.database import SessionLocal
from app.models.user import User, Profile, OrganizationProfile, Interest, Skill
from app.models.event import Event, Application, Certificate
from app.models.chat import Chat, ChatMessage
from app.models.notification import Notification

db = SessionLocal()
users = db.query(User).all()

print(f"{'ID':<5} {'Email':<30} {'Role':<15} {'Approved':<10}")
print("-" * 60)
for user in users:
    print(f"{user.id:<5} {user.email:<30} {user.role:<15} {user.is_approved:<10}")

db.close()
