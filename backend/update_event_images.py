import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from app.database import SessionLocal
from app.models.event import Event

def update_images():
    db = SessionLocal()
    try:
        urls = {
            "Помощь в приюте для животных 'Верный Друг'": "https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=600&q=80",
            "Озеленение парка Первого Президента": "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=600&q=80",
            "Almaty Marathon 2026: Координация на трассе": "https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=600&q=80",
            "Форум IT-технологий 'Digital Kazakhstan'": "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&q=80",
            "Обучение пенсионеров цифровой грамотности": "https://images.unsplash.com/photo-1516302752625-fcc3c50ae61f?w=600&q=80",
            "Фестиваль современной музыки 'Voice of Asia'": "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600&q=80",
        }
        
        updated = 0
        events = db.query(Event).all()
        for e in events:
            if e.title in urls:
                e.image_url = urls[e.title]
                updated += 1
            elif e.image_url and e.image_url.startswith('/static/images'):
                # Reset missing local paths to empty so it falls back to default photo
                e.image_url = ""
                updated += 1
                
        db.commit()
        print(f"Обновлено ссылок на картинки: {updated}")
    except Exception as e:
        print(f"Ошибка: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    update_images()
