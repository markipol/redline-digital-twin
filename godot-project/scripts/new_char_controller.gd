extends CharacterBody3D

enum ControlMode {MOUSE_DRAG, WASD, VIRTUAL_JOYSTICKS}
@export var control_mode: ControlMode = ControlMode.MOUSE_DRAG
# Nodes
@export_subgroup("Nodes")
@export var CUSTOM_CHART: Control
@export var DATA_LABEL: Label
@export var HEIGHT_LOCK_BUTTON: CheckButton
@export var MOVE_MODE_SEL: OptionButton
@export var HELP_PANEL: Panel

@export var RED: Material
@export var BLUE: Material
@export var DEBUG_MENU: CanvasLayer

@export var ON_SCREEN_CONTROLS: Control
@export var CROSSHAIR: Sprite2D

# Movement Settings
@export_subgroup("Movement settings")
@export var movement_speed : float = 10.0 # Default movement speed
@export var sprint_multiplier: float = 2.0 # Sprint speed multiplier
@export var height_lock: bool = true
# Key Bindings
@export_subgroup("Movement keybinds")
@export var KEY_FORWARD: String = "move_forward"
@export var KEY_BACKWARD: String = "move_backward"
@export var KEY_LEFT: String = "move_left"
@export var KEY_RIGHT: String = "move_right"
@export var KEY_UP: String = "move_up"
@export var KEY_DOWN: String = "move_down"
@export var KEY_SPRINT: String = "sprint"
@export var KEY_ESCAPE: String = "quit" # Escape key for toggling mouse capture
@export var KEY_INV: String = "inventory"
@export var CLICK:String = "mouse"
@export var KEY_MODE_SWITCH:String = "mode_switch"
@export var KEY_HIDE_JOYSTICKS:String = "hide_joysticks_temp_swipe_down_placeholder"
@export var KEY_HEIGHT_LOCK: String = "toggle_height_lock"

# Mouse Settings
@export_subgroup("Mouse")
@export var MOUSE_ACCEL_STATE := false # Enable mouse acceleration
@export var MOUSE_SENS := 0.005 # Mouse sensitivity
@export var MOUSE_ACCEL := 50 # Mouse acceleration factor

# Head Rotation Clamping
@export_subgroup("Clamp Head Rotation")
@export var CLAMP_HEAD_ROTATION := true # Enable head rotation clamping
@export var CLAMP_HEAD_ROTATION_MIN := -90.0 # Min head rotation
@export var CLAMP_HEAD_ROTATION_MAX := 90.0 # Max head rotation

# Camera Node
@export_subgroup("Camera node")
@export var camera: Camera3D # Camera attached to the character

# Collision Settings (Optional)
@export_subgroup("Collision (Optional)")
@export var collision_state := true # Enable or disable collision
@export var collision: CollisionShape3D # Collision shape for the character


# Internal variables 
var rotation_target_player : float
var rotation_target_head : float
var mouse_captured: bool = true


var room_data = {}
# On screen controls (assigned in _ready)
var LEFT_VJ: VirtualJoystick
var RIGHT_VJ: VirtualJoystick
var UP_BUTTON: TextureButton
var DOWN_BUTTON: TextureButton

var dragging := false
var last_mouse_position := Vector2.ZERO
@export var drag_sensitivity := 0.05
@export var zoom_sensitivity := 1
@export var zoom_min: float = 2.0
@export var zoom_max: float = 100.0

# Called when the node enters the scene tree for the first time
func _ready():
	set_control_mode(control_mode)
	await MOVE_MODE_SEL.ready
	
	HEIGHT_LOCK_BUTTON.button_pressed = height_lock
	$purple_arrow.visible = false
	RIGHT_VJ = ON_SCREEN_CONTROLS.get_node("right_vj")
	LEFT_VJ = ON_SCREEN_CONTROLS.get_node("left_vj")
	UP_BUTTON = ON_SCREEN_CONTROLS.get_node("up_button")
	DOWN_BUTTON = ON_SCREEN_CONTROLS.get_node("down_button")
	# Uncomment if you want FPS counter by default otherwise press f3
	# DEBUG_MENU.style = DEBUG_MENU.Style.VISIBLE_COMPACT
	# Toggle collision state if set
	if collision != null:
		collision.disabled = !collision_state

	# If no camera is assigned, create a new one and add it to the node
	if camera == null:
		camera = Camera3D.new()
		add_child(camera)
		
	# Capture the mouse at the start
	
	rotation_target_player = global_transform.basis.get_euler().y
	rotation_target_head = camera.global_transform.basis.get_euler().x

# Process input and rotation on physics ticks
func _physics_process(delta: float) -> void:	
	input_polling()
	rotate_player(delta)
	
func exists() -> bool:
	return true
# Input events where its not already been consumed by something else
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("show_help"):
		if wasd() and mouse_captured:
			mouse_captured = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			CROSSHAIR.hide()
		
		HELP_PANEL.visible = true
	# If OSC is visibile, its VJ mode, and the toggle OSC button was pressed 
	if Input.is_action_just_pressed(KEY_HIDE_JOYSTICKS) and control_mode == ControlMode.VIRTUAL_JOYSTICKS:
		ON_SCREEN_CONTROLS.visible = !ON_SCREEN_CONTROLS.visible
		CROSSHAIR.hide()
	# Movement mode switch
	if Input.is_action_just_pressed(KEY_MODE_SWITCH):
		if md():
			set_wasd()
		elif wasd():
			set_vj()
		elif vj():
			set_md()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# If OSC aren't visibile, its VJ mode, and the mouse button was just pressed
			if vj() and not ON_SCREEN_CONTROLS.visible:
				ON_SCREEN_CONTROLS.show()
			# If crosshair not shown and mouse not captured, not rotating player
			# and mouse was clicked, return to capturing mouse and rotating
			elif wasd():
				mouse_captured = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				CROSSHAIR.show()

# Input event will always fire no matter if already consumed and will do it immediately
# Capture mouse motion input and update rotations
func _input(event):
	if Engine.is_editor_hint():
		return

	# Process mouse motion when the mouse is captured
	if wasd() and event is InputEventMouseMotion and mouse_captured:
		set_rotation_target(event.relative)
	# Mouse dragging movement
	if md():
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				dragging = event.pressed
				if dragging:
					last_mouse_position = event.position
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_camera(1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_camera(-1)
		elif event is InputEventMouseMotion and dragging:
			var delta = event.position - last_mouse_position
			last_mouse_position = event.position

			# Calculate right and forward directions
			var right = -global_transform.basis.x
			var forward = -global_transform.basis.z

			# Move camera
			global_translate((right * delta.x + forward * delta.y) * drag_sensitivity)
func zoom_camera(direction: int) -> void:
	var move_amount: float = zoom_sensitivity * direction
	var new_pos: Vector3 = global_position + Vector3.UP * -move_amount

	var distance: float = new_pos.y
	if distance >= zoom_min and distance <= zoom_max:
		global_position = new_pos

func movement(move_direction: Vector3):
	# Normalize the movement vector to ensure consistent speed
	if move_direction.length() > 1:
		move_direction = move_direction.normalized()
	var speed_mod = sprint_multiplier if Input.is_action_pressed(KEY_SPRINT) else 1.0
	# If not height lock, normal velocity
	if !height_lock:
		# Get the direction relative to the camera orientation
		var forward = -camera.global_transform.basis.z
		var right = camera.global_transform.basis.x
		var up = Vector3.UP
		velocity = (forward * move_direction.z + right * move_direction.x + up * move_direction.y) * movement_speed * speed_mod
	# If height lock, never change height (y velocity 0)
	else:
		var forward = -camera.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		var right = camera.global_transform.basis.x
		right.y = 0
		right = right.normalized()
		var up = Vector3.UP
		velocity = (forward * move_direction.z + right * move_direction.x + up * move_direction.y) * movement_speed * speed_mod
	# Execute velocity update
	move_and_slide()


# Handle player movement input and apply to the character
func input_polling():
	var move_direction = Vector3.ZERO # Initial movement direction is zero
		
	if Input.is_action_just_pressed(KEY_HEIGHT_LOCK):
		height_lock = !height_lock
		
		HEIGHT_LOCK_BUTTON.button_pressed = height_lock
			
	
	# Escape key toggles mouse capture in wasd mode, hides chart if not mouse capture
	if Input.is_action_just_pressed(KEY_ESCAPE) or Input.is_action_just_pressed(KEY_INV):
		if wasd():
			if mouse_captured:
				mouse_captured = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				CROSSHAIR.hide()
			elif CUSTOM_CHART.visible == true:
				CUSTOM_CHART.hide()
		elif CUSTOM_CHART.visible == true:
			CUSTOM_CHART.hide()
	# Movement input handling per mode
	if wasd():
		if mouse_captured:
			move_direction.x = Input.get_axis(KEY_LEFT, KEY_RIGHT)
			move_direction.y = Input.get_axis(KEY_DOWN, KEY_UP)
			move_direction.z = Input.get_axis(KEY_BACKWARD, KEY_FORWARD)
			movement(move_direction)
	elif vj():
		move_direction.x = LEFT_VJ.output.x
		move_direction.y = int(UP_BUTTON.button_pressed) - int(DOWN_BUTTON.button_pressed)
		move_direction.z = -LEFT_VJ.output.y
		movement(move_direction)
		var look_input := RIGHT_VJ.output
		if look_input.length() > 0.01:
			var joystick_motion = Vector2(look_input.x, look_input.y)
			set_rotation_target(joystick_motion * 10.0) # 10.0 is a sensitivity multiplier, adjust as needed
	# Nothing to do for md(), handled in _input, _input does mouse events constantly 
	# Rather than polling per frame
	# which makes it smoother
	elif !md():
		print("Invalid control mode, changing to wasd")
		control_mode = ControlMode.WASD
		
	
	
	
		
	# Raycasting if user clicked mouse to see if they hit an info point
	if Input.is_action_just_pressed(CLICK):
		var space_state = get_world_3d().direct_space_state
		var cam = camera
		var mouse_pos = get_viewport().size / 2 if mouse_captured else get_viewport().get_mouse_position()


		var origin = cam.project_ray_origin(mouse_pos)
		var end = origin + cam.project_ray_normal(mouse_pos) * RAY_LENGTH

		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true

		# Optional: you can also enable collide_with_bodies = true if needed
		# query.collide_with_bodies = true

		var result = space_state.intersect_ray(query)
		handle_ray_result(result)
func handle_ray_result(result: Dictionary) -> void:
	if result and result.collider.is_in_group("info_points"):
		this_hit = result.collider
		if last_hit != this_hit:
			this_hit.get_parent().set_surface_override_material(0, RED)
			if last_hit:
				last_hit.get_parent().set_surface_override_material(0, BLUE)
			last_hit = this_hit
			print("New info point selected:", this_hit.get_parent().name)
			update_room(this_hit.get_parent().name)
	else:
		# No hit, or hit something not in info_points → clear last highlight
		if last_hit:
			last_hit.get_parent().set_surface_override_material(0, BLUE)
			last_hit = null
func select_mode_int(i: int):
	match i:
		0:
			set_md()
		1:
			set_wasd()
		2:
			set_vj()
func wasd():
	return control_mode == ControlMode.WASD
func vj():
	return control_mode == ControlMode.VIRTUAL_JOYSTICKS
func md():
	return control_mode == ControlMode.MOUSE_DRAG
	
func set_wasd():
	set_control_mode(ControlMode.WASD)
func set_vj():
	set_control_mode(ControlMode.VIRTUAL_JOYSTICKS)
func set_md():
	rotation_target_player = 0.0
	rotation_target_head = deg_to_rad(-90.0)
	set_control_mode(ControlMode.MOUSE_DRAG)
	
func set_control_mode(mode: ControlMode):
	control_mode = mode
	
	match mode:
		ControlMode.WASD:
			MOVE_MODE_SEL.select_wasd()
			HEIGHT_LOCK_BUTTON.disabled = false
			dragging = false
			mouse_captured = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
			ON_SCREEN_CONTROLS.hide()
			CROSSHAIR.show()

		ControlMode.VIRTUAL_JOYSTICKS:
			MOVE_MODE_SEL.select_vj()
			HEIGHT_LOCK_BUTTON.disabled = false
			dragging = false
			mouse_captured = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			ON_SCREEN_CONTROLS.show()
			CROSSHAIR.hide()

		ControlMode.MOUSE_DRAG:
			MOVE_MODE_SEL.select_md()
			HEIGHT_LOCK_BUTTON.disabled = true
			mouse_captured = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			ON_SCREEN_CONTROLS.hide()
			CROSSHAIR.hide()


# ======================================== #

const RAY_LENGTH = 10000

var last_hit: Node3D
var this_hit: Node3D


func update_room(name: String) -> void:
	var room_id = name.split(" ")[0]
	CUSTOM_CHART.show_chart_for_room(room_id)
	
	



	
# Update the target rotations for the player and camera based on mouse motion
func set_rotation_target(mouse_motion: Vector2):
	# Update player rotation based on mouse X movement
	rotation_target_player += -mouse_motion.x * MOUSE_SENS
	# Update head rotation based on mouse Y movement
	rotation_target_head += -mouse_motion.y * MOUSE_SENS
	## Wrap yaw to keep it in a sane range
	#rotation_target_player = wrapf(rotation_target_player, -PI, PI)

	# Clamp the head rotation if enabled
	if CLAMP_HEAD_ROTATION:
		rotation_target_head = clamp(rotation_target_head, deg_to_rad(CLAMP_HEAD_ROTATION_MIN), deg_to_rad(CLAMP_HEAD_ROTATION_MAX))

# Rotate the player and camera smoothly based on target rotation
func rotate_player(delta):
	

	if MOUSE_ACCEL_STATE:
		# Apply spherical interpolation (slerp) for smooth rotation
		quaternion = quaternion.slerp(Quaternion(Vector3.UP, rotation_target_player), MOUSE_ACCEL * delta)
		camera.quaternion = camera.quaternion.slerp(Quaternion(Vector3.RIGHT, rotation_target_head), MOUSE_ACCEL * delta)
	else:
		# If mouse acceleration is off, directly set to target rotation
		quaternion = Quaternion(Vector3.UP, rotation_target_player)
		camera.quaternion = Quaternion(Vector3.RIGHT, rotation_target_head)
