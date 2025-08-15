extends Camera2D
func reset_offset():
	offset = Vector2.ZERO
func shake(delta:float, factor: float):
	offset = Vector2(100,100)

func _process(delta):
	if Input.is_action_just_pressed("test"):
		shake(99,99)
	if Input.is_action_just_pressed("jump"):
		reset_offset()
