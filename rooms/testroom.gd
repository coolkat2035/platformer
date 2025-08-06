extends Node2D

@onready var sticks: CharacterBody2D = $sticks
@onready var claw: CharacterBody2D = $claw #????????????????????????
@onready var clawstate: Label = $clawstate

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_released("exit"):
		get_tree().quit()
	clawstate.text = "claw state: "+str(sticks.ClawStates.keys()[sticks.claw_state])+"\n"

func _on_sticks_shoot_claw(location, isLeft) -> void:
	print(location, isLeft, " uwu")
	claw.position = location
	
func _on_sticks_retract_claw(location: Variant) -> void:
	pass # Replace with function body.
