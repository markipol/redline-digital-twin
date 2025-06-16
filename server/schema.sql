CREATE TABLE buildings (
    name TEXT NOT NULL PRIMARY KEY,
    display_name TEXT
);

CREATE TABLE floors (
    id INTEGER PRIMARY KEY,
    building_name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    FOREIGN KEY (building_name) REFERENCES buildings(name)
);

CREATE TABLE rooms (
    id TEXT PRIMARY KEY,
    floor_id INTEGER NOT NULL,
    display_name TEXT NOT NULL,
    FOREIGN KEY (floor_id) REFERENCES floors(id)
);

CREATE TABLE temperature_readings (
    room_id TEXT NOT NULL,
    timestamp REAL NOT NULL,
    temperature REAL NOT NULL,
    PRIMARY KEY (room_id, timestamp),
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);
