import pytest
import requests
from read_temp import read_temperature
import os
from dotenv import load_dotenv

load_dotenv()

API_URL = "https://findio.me/api/report"
WRITE_KEY = os.getenv("WRITE_KEY")
ROOM_ID = "201B"
HEADERS = {
    "Content-Type": "application/json",
    "X-API-Key": WRITE_KEY,
    "X-Dry-Run": "true"  # TEST HEADER
}

# --- Test 1: read_temperature() works or fails gracefully ---

def test_read_temperature_runs():
    temp = read_temperature()
    assert  isinstance(temp, float), "Temperature should be float"

# --- Test 2: upload_temp.py behavior with X-Dry-Run ---




def test_upload_temperature_dry_run():
    temp = read_temperature()
    if temp is None:
        pytest.skip("Skipping upload test - could not read temperature")

    from datetime import datetime
    from zoneinfo import ZoneInfo
    MELB_TZ = ZoneInfo("Australia/Melbourne")
    timestamp = datetime.now(MELB_TZ).timestamp()

    payload = {
        "room_id": ROOM_ID,
        "temperature": temp,
        "timestamp": timestamp
    }

    response = requests.post(API_URL, json=payload, headers=HEADERS, timeout=5)

    # Check status code
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"

    # Check response is valid JSON
    response_json = response.json()

    # Check status validated
    assert "status" in response_json, "Response missing 'status' field"
    assert response_json["status"] == "validated", f"Expected 'validated' status, got {response_json['status']}"