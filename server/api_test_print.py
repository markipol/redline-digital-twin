import os
import requests
import json
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv

load_dotenv()

WRITE_KEY = os.getenv('WRITE_KEY')

# Correct endpoint for local testing
URL = "http://localhost/api/report"
HEADERS = {
    "Content-Type": "application/json",
    "X-Dry-Run": "true",
    "X-API-Key": WRITE_KEY
}

def post(payload, label):
    print(f"\n== {label} ==")
    response = requests.post(URL, headers=HEADERS, data=json.dumps(payload))
    print(f"Status: {response.status_code}")
    print("Response:", response.json())

# 1. Missing fields
post({}, "1. Missing all fields")

# 2. Invalid Unix timestamp (too short)
post({
    "room_id": "101A",
    "timestamp": "12345",
    "temperature": 22.0
}, "2. Invalid Unix timestamp (too short)")

# 3. Bad ISO format
post({
    "room_id": "101A",
    "timestamp": "28-05-2025 17:00",
    "temperature": 22.0
}, "3. Bad ISO format")

# 4. ISO timestamp missing timezone
post({
    "room_id": "101A",
    "timestamp": "2025-05-28T17:00:00",
    "temperature": 22.0
}, "4. ISO timestamp missing timezone")

# 5. Timestamp too far in the future
future_ts = datetime.now(timezone.utc) + timedelta(days=1)
post({
    "room_id": "101A",
    "timestamp": future_ts.isoformat(),
    "temperature": 22.0
}, "5. Timestamp too far in the future")

# 6. Timestamp too far in the past (11 years ago)
past_ts = datetime.now(timezone.utc) - timedelta(days=365*11)
post({
    "room_id": "101A",
    "timestamp": past_ts.isoformat(),
    "temperature": 22.0
}, "6. Timestamp too far in the past")

# 7. Room does not exist
valid_ts = datetime.now(timezone.utc).timestamp()
post({
    "room_id": "Z999",
    "timestamp": valid_ts,
    "temperature": 22.0
}, "7. Room ID does not exist")
print(valid_ts)
# 8. All good (control case)
post({
    "room_id": "101A",
    "timestamp": valid_ts,
    "temperature": 22.0
}, "9. Valid input")