extends Camera2D
func reset_offset():
	offset = Vector2.ZERO
func shake(delta:float, factor: float):
	offset = Vector2(100,100)
