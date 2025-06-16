import sys
import requests
import random, pytz, os
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo 
from dotenv import load_dotenv

load_dotenv()

WRITE_KEY = os.getenv('WRITE_KEY')

HEADERS = {
    "Content-Type": "application/json",
    "X-API-Key": WRITE_KEY
}

API_URL = "http://127.0.0.1/api/report"  # Change to Azure IP if testing live
MELB_TZ = pytz.timezone("Australia/Melbourne")
# DO NOT INCLUDE 101A, THATS THE REAL DATA BRO!!!!
ROOM_IDS = [
    "101", "101B", "101C", "101D", "101F",
    "102", "103", "103A", "104", "104A", "104B",
    "105", "106", "107", "108", "109", "110",
    "111", "112", "113", "114", "115", "116",
    "117", "118", "119", "120", "150A", "152",
    "162A", "165"
]

def generate_temperature():
    return round(random.uniform(18.0, 25.0), 1)

def post_reading(room_id, temperature, timestamp):
    payload = {
        "room_id": room_id,
        "temperature": temperature,
        "timestamp": timestamp
    }
    try:
        res = requests.post(API_URL, json=payload, timeout=2, headers=HEADERS)
        dt = datetime.fromtimestamp(timestamp, ZoneInfo("Australia/Melbourne"))
        dtstr = dt.strftime("%Y-%m-%d %H:%M:%S %Z")
        print(f"[{room_id}] {temperature}°C @ {dtstr} → {res.status_code}")
    except Exception as e:
        print(f"[{room_id}] Failed: {e}")


def post_one_random_reading():
    room_id = random.choice(ROOM_IDS)
    temp = generate_temperature()
    ts = datetime.now(MELB_TZ).timestamp()
    post_reading(room_id, temp, ts)

def backfill_24h_for_rooms(room_list):
    base_time = datetime.now(MELB_TZ) - timedelta(hours=24)
    for room_id in room_list:
        print(f"\nBackfilling 24h for room {room_id}...")
        for hour in range(24):
            report_time = base_time + timedelta(hours=hour)
            temp = generate_temperature()
            post_reading(room_id, temp, report_time.timestamp())


if __name__ == "__main__":
    if "--one" in sys.argv:
        post_one_random_reading()
    elif "--all" in sys.argv:
        backfill_24h_for_rooms(ROOM_IDS)
    else:
        sample_rooms = random.sample(ROOM_IDS, 3)
        backfill_24h_for_rooms(sample_rooms)