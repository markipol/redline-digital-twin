from datetime import datetime, timedelta, timezone
import re, time
from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import sqlite3
import os
from dotenv import load_dotenv
from zoneinfo import ZoneInfo

load_dotenv()

WRITE_KEY = os.getenv('WRITE_KEY')
READ_KEY = os.getenv('READ_KEY')
server = Flask(__name__)
CORS(server)
DB_FILE = os.path.join(os.path.dirname(__file__), "data.db")

UNIX_TIME_REGEX = r'^\d{10}(?:\.\d+)?$'
ISO_TIME_REGEX = r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?([+-]\d{2}:\d{2}|Z)$'

class HTTPError(Exception):
    def __init__(self, message, status_code):
        super().__init__(message)
        self.message = message
        self.status_code = status_code

def wrap_http_errors(fn):
    try:
        return fn()
    except HTTPError as e:
        return jsonify({"error": e.message}), e.status_code
    except Exception as e:
        print(f"Unhandled exception: {e}")
        return jsonify({"error": "Internal server error"}), 500

def check_write_key(request):
    request_api_key = request.headers.get("X-API-Key")
    if request_api_key != WRITE_KEY:
        raise HTTPError("API write key incorrect or missing", 401)

def check_read_key(request):
    request_api_key = request.headers.get("X-API-Key")
    if request_api_key != READ_KEY:
        raise HTTPError("API read key incorrect or missing", 401)

def to_local_time_info(unix_timestamp, tz_str):
    try:
        tz = ZoneInfo(tz_str)
    except Exception:
        raise HTTPError(f"Invalid timezone: '{tz_str}'", 400)
    dt = datetime.fromtimestamp(unix_timestamp, tz)
    offset = dt.utcoffset().total_seconds() / 3600
    return {
        "local_time": dt.isoformat(),
        "utc_offset_hours": offset,
    }, tz_str, offset
# Human readable helper function for console output
def decorate_with_local_time(data, tz_str):
    try:
        tz = ZoneInfo(tz_str)
    except Exception:
        raise HTTPError(f"Invalid timezone: '{tz_str}'", 400)

    result = []
    offset = None  # Default fallback
    tz_str_fixed = tz_str

    for row in data:
        time_info, tz_str_fixed, offset = to_local_time_info(row["timestamp"], tz_str)
        row.update(time_info)
        result.append(row)

    return {
        "timezone": tz_str_fixed,
        "utc_offset_hours": offset if offset is not None else tz.utcoffset(datetime.now()).total_seconds() / 3600,
        "readings": result
    }
def fetch_latest_all_rooms_of_floor(floor_id):
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute("SELECT EXISTS(SELECT 1 FROM floors WHERE id = ?)", (floor_id,))
    if not cur.fetchone()[0]:
        conn.close()
        raise HTTPError(f"Floor {floor_id} does not exist", 404)
    cur.execute('''
        SELECT r.id AS room_id, r.display_name, tr.timestamp, tr.temperature
        FROM rooms r
        JOIN (
            SELECT room_id, MAX(timestamp) AS latest_timestamp
            FROM temperature_readings
            GROUP BY room_id
        ) latest ON r.id = latest.room_id
        JOIN temperature_readings tr
            ON tr.room_id = latest.room_id AND tr.timestamp = latest.latest_timestamp
        WHERE r.floor_id = ?;
    ''', (floor_id,))
    rows = cur.fetchall()
    conn.close()
    return [dict(row) for row in rows]

def fetch_last24h_for_room(room_id):
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute("SELECT EXISTS(SELECT 1 FROM rooms WHERE id = ?)", (room_id,))
    if not cur.fetchone()[0]:
        conn.close()
        raise HTTPError(f"Room ID '{room_id}' does not exist", 404)
    now = time.time()
    twenty_four_hours_ago = now - 86400
    cur.execute('''
        SELECT timestamp, temperature
        FROM temperature_readings
        WHERE room_id = ?
        AND timestamp >= ?
        ORDER BY timestamp DESC;
    ''', (room_id, twenty_four_hours_ago))
    rows = cur.fetchall()
    conn.close()
    return [dict(row) for row in rows]
def fetch_day_for_room(room_id: str, date_str: str, tz_str: str):
    if not re.match(r"^\d{4}-\d{2}-\d{2}$", date_str):
        raise HTTPError("Date must be in ISO format YYYY-MM-DD with a 4-digit year", 400)

    try:
        day_dt = datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        raise HTTPError("Invalid date format or impossible date", 400)

    try:
        tz = ZoneInfo(tz_str)
    except Exception:
        raise HTTPError(f"Invalid timezone: '{tz_str}'", 400)

    start_dt = day_dt.replace(tzinfo=tz)
    now_dt = datetime.now(tz)

    if start_dt > now_dt:
        raise HTTPError("Date cannot be in the future", 400)
    end_dt = (day_dt + timedelta(days=1)).replace(tzinfo=tz)
    start_ts = start_dt.timestamp()
    end_ts = end_dt.timestamp()

    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    cur.execute("SELECT EXISTS(SELECT 1 FROM rooms WHERE id = ?)", (room_id,))
    if not cur.fetchone()[0]:
        conn.close()
        raise HTTPError(f"Room ID '{room_id}' does not exist", 404)

    cur.execute('''
        SELECT timestamp, temperature
        FROM temperature_readings
        WHERE room_id = ?
        AND timestamp >= ?
        AND timestamp < ?
        ORDER BY timestamp ASC;
    ''', (room_id, start_ts, end_ts))

    rows = cur.fetchall()
    conn.close()
    return [dict(row) for row in rows]
def fetch_latest_day_wrapped_for_room(room_id: str, tz_str: str):
    try:
        tz = ZoneInfo(tz_str)
    except Exception:
        raise HTTPError(f"Invalid timezone: '{tz_str}'", 400)

    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    cur.execute("SELECT EXISTS(SELECT 1 FROM rooms WHERE id = ?)", (room_id,))
    if not cur.fetchone()[0]:
        conn.close()
        raise HTTPError(f"Room ID '{room_id}' does not exist", 404)

    # Fetch latest reading timestamp
    cur.execute('''
        SELECT timestamp
        FROM temperature_readings
        WHERE room_id = ?
        ORDER BY timestamp DESC
        LIMIT 1;
    ''', (room_id,))
    row = cur.fetchone()

    if not row:
        conn.close()
        return {
            "latest_day_iso": "1970-01-01", # Fallback date, unix epoch, date still there which makes output consistent
            "readings": [] # Empty array, program should be if this is empty display no data
        }

    latest_unix = row["timestamp"]
    latest_dt_local = datetime.fromtimestamp(latest_unix, tz)
    latest_day_iso = latest_dt_local.date().isoformat()

    conn.close()

    # Re use existing function
    readings = fetch_day_for_room(room_id, latest_day_iso, tz_str)

    return {
        "latest_day_iso": latest_day_iso,
        "readings": readings
    }

def handle_report_payload(data, dry_run):
    print("Received data:", data)
    required = ["room_id", "timestamp", "temperature"]
    if not all(k in data for k in required):
        raise HTTPError("Missing required fields", 400)

    room_id = data["room_id"]
    raw_timestamp = data["timestamp"]
    temperature = data["temperature"]

    if re.match(UNIX_TIME_REGEX, str(raw_timestamp)):
        parsed_time = datetime.fromtimestamp(float(raw_timestamp), tz=timezone.utc)
        unix_time = float(raw_timestamp)
    elif re.match(ISO_TIME_REGEX, str(raw_timestamp)):
        parsed_time = datetime.fromisoformat(raw_timestamp)
        if parsed_time.tzinfo is None:
            raise HTTPError("ISO timestamp missing timezone", 400)
        unix_time = parsed_time.timestamp()
    else:
        raise HTTPError("Timestamp format not recognized (must be Unix or ISO 8601 with timezone)", 400)

    now = datetime.now(timezone.utc)
    if parsed_time > now + timedelta(seconds=10):
        raise HTTPError("Timestamp is in the future", 400)
    if parsed_time < now - timedelta(days=365 * 10):
        raise HTTPError("Timestamp is more than 10 years in the past", 400)

    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()
    cur.execute("SELECT EXISTS(SELECT 1 FROM rooms WHERE id = ?)", (room_id,))
    if not cur.fetchone()[0]:
        conn.close()
        raise HTTPError(f"Room ID '{room_id}' does not exist", 404)

    if dry_run:
        conn.close()
        return jsonify({
            "status": "validated",
            "dry_run_result": "Dry run enabled via X-Dry-Run header. No data stored. Request is validly formatted"
        })

    cur.execute('''
        INSERT OR REPLACE INTO temperature_readings
        (room_id, timestamp, temperature)
        VALUES (?, ?, ?)
    ''', (room_id, unix_time, temperature))
    conn.commit()
    conn.close()

    return jsonify({"status": "ok"})

# Incoming data report, put data in database
@server.route("/api/report", methods=["POST"])
def report_route():
    def inner():
        check_write_key(request)
        dry_run = request.headers.get("X-Dry-Run", "").lower() == "true"
        data = request.get_json(force=True)
        return handle_report_payload(data, dry_run)
    return wrap_http_errors(inner)

# Debug function to return IP of client
@server.route("/api/whoami", methods=["GET"])
def whoami_route():
    def inner():
        return jsonify({"ip": request.headers.get("CF-Connecting-IP")})
    return wrap_http_errors(inner)
# Empty read route but authenticated, test API read key correct
@server.route("/api/check_read", methods=["GET"])
def check_read_route():
    def inner():
        check_read_key(request)
        return jsonify({
            "read_access": True
        })
    return wrap_http_errors(inner)
# Empty write route but authenticated, test API write key correct
@server.route("/api/check_write", methods=["GET"])
def check_write_route():
    def inner():
        check_write_key(request)
        return jsonify({
            "write_access": True
        })
    return wrap_http_errors(inner)


# Get latest data from all rooms of a floor
@server.route("/api/floor/<int:floor_id>/latest", methods=["GET"])
def latest_per_room_route(floor_id):
    def inner():
        check_read_key(request)
        return jsonify(fetch_latest_all_rooms_of_floor(floor_id))
    return wrap_http_errors(inner)

# Get data from the last 24 hours from a specfiic room
@server.route("/api/room/<room_id>/last24h", methods=["GET"])
def last24h_room_route(room_id):
    def inner():
        check_read_key(request)
        return jsonify(fetch_last24h_for_room(room_id))
    return wrap_http_errors(inner)
# Get data 12am-12am for a specific day
@server.route("/api/room/<room_id>/day/<date_str>/<path:tz_str>", methods=["GET"])
def day_room_route_(room_id, date_str, tz_str):
    def inner():
        check_read_key(request)
        return jsonify({"readings": fetch_day_for_room(room_id, date_str, tz_str)})
    return wrap_http_errors(inner)
# Get the latest day for a room, then get that day 12am-12am, also returns latest_day_iso
@server.route("/api/room/<room_id>/latest_day/<path:tz_str>", methods=["GET"])
def latest_day_room_route(room_id, tz_str):
    def inner():
        check_read_key(request)
        return jsonify(fetch_latest_day_wrapped_for_room(room_id, tz_str))
    return wrap_http_errors(inner)
# Human readable helper routes for console output
@server.route("/api/floor/<int:floor_id>/latest/human_readable/<path:tz_str>", methods=["GET"])
def latest_per_room_human_route(floor_id, tz_str):
    def inner():
        check_read_key(request)
        return jsonify(decorate_with_local_time(fetch_latest_all_rooms_of_floor(floor_id), tz_str))
    return wrap_http_errors(inner)

@server.route("/api/room/<room_id>/last24h/human_readable/<path:tz_str>", methods=["GET"])
def last24h_room_human_route(room_id, tz_str):
    def inner():
        check_read_key(request)
        return jsonify(decorate_with_local_time(fetch_last24h_for_room(room_id), tz_str))
    return wrap_http_errors(inner)
@server.route("/api/room/<room_id>/day/<date_str>/human_readable/<path:tz_str>", methods=["GET"])
def day_room_human_route(room_id, date_str, tz_str):
    def inner():
        check_read_key(request)
        return jsonify(decorate_with_local_time(fetch_day_for_room(room_id, date_str, tz_str), tz_str))
    return wrap_http_errors(inner)

if __name__ == "__main__":
    server.run(host="0.0.0.0", port=80)
