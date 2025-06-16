extends Panel

@export var help_button: Button

# Show on ready, if hidden in the editor to not clutter it
func _ready():
	visible = true

func _on_help_button_pressed():
	visible = true

func _on_ok_pressed():
	visible = false
