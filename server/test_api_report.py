import os
import pytest
import requests
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv

load_dotenv()


REPORT_URL = "http://localhost/api/report"
VALID_ROOM = "101A"
load_dotenv()
WRITE_KEY = os.getenv("WRITE_KEY")
READ_KEY = os.getenv("READ_KEY")
BASE = "http://localhost/"
VALID_ROOM = "101A"
VALID_FLOOR = 1
WRITE_HEADERS = {
    "Content-Type": "application/json",
    "X-Dry-Run": "true",
    "X-API-Key": WRITE_KEY

}
READ_HEADERS = {
    "Content-Type": "application/json",
    "X-Dry-Run": "true",
    "X-API-Key": READ_KEY

}
HEADERS_NO_AUTH = {
    "Content-Type": "application/json",
    "X-Dry-Run": "true"
}
def post(payload):
    return requests.post(REPORT_URL, json=payload, headers=WRITE_HEADERS)

def test_missing_fields():
    res = post({})
    assert res.status_code == 400
    assert "Missing required fields" in res.json()["error"]

def test_invalid_unix_too_short():
    res = post({
        "room_id": VALID_ROOM,
        "timestamp": "123456789",  # 9 digits
        "temperature": 22.0
    })
    assert res.status_code == 400
    assert "Timestamp format not recognized" in res.json()["error"]

def test_bad_iso_format():
    res = post({
        "room_id": VALID_ROOM,
        "timestamp": "2025/01/01 10:00",
        "temperature": 22.0
    })
    assert res.status_code == 400
    assert "Timestamp format not recognized" in res.json()["error"]

def test_missing_timezone():
    res = post({
        "room_id": VALID_ROOM,
        "timestamp": "2025-01-01T10:00:00",
        "temperature": 22.0
    })
    assert res.status_code == 400
    assert "Timestamp format not recognized" in res.json()["error"]

def test_future_timestamp():
    future = datetime.now(timezone.utc) + timedelta(days=2)
    res = post({
        "room_id": VALID_ROOM,
        "timestamp": future.isoformat(),
        "temperature": 22.0
    })
    assert res.status_code == 400
    assert "Timestamp is in the future" in res.json()["error"]

def test_past_too_far():
    past = datetime.now(timezone.utc) - timedelta(days=365 * 11)
    res = post({
        "room_id": VALID_ROOM,
        "timestamp": past.isoformat(),
        "temperature": 22.0
    })
    assert res.status_code == 400
    assert "more than 10 years in the past" in res.json()["error"]

def test_nonexistent_room():
    now = datetime.now(timezone.utc)
    res = post({
        "room_id": "Z999",
        "timestamp": now.isoformat(),
        "temperature": 22.0
    })
    assert res.status_code == 404
    assert "Room ID" in res.json()["error"]

def test_valid_input():
    now = datetime.now(timezone.utc)
    res = post({
        "room_id": VALID_ROOM,
        "timestamp": now.isoformat(),
        "temperature": 22.0
    })
    assert res.status_code == 200
    json = res.json()
    assert json["status"] == "validated"
    assert "validly formatted" in json["dry_run_result"].lower()




def test_whoami():
    res = requests.get(f"{BASE}/api/whoami")
    assert res.status_code == 200
    assert "ip" in res.json()
def test_check_read_success():
    res = requests.get(f"{BASE}/api/check_read", headers=READ_HEADERS)
    assert res.status_code == 200
    assert res.json()["read_access"] is True
def test_check_read_fail():
    res = requests.get(f"{BASE}/api/check_read", headers=HEADERS_NO_AUTH)
    assert res.status_code == 401
    assert "API read key incorrect or missing" in res.json()["error"]
def test_check_write_success():
    res = requests.get(f"{BASE}/api/check_write", headers=WRITE_HEADERS)
    assert res.status_code == 200
    assert res.json()["write_access"] is True
def test_check_write_fail():
    res = requests.get(f"{BASE}/api/check_write", headers=HEADERS_NO_AUTH)
    assert res.status_code == 401
    assert "API write key incorrect or missing" in res.json()["error"]
def test_no_write_auth():
    now = datetime.now(timezone.utc)
    payload = {
        "room_id": VALID_ROOM,
        "timestamp": now.isoformat(),
        "temperature": 22.0
    }
    res = requests.post(REPORT_URL, json=payload, headers=HEADERS_NO_AUTH)
    assert res.status_code == 401
    assert "API write key incorrect or missing" in res.json()["error"]
def test_latest_per_floor_success():
    res = requests.get(f"{BASE}/api/floor/{VALID_FLOOR}/latest", headers=READ_HEADERS)
    assert res.status_code == 200
    assert isinstance(res.json(), list)

def test_latest_per_floor_404():
    res = requests.get(f"{BASE}/api/floor/999/latest", headers=READ_HEADERS)
    assert res.status_code == 404
    assert "error" in res.json()

def test_last24h_for_room_success():
    res = requests.get(f"{BASE}/api/room/{VALID_ROOM}/last24h", headers=READ_HEADERS)
    assert res.status_code == 200
    assert isinstance(res.json(), list)

def test_last24h_for_room_404():
    res = requests.get(f"{BASE}/api/room/Z999/last24h", headers=READ_HEADERS)
    assert res.status_code == 404
    assert "error" in res.json()

def test_human_latest_success():
    res = requests.get(f"{BASE}/api/floor/{VALID_FLOOR}/latest/human_readable/Australia/Melbourne", headers=READ_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert "timezone" in data and "readings" in data

def test_human_latest_invalid_tz():
    res = requests.get(f"{BASE}/api/floor/{VALID_FLOOR}/latest/human_readable/NotAZone", headers=READ_HEADERS)
    assert res.status_code == 400
    assert "Invalid timezone" in res.json()["error"]

def test_human_last24h_success():
    res = requests.get(f"{BASE}/api/room/{VALID_ROOM}/last24h/human_readable/Australia/Melbourne", headers=READ_HEADERS)
    print(res.status_code)
    print(res.text)
    assert res.status_code == 200
    data = res.json()
    assert "timezone" in data and "readings" in data

def test_human_last24h_invalid_tz():
    res = requests.get(f"{BASE}/api/room/{VALID_ROOM}/last24h/human_readable/NotAZone", headers=READ_HEADERS)
    print(res.status_code)
    print(res.text)
    assert res.status_code == 400
    assert "Invalid timezone" in res.json()["error"]

def test_human_latest_404():
    res = requests.get(f"{BASE}/api/floor/999/latest/human_readable/Australia/Melbourne", headers=READ_HEADERS)
    assert res.status_code == 404

def test_human_last24h_404():
    res = requests.get(f"{BASE}/api/room/Z999/last24h/human_readable/Australia/Melbourne", headers=READ_HEADERS)
    assert res.status_code == 404   
