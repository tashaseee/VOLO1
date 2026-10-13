#!/usr/bin/env python3
import requests
import json
import sys
import os
from datetime import datetime, timedelta

# Add parent path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal
from app.models.user import User, Profile, OrganizationProfile
from app.models.event import Event, Application, Certificate
from app.models.chat import Chat, ChatMessage
from app.models.notification import Notification

BASE_URL = "http://127.0.0.1:8080"

def get_db_user_code(email: str) -> str:
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email.lower()).first()
        if user:
            return user.verification_code
        return None
    finally:
        db.close()

def approve_user_in_db(email: str):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email.lower()).first()
        if user:
            user.is_approved = True
            db.commit()
            print(f"✅ User {email} approved directly in DB")
    finally:
        db.close()

def delete_test_users():
    db = SessionLocal()
    try:
        emails = ["test_org_e2e@test.com", "test_vol_e2e@test.com"]
        for email in emails:
            user = db.query(User).filter(User.email == email).first()
            if user:
                print(f"🧹 Cleaning up existing test user: {email}")
                db.delete(user)
        db.commit()
    finally:
        db.close()

def print_banner(text):
    print(f"\n============================================================")
    print(f" 🚀 {text}")
    print(f"============================================================\n")

def run_tests():
    print_banner("STARTING VOLO E2E INTEGRATION TESTS")
    
    # 0. Clean up old test data
    delete_test_users()
    
    # 1. Register Organizer
    print_banner("1. Registering Organizer")
    org_email = "test_org_e2e@test.com"
    org_register_data = {
        "email": org_email,
        "password": "Password123",
        "role": "organizer",
        "org_name": "E2E Test Org",
        "bin": "999999999999"
    }
    
    resp = requests.post(f"{BASE_URL}/auth/register", json=org_register_data)
    assert resp.status_code == 200, f"Register failed: {resp.text}"
    print("✅ Organizer registered successfully")
    
    # 2. Get verification code and verify email
    print_banner("2. Verifying Organizer Email")
    code = get_db_user_code(org_email)
    print(f"Retrieved verification code from DB: {code}")
    assert code is not None, "Verification code not found in DB!"
    
    verify_data = {
        "email": org_email,
        "code": code
    }
    resp = requests.post(f"{BASE_URL}/auth/verify", json=verify_data)
    assert resp.status_code == 200, f"Verify failed: {resp.text}"
    print("✅ Organizer email verified successfully")
    
    # 3. Approve Organizer via Admin panel/endpoint
    print_banner("3. Admin Approval of Organizer")
    # First, let's login as admin to get admin token
    admin_login = {
        "email": "admin@volo.kz",
        "password": "admin"
    }
    resp = requests.post(f"{BASE_URL}/auth/login", json=admin_login)
    assert resp.status_code == 200, f"Admin login failed: {resp.text}"
    admin_token = resp.json()["access_token"]
    print("✅ Admin logged in successfully")
    
    # Get organizer user ID
    db = SessionLocal()
    org_user = db.query(User).filter(User.email == org_email).first()
    org_id = org_user.id
    db.close()
    
    # Approve via admin endpoint
    headers = {"Authorization": f"Bearer {admin_token}"}
    resp = requests.post(f"{BASE_URL}/admin/approve-organization/{org_id}", headers=headers)
    assert resp.status_code == 200, f"Approval failed: {resp.text}"
    print("✅ Organizer approved by Admin via API successfully")
    
    # 4. Login as Organizer
    print_banner("4. Logging in as Organizer")
    org_login_data = {
        "email": org_email,
        "password": "Password123"
    }
    resp = requests.post(f"{BASE_URL}/auth/login", json=org_login_data)
    assert resp.status_code == 200, f"Organizer login failed: {resp.text}"
    org_token = resp.json()["access_token"]
    assert resp.json()["role"] == "organizer", "Role is incorrect"
    assert resp.json()["is_approved"] is True, "Approved flag is incorrect"
    print("✅ Organizer login successful, token retrieved")
    
    # 5. Create Event (Organization)
    print_banner("5. Creating Event as Organizer")
    event_data = {
        "title": "E2E Clean Air Volunteering",
        "description": "Planting trees and clean-up in Almaty hills.",
        "location": "Almaty Kok-Tobe",
        "date_text": "20.10.2026 | 10:00",
        "hours": 4,
        "category": "Экология",
        "chat_link": "https://t.me/e2e_volo_chat",
        "volunteer_count": 10,
        "responsibilities": "Plant trees, carry water",
        "benefits": "Snacks, fresh air, Volo hours"
    }
    org_headers = {"Authorization": f"Bearer {org_token}"}
    # Create event using multipart/form-data
    resp = requests.post(f"{BASE_URL}/events/", data=event_data, headers=org_headers)
    assert resp.status_code == 200, f"Event creation failed: {resp.text}"
    event_id = resp.json()["id"]
    print(f"✅ Event created successfully with ID: {event_id}")
    
    # 6. Register Volunteer
    print_banner("6. Registering Volunteer")
    vol_email = "test_vol_e2e@test.com"
    vol_register_data = {
        "email": vol_email,
        "password": "Password123",
        "role": "volunteer"
    }
    resp = requests.post(f"{BASE_URL}/auth/register", json=vol_register_data)
    assert resp.status_code == 200, f"Volunteer register failed: {resp.text}"
    
    vol_code = get_db_user_code(vol_email)
    print(f"Retrieved volunteer verification code: {vol_code}")
    resp = requests.post(f"{BASE_URL}/auth/verify", json={"email": vol_email, "code": vol_code})
    assert resp.status_code == 200, f"Volunteer verification failed: {resp.text}"
    print("✅ Volunteer registered and verified successfully")
    
    # 7. Login as Volunteer
    print_banner("7. Logging in as Volunteer")
    vol_login_data = {
        "email": vol_email,
        "password": "Password123"
    }
    resp = requests.post(f"{BASE_URL}/auth/login", json=vol_login_data)
    assert resp.status_code == 200, f"Volunteer login failed: {resp.text}"
    vol_token = resp.json()["access_token"]
    print("✅ Volunteer login successful, token retrieved")
    
    # 8. Volunteer applies to the Event
    print_banner("8. Volunteer applying to Event")
    vol_headers = {"Authorization": f"Bearer {vol_token}"}
    resp = requests.post(f"{BASE_URL}/events/{event_id}/apply", headers=vol_headers)
    assert resp.status_code == 200, f"Application failed: {resp.text}"
    application_id = resp.json()["id"]
    print(f"✅ Application submitted successfully with ID: {application_id}")
    
    # 9. Organizer views applications and approves it
    print_banner("9. Organizer approving volunteer application")
    resp = requests.get(f"{BASE_URL}/events/{event_id}/applications", headers=org_headers)
    assert resp.status_code == 200, f"Get applications failed: {resp.text}"
    apps = resp.json()
    assert len(apps) > 0, "No applications found"
    print(f"Found {len(apps)} applications. Approving the application...")
    
    resp = requests.put(
        f"{BASE_URL}/events/applications/{application_id}/status",
        json={"status": "approved"},
        headers=org_headers
    )
    assert resp.status_code == 200, f"Application approval failed: {resp.text}"
    print("✅ Application approved successfully by Organizer")
    
    # 10. Forgot Password Flow
    print_banner("10. Testing Forgot Password Flow")
    # Request reset code
    forgot_data = {"email": vol_email}
    resp = requests.post(f"{BASE_URL}/auth/forgot-password", json=forgot_data)
    assert resp.status_code == 200, f"Forgot password failed: {resp.text}"
    print("✅ Forgot password code requested successfully")
    
    # Retrieve reset code from DB
    reset_code = get_db_user_code(vol_email)
    print(f"Retrieved reset code from DB: {reset_code}")
    assert reset_code is not None, "Reset code not found in DB!"
    
    # Reset password
    reset_data = {
        "email": vol_email,
        "code": reset_code,
        "new_password": "NewPassword123"
    }
    resp = requests.post(f"{BASE_URL}/auth/reset-password", json=reset_data)
    assert resp.status_code == 200, f"Reset password failed: {resp.text}"
    print("✅ Password reset successfully")
    
    # Try logging in with old password (should fail)
    print_banner("11. Verifying old password no longer works")
    resp = requests.post(f"{BASE_URL}/auth/login", json={"email": vol_email, "password": "Password123"})
    assert resp.status_code == 403, f"Old password login should have failed but returned: {resp.status_code}"
    print("✅ Login with old password rejected successfully")
    
    # Try logging in with new password (should succeed)
    print_banner("12. Logging in with new password")
    resp = requests.post(f"{BASE_URL}/auth/login", json={"email": vol_email, "password": "NewPassword123"})
    assert resp.status_code == 200, f"Login with new password failed: {resp.text}"
    print("✅ Login with new password succeeded!")
    
    # 11. Cleanup test users
    print_banner("13. Cleaning up test data")
    delete_test_users()
    
    print("\n🎉 ALL E2E TESTS PASSED SUCCESSFULLY! EVERYTHING WORKS GREAT! 🎉\n")

if __name__ == "__main__":
    try:
        run_tests()
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ UNEXPECTED ERROR: {e}")
        sys.exit(1)
