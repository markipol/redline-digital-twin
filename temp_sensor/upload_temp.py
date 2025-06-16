import os
import requests
from datetime import datetime
from zoneinfo import ZoneInfo
from read_temp import read_temperature
from dotenv import load_dotenv

load_dotenv()

WRITE_KEY = os.getenv("WRITE_KEY")
ROOM_ID = "101A"  # ← Change to your actual room ID
API_URL = "https://findio.me/api/report"  # ← Use your real domain (with HTTPS)
HEADERS = {
    "Content-Type": "application/json",
    "X-API-Key": WRITE_KEY
}
MELB_TZ = ZoneInfo("Australia/Melbourne")

def post_real_temperature():
    temp = read_temperature()
    if temp is None:
        print("Failed to read temperature")
        return

    timestamp = datetime.now(MELB_TZ).timestamp()
    payload = {
        "room_id": ROOM_ID,
        "temperature": temp,
        "timestamp": timestamp
    }

    try:
        res = requests.post(API_URL, json=payload, headers=HEADERS, timeout=5)
        dt_str = datetime.fromtimestamp(timestamp, MELB_TZ).strftime("%Y-%m-%d %H:%M:%S %Z")
        print(f"[{ROOM_ID}] {temp:.2f}°C @ {dt_str} → {res.status_code}")
        print("Response:", res.text)
    except Exception as e:
        print("Error sending temperature:", e)

# Run when called directly
if __name__ == "__main__":
    post_real_temperature()
