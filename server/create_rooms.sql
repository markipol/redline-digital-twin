-- Add building
INSERT OR IGNORE INTO buildings (name, display_name) VALUES ('jg', 'Jenny Graves Building');

-- Add floor
INSERT OR IGNORE INTO floors (id, building_name, display_name) VALUES (1, 'jg', 'Level 1');

-- All Level 1 rooms in Jenny Graves
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('101', 1, '101 - Central Space');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('101A', 1, '101A - HOC Cafe');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('101B', 1, '101B - Male Toilets');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('101C', 1, '101C - Female Toilets');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('101D', 1, '101D - Unisex Toilet');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('101F', 1, '101F - Meeting');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('102', 1, '102 - Student Services Staff');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('103', 1, '103 - Mentoring Hub');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('103A', 1, '103A - Mentoring Hub');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('104', 1, '104 - Waiting');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('104A', 1, '104A - Meeting');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('104B', 1, '104B - Meeting');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('105', 1, '105 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('106', 1, '106 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('107', 1, '107 - Staff');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('108', 1, '108 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('109', 1, '109 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('110', 1, '110 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('111', 1, '111 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('112', 1, '112 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('113', 1, '113 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('114', 1, '114 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('115', 1, '115 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('116', 1, '116 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('117', 1, '117 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('118', 1, '118 - Interview');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('119', 1, '119 - Comms');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('120', 1, '120 - Storage');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('150A', 1, '150A - Tea Point');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('152', 1, '152 - Inside Lift');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('162A', 1, '162A - Exterior Lift');
INSERT OR REPLACE INTO rooms (id, floor_id, display_name) VALUES ('165', 1, '165 - Plenum');

