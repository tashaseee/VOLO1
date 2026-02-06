import requests
import os

# Get token (you'll need to login first or use an existing token)
# For testing, let's first try to create a test event

base_url = "http://127.0.0.1:8000"

# You need to login first to get a token
# Replace with actual credentials
login_data = {
    "username": "test@example.com",  # Replace with actual organizer email
    "password": "password123"  # Replace with actual password
}

# Try to login
try:
    response = requests.post(f"{base_url}/auth/login", data=login_data)
    print(f"Login response: {response.status_code}")
    if response.status_code == 200:
        token = response.json().get("access_token")
        print(f"Token received: {token[:20]}...")
        
        # Try to create an event with image
        headers = {"Authorization": f"Bearer {token}"}
        
        event_data = {
            "title": "Test Event with Image",
            "description": "This is a test event",
            "location": "Almaty, Test Location",
            "date_text": "15.02.2026",
            "hours": "4",
            "category": "Экология",
            "chat_link": "https://t.me/test",
            "volunteer_count": "10",
            "responsibilities": "Test responsibility",
            "benefits": "Test benefit"
        }
        
        # Create a simple test image if it doesn't exist
        test_image_path = "/tmp/test_event_image.jpg"
        if not os.path.exists(test_image_path):
            # Create a minimal valid JPEG
            with open(test_image_path, "wb") as f:
                # Minimal JPEG header (won't display properly but valid for upload test)
                f.write(b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xd9')
        
        files = {"image": open(test_image_path, "rb")}
        
        response = requests.post(
            f"{base_url}/events/",
            headers=headers,
            data=event_data,
            files=files
        )
        
        print(f"\nEvent creation response: {response.status_code}")
        print(f"Response body: {response.json()}")
        
    else:
        print(f"Login failed: {response.text}")
        
except Exception as e:
    print(f"Error: {e}")
