import sqlite3
import os


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(BASE_DIR, "data.db")
SCHEMA_FILE = os.path.join(BASE_DIR, "schema.sql")
CREATE_ROOMS_FILE = os.path.join(BASE_DIR, "create_rooms.sql")

with open(SCHEMA_FILE, "r") as f:
    schema = f.read()
with open(CREATE_ROOMS_FILE, "r") as f:
    create_rooms = f.read()

conn = sqlite3.connect(DB_FILE)
conn.executescript(schema)
conn.executescript(create_rooms)
conn.commit()
conn.close()

print(f"✅ Database created at {DB_FILE}")
