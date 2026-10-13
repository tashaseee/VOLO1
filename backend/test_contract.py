import os
import sys

# Ensure backend root is in python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.contract_generator import generate_organization_contract

if __name__ == "__main__":
    print("Testing contract generation...")
    try:
        pdf_path = generate_organization_contract(
            org_name="ТОО Волонтерский Альянс",
            org_bin="987654321012",
            org_email="alliance@test.org",
            output_dir=os.path.join(os.path.dirname(__file__), "uploads", "contracts")
        )
        print(f"✅ Success! Contract generated at: {pdf_path}")
        print(f"File size: {os.path.getsize(pdf_path)} bytes")
    except Exception as e:
        print(f"❌ Error during contract generation: {e}")
        import traceback
        traceback.print_exc()
