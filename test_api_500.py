
import requests

BASE_URL = "http://10.202.7.234:8080" # OR http://127.0.0.1:8080

def test_api():
    # Attempt to login as admin to get a token
    # Or just use the known admin credentials
    login_data = {"email": "admin@volo.kz", "password": "admin"}
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    if response.status_code != 200:
        print(f"Login failed: {response.status_code} {response.text}")
        return
    
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test /users/me
    resp = requests.get(f"{BASE_URL}/users/me", headers=headers)
    print(f"/users/me: {resp.status_code}")
    if resp.status_code == 500:
        print(resp.text)

    # Test /events/my-events
    resp = requests.get(f"{BASE_URL}/events/my-events", headers=headers)
    print(f"/events/my-events: {resp.status_code}")
    if resp.status_code == 500:
        print(resp.text)
        return

    events = resp.json()
    for event in events:
        eid = event["id"]
        resp = requests.get(f"{BASE_URL}/events/{eid}/applications", headers=headers)
        print(f"/events/{eid}/applications: {resp.status_code}")
        if resp.status_code == 500:
            print(resp.text)

if __name__ == "__main__":
    test_api()
