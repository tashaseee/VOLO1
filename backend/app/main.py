from fastapi import FastAPI
from .database import engine
from .models import user as user_models
from .models import event as event_models
from .models import notification as notification_models
from .api import auth, users, events, admin, notifications
from sqlalchemy import text

user_models.Base.metadata.create_all(bind=engine)
event_models.Base.metadata.create_all(bind=engine)
notification_models.Base.metadata.create_all(bind=engine)

# Migration for new columns
with engine.connect() as conn:
    try:
        # Add user approval and role columns if they don't exist
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR DEFAULT 'volunteer'"))
        # Add profile stats columns
        conn.execute(text("ALTER TABLE profiles ADD COLUMN IF NOT EXISTS events_done INTEGER DEFAULT 0"))
        conn.execute(text("ALTER TABLE profiles ADD COLUMN IF NOT EXISTS eco_score INTEGER DEFAULT 0"))
        conn.execute(text("ALTER TABLE profiles ADD COLUMN IF NOT EXISTS social_score INTEGER DEFAULT 0"))
        conn.execute(text("ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sport_score INTEGER DEFAULT 0"))
        conn.execute(text("ALTER TABLE profiles ADD COLUMN IF NOT EXISTS cultural_score INTEGER DEFAULT 0"))
        # Add event category
        conn.execute(text("ALTER TABLE events ADD COLUMN IF NOT EXISTS category VARCHAR DEFAULT NULL"))
        conn.commit()
    except Exception as e:
        print(f"Migration error: {e}")

app = FastAPI(title="VOLO Backend")

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(events.router)
app.include_router(admin.router)
app.include_router(notifications.router)

from fastapi.staticfiles import StaticFiles
import os

# Create static directory if it doesn't exist
static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if not os.path.exists(static_dir):
    os.makedirs(static_dir)

# Create uploads directory if it doesn't exist
uploads_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
if not os.path.exists(uploads_dir):
    os.makedirs(uploads_dir)

app.mount("/static", StaticFiles(directory=static_dir), name="static")
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

@app.get("/")
def read_root():
    print("📢 Root / accessed")
    return {"message": "Welcome to VOLO API"}
