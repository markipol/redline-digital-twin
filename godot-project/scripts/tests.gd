extends Node

@export var player: Node
@export var infobox: Node
@export var customchart: Node
@export var env_loader: Node
@export var error_dialog: AcceptDialog
@export var popup_dialog: bool = true # Whether to show errors in popup or just print to console
@onready var http_request: HTTPRequest = HTTPRequest.new()
var errors = []
func _ready():
	await get_tree().process_frame 
	print("Running startup tests...")
	add_child(http_request) 
	player.exists()
	test_result("Player node exists", true)
	infobox.exists()
	test_result("Infobox node exists", true)
	customchart.exists()
	test_result("CustomChart node exists", true)
	env_loader.exists()
	test_result("EnvLoader node exists", true)
	if env_loader.get_var("READ_KEY") != "":
		test_result("Loaded READ_KEY", true)
	else:
		test_result("READ_KEY load failed! '.env' file missing or does not have 'READ_KEY = <key>'. Requests to server will fail", false)
	check_server()
func finish_tests():
	if errors.size() > 0:
		print("Some tests failed, program may be unstable or not work.")
		if popup_dialog:
			error_dialog.dialog_text = "Startup Test Errors:\n" + String("\n").join(errors)
			error_dialog.popup_centered()
	else:
		print("All startup tests passed!")
func check_server() -> void:
	print("Checking server health...")
	
	# First attempt: check Globals.SERVER/api/whoami
	var server_url = "%s/api/whoami" % Globals.SERVER
	http_request.request_completed.connect(_on_server_request_completed)
	var err = http_request.request(server_url)
	if err != OK:
		print("Failed to send server request, error code:", err)
		# fallback directly
		fallback_check_google()
	else:
		await http_request.request_completed # wait for signal
	
func _on_server_request_completed(_result, response_code, _headers, body):
	http_request.request_completed.disconnect(_on_server_request_completed)
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if typeof(json) == TYPE_DICTIONARY and json.has("ip"):
			print("Server reachable, now checking read access...")
			# Go check read access next
			check_read_access()
			return
		else:
			print("Server returned invalid response")
			test_result("Server is reachable but unexpected response format. Client may be outdated. Requests may not work", false)
			finish_tests()
	else:
		print("Server unreachable, error code:", response_code)
		fallback_check_google()

func check_read_access() -> void:
	var url = "https://findio.me/api/check_read"
	var read_key = env_loader.get_var("READ_KEY")
	var headers = [
		"X-API-KEY: %s" % read_key,
		"Content-Type: application/json"
	]
	http_request.request_completed.connect(_on_check_read_completed)
	var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("Failed to send check_read request, error code:", err)
		test_result("Check read request failed", false)
		finish_tests()
	else:
		await http_request.request_completed

func _on_check_read_completed(_result, response_code, _headers, body):
	http_request.request_completed.disconnect(_on_check_read_completed)
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if typeof(json) == TYPE_DICTIONARY and json.has("read_access") and json["read_access"] == true:
			test_result("Server reachable and read access OK! Data will show", true)
			finish_tests()
		else:
			test_result("Server is reachable and read key check returned 200 OK, but unexpected response format. Client may be outdated. Requests may not work", false)
			finish_tests()
	elif response_code == 401:
		test_result("Server reachable, but read key is incorrect/missing. Data will not show", false)
		finish_tests()
# Fallback: check google.com HEAD
func fallback_check_google() -> void:
	print("Trying fallback Google HEAD check...")
	
	http_request.request_completed.connect(_on_google_request_completed)
	var err = http_request.request("https://www.google.com", [], HTTPClient.METHOD_HEAD)
	if err != OK:
		print("Failed to send Google HEAD request, error code:", err)
		test_result("Can't ping google.com. Data will not show", false)
		finish_tests()
	else:
		await http_request.request_completed

func _on_google_request_completed(_result, response_code, _headers, _body):
	http_request.request_completed.disconnect(_on_google_request_completed)
	
	if response_code == 200:
		test_result("Can't reach server, it is offline or the connection is blocked. Connected to internet, can ping google.com. Data will not show.", false)
		finish_tests()
	else:
		test_result("No internet connection, can't ping google.com. Data will not show", false)
		finish_tests()

func test_result(message: String, result: bool):
	if result:
		print("PASS - %s" % message)
	else:
		print("FAIL - %s" % message)
		errors.append(message)
	# If any errors, popup
