import os
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, RedirectResponse
from .database import engine
from .models import user as user_models
from .models import event as event_models
from .models import notification as notification_models
from .models import chat as chat_models
from .models import support as support_models
from .api import auth, users, events, admin, notifications, ai_chat, chats, support
from sqlalchemy import text

user_models.Base.metadata.create_all(bind=engine)
event_models.Base.metadata.create_all(bind=engine)
notification_models.Base.metadata.create_all(bind=engine)
chat_models.Base.metadata.create_all(bind=engine)
support_models.Base.metadata.create_all(bind=engine)

# Migration for new columns
with engine.connect() as conn:
    try:
        # Add user approval and role columns if they don't exist
        conn.execute(
            text(
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR DEFAULT 'volunteer'"
            )
        )
        # Add profile stats columns
        conn.execute(
            text(
                "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS events_done INTEGER DEFAULT 0"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS eco_score INTEGER DEFAULT 0"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS social_score INTEGER DEFAULT 0"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sport_score INTEGER DEFAULT 0"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS cultural_score INTEGER DEFAULT 0"
            )
        )
        # Add event category
        conn.execute(
            text(
                "ALTER TABLE events ADD COLUMN IF NOT EXISTS category VARCHAR DEFAULT NULL"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE events ADD COLUMN IF NOT EXISTS certificate_title VARCHAR DEFAULT NULL"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE organization_profiles ADD COLUMN IF NOT EXISTS certificate_template_url VARCHAR DEFAULT NULL"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE certificates ADD COLUMN IF NOT EXISTS event_id INTEGER DEFAULT NULL"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE certificates ADD COLUMN IF NOT EXISTS volunteer_name VARCHAR DEFAULT NULL"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE certificates ADD COLUMN IF NOT EXISTS organizer_name VARCHAR DEFAULT NULL"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE certificates ADD COLUMN IF NOT EXISTS hours INTEGER DEFAULT 0"
            )
        )
        conn.commit()
    except Exception as e:
        print(f"Migration error: {e}")

app = FastAPI(title="VOLO Backend")


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
app.include_router(ai_chat.router)
app.include_router(chats.router)
app.include_router(support.router)


# Create static directory if it doesn't exist
static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if not os.path.exists(static_dir):
    os.makedirs(static_dir)

# Create uploads directory if it doesn't exist
uploads_dir = os.path.join(
    os.path.dirname(
        os.path.dirname(__file__)),
    "uploads")
if not os.path.exists(uploads_dir):
    os.makedirs(uploads_dir)

certificates_dir = os.path.join(uploads_dir, "certificates")
os.makedirs(certificates_dir, exist_ok=True)

templates_dir = os.path.join(static_dir, "certificate_templates")
os.makedirs(templates_dir, exist_ok=True)

app.mount("/static", StaticFiles(directory=static_dir), name="static")
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

# ─── Веб-админка UI на /panel/ (API остаётся на /admin/...) ─────────────
panel_dir = os.path.join(static_dir, "admin")
os.makedirs(panel_dir, exist_ok=True)


def _panel_index():
    index_path = os.path.join(panel_dir, "index.html")
    if not os.path.isfile(index_path):
        raise HTTPException(
            status_code=503,
            detail="Админ-панель не собрана. Выполните: cd admin_web && npm install && npm run build",
        )
    return FileResponse(index_path)


@app.get("/panel")
@app.get("/panel/")
def panel_root():
    return _panel_index()


@app.get("/panel/{full_path:path}")
def serve_panel_spa(full_path: str):
    safe = os.path.normpath(full_path)
    if safe.startswith(".."):
        raise HTTPException(status_code=404, detail="Not Found")
    asset_path = os.path.join(panel_dir, safe)
    if os.path.isfile(asset_path):
        return FileResponse(asset_path)
    return _panel_index()


@app.get("/admin")
def admin_api_hint():
    return RedirectResponse(url="/panel/")


@app.get("/")
def read_root():
    return RedirectResponse(url="/panel/")
