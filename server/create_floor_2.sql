-- Add floor
INSERT OR IGNORE INTO floors (id, building_name, display_name) VALUES (2, 'jg', 'Level 2 - Digital Innovation Hub');

-- All Level 1 rooms in Jenny Graves
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('201', 2, '201 - Presentation Space');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('201B', 2, '201B - Co Work Lounge');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('202', 2, '202 - 5G Ideation/Boardroom');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('216', 2, '216 - Co Work Space');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('201C', 2, '201C - Collaboration Hub');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('203', 2, '203 - Open Desk Space');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('204', 2, '204 - Makers Workshop');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('214', 2, '214 - Incubator / Design Studio');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES  ('215', 2, '215 - Incubator / Design Studio');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('213', 2, '213 - Meeting / Pitch Space');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('210', 2, '210 - Male Toilets');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('209', 2, '209 - Female Toilets');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('211', 2, '211 - Unisex Toilet');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('204A', 2, '204A - Compactus / Store');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('205', 2, '205 - Makers Lab');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('206', 2, '206 - Makers Lab');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('207', 2, '207 - Makers Lab');