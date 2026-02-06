from app.database import engine
from sqlalchemy import text

def reset_database():
    with engine.connect() as conn:
        print("Dropping all tables with CASCADE...")
        # Get all table names
        result = conn.execute(text("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public'"))
        tables = [row[0] for row in result]
        for table in tables:
            conn.execute(text(f'DROP TABLE IF EXISTS "{table}" CASCADE'))
        conn.commit()
    
    # Re-import models to ensure they are registered with Base
    from app.models.user import Base as UserBase
    from app.models.event import Base as EventBase
    
    print("Creating all tables...")
    UserBase.metadata.create_all(bind=engine)
    EventBase.metadata.create_all(bind=engine)
    print("Database reset complete.")

if __name__ == "__main__":
    reset_database()
