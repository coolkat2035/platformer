extends CharacterBody2D

const THRES:=30 #for distance
var SHOOT_SPEED  #0.4 seconds longest ( var ARM_LENGTH = 400
var RETURN_SPEED
var CLAW_LINGER = 0.2 #linger time of the claw
var player
var goal: Vector2
var returned = true

@onready var sprite: Sprite2D = $sprite

func _ready():
	player = get_parent()
	#player.claw_state = player.ClawStates.FLYING
	#if player.isLeft:
		#
	#else:
		#sprite.set_flip_h(true)
	sprite.set_flip_h(true)
	SHOOT_SPEED = player.SHOOT_SPEED
	RETURN_SPEED = player.RETURN_SPEED
	
signal claw_return
signal claw_ready
signal claw_hanging

func _physics_process(delta: float) -> void:
	
	#Hit something or miss
	if _is_near(global_position, goal, THRES) and player.claw_state == player.ClawStates.FLYING:
		print("reach goal, returning")
		if player.catch_land:
			print("land!")
			player.claw_state = player.ClawStates.LAND
		else:
			player.claw_state = player.ClawStates.MISS #coupling bruh
		#player.claw_state = player.ClawStates.RETURN

	if _is_near(global_position, player.global_position, THRES):
		match (player.claw_state):
			player.ClawStates.READY:
				velocity = Vector2.ZERO
			player.ClawStates.RETURN:
				print("reached player!!!")
				claw_ready.emit()
				#player.claw_state = player.ClawStates.READY
				set_visible(false)
				velocity = Vector2.ZERO
			player.ClawStates.LAND:
				print("hanging on the wall/floor")
				claw_hanging.emit()
			
	match (player.claw_state):
		player.ClawStates.FLYING:
			move(goal)
			look_at(goal)
		player.ClawStates.RETURN:
			retrn(player.global_position)
		player.ClawStates.MISS:
			velocity = Vector2.ZERO
			get_tree().create_timer(CLAW_LINGER).timeout.connect(_on_linger_timeout)
			print("empty :(")
		player.ClawStates.LAND:
			#after landing, press x to hold retracting
			velocity = Vector2.ZERO
			#print("land... hmm how to retract arm?")
			
			#player.claw_state = player.ClawStates.RETURN
		
	move_and_slide()
	
func move(target:Vector2):
	print("goal: ", goal, "vel: ", velocity)
	velocity = global_position.direction_to(target)*SHOOT_SPEED
	
func retrn(target:Vector2):
	velocity = global_position.direction_to(target)*RETURN_SPEED

func _on_linger_timeout():
	print("returning after miss")
	claw_return.emit()

func _is_near(pos1:Vector2, pos2:Vector2, thres:int) -> bool:
	return pos1.distance_to(pos2) < thres
