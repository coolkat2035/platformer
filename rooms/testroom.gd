extends Node2D

@onready var sticks: CharacterBody2D = $sticks
@onready var claw: CharacterBody2D = $claw #????????????????????????
@onready var clawstate: Label = $sticks/clawstate
@onready var test_camera: Camera2D = $sticks/testCamera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	clawstate.text = "claw state: "+str(sticks.ClawStates.keys()[sticks.claw_state])+"\n"

	if Input.is_action_just_pressed("test"):
		test_camera.shake(99,99)
	if Input.is_action_just_pressed("jump"):
		test_camera.reset_offset()
	if Input.is_action_just_released("exit"):
		get_tree().quit()

func _on_sticks_shoot_claw(location, isLeft) -> void:
	print(location, isLeft, " uwu")
	claw.position = location
	

func _on_sticks_retract_claw(location: Variant) -> void:
	pass # Replace with function body.
