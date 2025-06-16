extends TextureButton

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var local_pos: Vector2 = get_local_mouse_position()
		var tex: Texture2D = texture_normal

		if tex is CompressedTexture2D:
			var img: Image = tex.get_image()
			if not img.is_empty():
				var x: int = int(local_pos.x)
				var y: int = int(local_pos.y)

				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
					var pixel: Color = img.get_pixel(x, y)
					if pixel.a < 0.1:
						# Transparent - manually stop the event from doing anything
						get_viewport().set_input_as_handled()
						return

		
