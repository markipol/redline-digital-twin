extends Control

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var left_button: TextureButton = $left_arrow
@onready var right_button: TextureButton = $right_arrow
@export var label: Label
@export var env_loader: Node3D
@export var error_dialog: AcceptDialog

var data_points: Array[Dictionary] = []  # { "dt": Dictionary, "temperature": float }
var screen_points: PackedVector2Array = []
var start_time_dict: Dictionary  # start of chart (local time)
var current_date: Dictionary
var room_id: String = ""
var epoch = Time.get_datetime_dict_from_unix_time(0)

const TEMP_MIN := 10.0
const TEMP_MAX := 35.0
const SPAN_SECONDS := 86400.0  # 24 hours

var line_color: Color = Color.RED
var dot_color: Color = Color.BLACK
var bg_color: Color = Color.hex(0xFF2a2a66)

# ========= INIT =========

func _ready():
	visible = false

func exists() -> bool:
	return true

# ========= SHOW ROOM =========

func show_chart_for_room(new_room_id: String) -> void:
	
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		print("Request already in progress, ignoring...")
		return
	set_arrow_buttons_enabled(false)
	room_id = new_room_id
	
	var tz_str = Globals.TIMEZONE
	var url = Globals.SERVER + "/api/room/%s/latest_day/%s" % [room_id, tz_str]
	
	var read_key = env_loader.get_var("READ_KEY")
	if not read_key:
		print("READ_KEY missing or empty in EnvLoader")
		return
	
	var headers = [
		"X-API-KEY: %s" % read_key,
		"Content-Type: application/json"
	]
	
	var error = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_GET
	)
	
	if error != OK:
		print("Failed to send request:", error)
	else:
		visible = true

func show_chart_for_day() -> void:
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		print("Request already in progress, ignoring...")
		return
	set_arrow_buttons_enabled(false)
	var tz_str = Globals.TIMEZONE
	var iso_date = "%04d-%02d-%02d" % [current_date.year, current_date.month, current_date.day]
	var url = Globals.SERVER + "/api/room/%s/day/%s/%s" % [room_id, iso_date, tz_str]
	
	var read_key = env_loader.get_var("READ_KEY")
	if not read_key:
		print("READ_KEY missing or empty in EnvLoader")
		return
	
	var headers = [
		"X-API-KEY: %s" % read_key,
		"Content-Type: application/json"
	]
	
	var error = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_GET
	)
	
	if error != OK:
		print("Failed to send request:", error)
	else:
		visible = true

# ========= HTTP COMPLETE =========

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json_result
	if body:
		json_result = JSON.parse_string(body.get_string_from_utf8())

	if response_code != 200:
		print("Error: status ", response_code)
		var error_str = (", " + json_result["error"]) if json_result.has("error") else ""
		$Error.text = "HTTP Error " + str(response_code) + error_str
		$Error.show()
		current_date = epoch # Set date as unix epoch, universal "something is wrong" error
		update_room_date()
		set_arrow_buttons_enabled(true)
		return

	if typeof(json_result) != TYPE_DICTIONARY:
		print("Invalid JSON format, expected dictionary")
		$Error.text = "Invalid JSON format, expected dictionary"
		$Error.show()
		update_room_date()
		set_arrow_buttons_enabled(true)
		return

	# Handle latest_day_iso + readings API
	if json_result.has("latest_day_iso") and json_result.has("readings"):
		var latest_day_iso = json_result["latest_day_iso"]
		var readings = json_result["readings"]
		current_date = parse_iso_date(latest_day_iso)
		
			

		update_start_time_from_current_date()
		load_readings(readings)

	# Handle day API
	elif json_result.has("readings"):
		var readings = json_result["readings"]
		update_start_time_from_current_date()
		load_readings(readings)

	else:
		print("Invalid response format")
		$Error.text = "Invalid response format"
		$Error.show()
		set_arrow_buttons_enabled(true)
		update_room_date()
		return
	set_arrow_buttons_enabled(true)
# ========= LOAD READINGS =========

func load_readings(readings: Array):
	data_points.clear()
	for entry in readings:
		if typeof(entry) == TYPE_DICTIONARY:
			var ts = float(entry.get("timestamp", 0))
			var temp = float(entry.get("temperature", 0))
			var local_dt = utc_unix_to_local_dict(ts)
			data_points.append({ "dt": local_dt, "temperature": temp })
	
	data_points.sort_custom(func(a, b): return seconds_since_start(a["dt"], start_time_dict) < seconds_since_start(b["dt"], start_time_dict))
	update_room_date()
	# update UI
	if data_points.size() > 0:
		$Error.hide()
		var last = data_points.back()
		var time_string = Time.get_datetime_string_from_datetime_dict(last["dt"], true)
		var temp = last["temperature"]
		label.text = "Room %s\nLast update: %s\nTemperature: %.1f°C" % [room_id, time_string, temp]
	elif is_same_day(current_date, epoch):
		label.text = room_id
		$Error.text = "No data for ANY date for room " + room_id + " recorded in database"
		$Error.show()
		
	else:
		label.text = room_id
		$Error.text = "No data on " + $Date.text + " found for room " + room_id
		$Error.show()
	
	
	
	await get_tree().process_frame
	map_data_to_screen()
	queue_redraw()
func update_room_date():
	$Room.text = room_id
	$Date.text = "%02d/%02d/%04d" % [current_date.day, current_date.month, current_date.year]
# ========= MAP TO SCREEN =========

func map_data_to_screen() -> void:
	screen_points.clear()

	var width = size.x
	var height = size.y

	for dp in data_points:
		var local_dt = dp["dt"]
		var temp = dp["temperature"]
		var sec = seconds_since_start(local_dt, start_time_dict)
		var x = x_position(sec, width)
		var y = lerp(height, 0.0, (temp - TEMP_MIN) / (TEMP_MAX - TEMP_MIN))
		screen_points.append(Vector2(x, y))

# ========= DRAW =========

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)

	if screen_points.size() < 2:
		return
	draw_vertical_time_grid_lines()
	draw_horizontal_temp_grid_lines() 
	for i in range(screen_points.size() - 1):
		draw_line(screen_points[i] + Vector2(1, 1), screen_points[i + 1] + Vector2(1, 1), Color(0, 0, 0, 0.3), 3, true)
		draw_line(screen_points[i], screen_points[i + 1], line_color, 2, true)

	for pt in screen_points:
		draw_circle(pt, 5, dot_color)


@export var time_label_y_offset: int = 25
func draw_vertical_time_grid_lines():
	var font = get_theme_default_font()
	var width = size.x
	var height = size.y

	var label_dt = first_full_hour_after(start_time_dict)

	while true:
		var sec = seconds_since_start(label_dt, start_time_dict)
		if sec > SPAN_SECONDS:
			break
		var x = x_position(sec, width)
		draw_line(Vector2(x, 0), Vector2(x, height), Color.LIGHT_GRAY, 1)

		var label_text = "%02d:00" % label_dt.hour
		var label_y = height + time_label_y_offset
		var label_size = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

		var bg_color = Color.hex(0x000000dd)
		var bg_pos = Vector2(x + 2, label_y - label_size.y)
		var bg_size = label_size + Vector2(8, 4)
		draw_rect(Rect2(bg_pos, bg_size), bg_color, true)

		draw_string(font, bg_pos + Vector2(4, label_size.y), label_text, 0, -1, 16, Color(0.9, 0.9, 0.9))

		label_dt = add_hours_to_dict(label_dt, 3)

@export var data_label_x_offset: int = -50
@export var data_label_y_offset: int = -5

func draw_horizontal_temp_grid_lines(step: float = 5.0):
	var font = get_theme_default_font()
	var width = size.x
	var height = size.y

	var value: float = ceil(TEMP_MIN / step) * step
	while value <= TEMP_MAX:
		var y = lerp(height, 0.0, (value - TEMP_MIN) / (TEMP_MAX - TEMP_MIN))
		draw_line(Vector2(0, y), Vector2(width, y), Color.LIGHT_GRAY, 1)

		var label = "%2.0f°C" % value
		var label_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

		# Use offset for consistent left margin
		var label_x = data_label_x_offset
		var label_y = y + data_label_y_offset  # baseline correction (optional tweak)

		var bg_color = Color.hex(0x000000dd)
		var bg_pos = Vector2(label_x, label_y - label_size.y)
		var bg_size = label_size + Vector2(8, 4)

		draw_rect(Rect2(bg_pos, bg_size), bg_color, true)
		draw_string(font, bg_pos + Vector2(4, label_size.y), label, 0, -1, 16, Color(0.9, 0.9, 0.9))

		value += step
# ========= HELPERS =========

func set_arrow_buttons_enabled(enabled: bool) -> void:
	left_button.disabled = not enabled
	right_button.disabled = not enabled
func is_same_day(a: Dictionary, b: Dictionary) -> bool:
	return (
		a.get("year", null) == b.get("year", null) and
		a.get("month", null) == b.get("month", null) and
		a.get("day", null) == b.get("day", null)
	)
func update_start_time_from_current_date():
	start_time_dict = current_date.duplicate()
	start_time_dict.hour = 0
	start_time_dict.minute = 0
	start_time_dict.second = 0

func utc_unix_to_local_dict(utc_ts: float) -> Dictionary:
	var offset = Time.get_time_zone_from_system().bias * 60
	return Time.get_datetime_dict_from_unix_time(utc_ts + offset)

func seconds_since_start(local: Dictionary, zero: Dictionary) -> float:
	var ts_local = Time.get_unix_time_from_datetime_dict(local)
	var ts_zero = Time.get_unix_time_from_datetime_dict(zero)
	return float(ts_local - ts_zero)

func x_position(sec: float, width: float) -> float:
	return (sec / SPAN_SECONDS) * width

func first_full_hour_after(dt: Dictionary) -> Dictionary:
	var unix = Time.get_unix_time_from_datetime_dict(dt)
	if dt.minute > 0 or dt.second > 0:
		unix = (floor(unix / 3600) + 1) * 3600  # Round up to next hour
	return Time.get_datetime_dict_from_unix_time(unix)

func add_hours_to_dict(dt: Dictionary, hours: int) -> Dictionary:
	var unix = Time.get_unix_time_from_datetime_dict(dt)
	unix += hours * 3600 # 3600 seconds in 1 hour
	return Time.get_datetime_dict_from_unix_time(unix)

func parse_iso_date(iso_str: String) -> Dictionary:
	var parts = iso_str.split("-")
	return {
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2]),
		"hour": 0,
		"minute": 0,
		"second": 0
	}

func shift_current_date_by_days(delta: int):
	if current_date.is_empty():
		print("current_date empty, ignoring shift")
		return
	
	var unix_time = Time.get_unix_time_from_datetime_dict(current_date)
	unix_time += delta * 86400
	if unix_time > Time.get_unix_time_from_system():
		error_dialog.dialog_text = "Error: Date can not be in the future"
		error_dialog.popup_centered()
		return
	current_date = Time.get_datetime_dict_from_unix_time(unix_time)
	update_start_time_from_current_date()
	show_chart_for_day()

# ========= BUTTONS =========

func _on_close_button_pressed() -> void:
	visible = false

func _on_left_arrow_pressed():
	shift_current_date_by_days(-1)

func _on_right_arrow_pressed():
	shift_current_date_by_days(1)
