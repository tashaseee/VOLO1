"""
Script to add placeholder images to existing events
"""
from app.database import SessionLocal
from app.models.event import Event
from sqlalchemy import text
import os
import shutil
import requests

def download_placeholder_images():
    """Download placeholder images for events"""
    uploads_dir = "uploads/events"
    os.makedirs(uploads_dir, exist_ok=True)
    
    # List of free placeholder image URLs (from picsum.photos - free placeholder service)
    placeholder_urls = [
        "https://picsum.photos/400/300?random=1",
        "https://picsum.photos/400/300?random=2",
        "https://picsum.photos/400/300?random=3",
        "https://picsum.photos/400/300?random=4",
        "https://picsum.photos/400/300?random=5",
        "https://picsum.photos/400/300?random=6",
        "https://picsum.photos/400/300?random=7",
        "https://picsum.photos/400/300?random=8",
    ]
    
    downloaded_files = []
    
    for i, url in enumerate(placeholder_urls):
        try:
            print(f"Downloading image {i+1}...")
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                filename = f"placeholder_{i+1}.jpg"
                filepath = os.path.join(uploads_dir, filename)
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                downloaded_files.append(f"/uploads/events/{filename}")
                print(f"✓ Downloaded: {filename}")
        except Exception as e:
            print(f"✗ Failed to download image {i+1}: {e}")
    
    return downloaded_files

def update_events_with_images():
    """Update existing events with placeholder images"""
    db = SessionLocal()
    
    try:
        # Get all events without images
        events = db.query(Event).filter(
            (Event.image_url == None) | (Event.image_url == '')
        ).all()
        
        print(f"\nFound {len(events)} events without images")
        
        if not events:
            print("No events need updating!")
            return
        
        # Download placeholder images
        print("\nDownloading placeholder images...")
        image_urls = download_placeholder_images()
        
        if not image_urls:
            print("Failed to download images!")
            return
        
        # Update events
        print(f"\nUpdating events with images...")
        for i, event in enumerate(events):
            # Cycle through available images
            image_url = image_urls[i % len(image_urls)]
            event.image_url = image_url
            print(f"✓ Event '{event.title}' -> {image_url}")
        
        db.commit()
        print(f"\n✅ Successfully updated {len(events)} events with images!")
        
        # Verify
        events_with_images = db.query(Event).filter(Event.image_url != None).count()
        print(f"Total events with images: {events_with_images}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("=" * 60)
    print("Adding images to existing events")
    print("=" * 60)
    update_events_with_images()
    print("\n" + "=" * 60)
    print("Done!")
    print("=" * 60)
