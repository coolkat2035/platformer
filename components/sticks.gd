extends CharacterBody2D
## how to limit 
const GRAVITY = Vector2(0,3500)
const SPEED = 500.0
const JUMP_VELOCITY = -1300.0
const TERM_VEL = 2000
var isLeft = true
#detect up or down with direction v
var direction_v:float = 0 #up is negative
var direction_h:float = 0
@onready var anim: AnimatedSprite2D = $anim

@onready var claw: CharacterBody2D = $claw
@onready var arm_left: Marker2D = $armLeft
@onready var arm_right: Marker2D = $armRight
signal shoot_claw(location, isLeft)
signal retract_claw()
enum ClawStates {READY, SHOOT, FLYING, LAND,HANGING, MISS, RETURN}
@export var claw_state := ClawStates.READY
@export var ARM_LENGTH = 400
@export var SHOOT_SPEED = 2000
@export var RETURN_SPEED = 4000

#determine if can shoot (unused
const CLAW_CD = 0.1
var claw_coolover = true
#det the time player holds in the air when it shoots
@export var CLAW_SHOOT_PAUSE = 0.001
var yvel_before_fall = 0
var claw_pause_over = true

@onready var c_left: RayCast2D = $cLeft
@onready var c_up_left: RayCast2D = $cUpLeft
@onready var c_down_left: RayCast2D = $cDownLeft

@onready var c_right: RayCast2D = $cRight
@onready var c_up_right: RayCast2D = $cUpRight
@onready var c_down_right: RayCast2D = $cDownRight

@onready var c_up: RayCast2D = $cUp
@onready var c_down: RayCast2D = $cDown

@onready var debug_point: Sprite2D = $debugPoint


func _ready() -> void:
	claw_state = ClawStates.READY

	debug_point.top_level = true
	claw.top_level = true
	debug_point.z_index = 999
	#arms
	c_left.target_position = Vector2(-ARM_LENGTH,0)
	c_right.target_position = Vector2(ARM_LENGTH,0)
	c_up.target_position = Vector2(0,-ARM_LENGTH)
	c_down.target_position = Vector2(0,ARM_LENGTH)
	
func _process(d):
	#handle anims
	#shoulda made left and right separately??
	if Input.is_action_just_pressed("ui_left"):
		isLeft = true
	elif Input.is_action_just_pressed("ui_right"):
		isLeft = false
		
	if is_on_floor():
		if direction_h:
			if direction_h < 0:
				anim.flip_h = false
			else:
				anim.flip_h = true
			anim.play("walk")
		else:
			anim.play("idle")
	else:
		anim.play("jump")
		#if velocity.y > 0:#fall
			#anim.frame = 1
	
	if Input.is_action_pressed("jump"):
		anim.play("jump")
	#handle shoot
	if Input.is_action_just_pressed("shoot"):
		shoot()
	#retract
	if Input.is_action_just_released("shoot"):
		retract()
		
var catch_land := false #would it be useful
func shoot():
	if claw_state == ClawStates.READY:
		anim.play("shoot")
		
		var origin := arm_left if isLeft else arm_right
		#print(origin.position, origin.global_position)
		
		#choose where to shoot at
		var target_ray
		if direction_v:
			#up or down first
			if direction_v <0:
				if direction_h < 0:
					target_ray = c_up_left
				elif direction_h == 0:
					target_ray = c_up
				else:
					target_ray = c_up_right
			else:
				if direction_h < 0:
					target_ray = c_down_left
				elif direction_h == 0:
					target_ray = c_down
				else:
					target_ray = c_down_right
		else:
			if isLeft:
				target_ray = c_left
			else:
				target_ray = c_right
				
		if target_ray.is_colliding() and target_ray.get_collision_point().distance_to(position)<50:
			print("too close")
			return
			
		#claw.connect("claw_ready", _on_claw_claw_ready)
		#claw.connect("claw_return", _on_claw_claw_return)
		#claw.connect("claw_hanging", _on_claw_claw_hanging)
		
		claw.set_visible(true)
		claw_state = ClawStates.FLYING
		claw.global_position = origin.global_position
		claw.z_index = 2
		
		if target_ray.is_colliding():
			claw.goal = target_ray.get_collision_point()
			catch_land = true
		else:
			claw.goal = global_position + target_ray.target_position
			catch_land = false
			#claw_state = ClawStates.MISS
		#claw.goal.x += claw.get_node("sprite").texture.get_width()/2
		debug_point.visible = true
		debug_point.global_position = claw.goal
func retract():
	print("retract uwu")
	if claw_state != ClawStates.READY:
		#if claw_state == ClawStates.HANGING:
			#print("drop")
			#claw_state = ClawStates.READY
		#else:
		claw_state = ClawStates.RETURN
	#await get_tree().create_timer(CLAW_CD).timeout
func pull():
	#pull by the claw to the wall/pull obj
	#only pull if no x button and state is landed
	#pull to wall
	if claw_state == ClawStates.LAND:
		if _is_near(position, claw.goal,50):
			print("hanging on the wall/floor")
			claw_state = ClawStates.HANGING
		else:
			velocity = position.direction_to(claw.global_position)*SHOOT_SPEED*1

func hang():
	if claw_state == ClawStates.HANGING:
		velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	direction_v = Input.get_axis("ui_up", "ui_down")
	direction_h = Input.get_axis("ui_left", "ui_right")
	# Add the gravity, no higher than the terminal vel.
	if not is_on_floor() or velocity.y < TERM_VEL:
		velocity += GRAVITY * delta
	if velocity.y > TERM_VEL:
		velocity.y = TERM_VEL
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	#drop immediately when button released
	if Input.is_action_just_released("jump") and not is_on_floor() and velocity.y < 0:
		velocity.y = 0
		
	#hold in the air when the claw just shoots
	if Input.is_action_just_pressed("shoot"):
		yvel_before_fall = velocity.y
		claw_pause_over = false
		get_tree().create_timer(CLAW_SHOOT_PAUSE).timeout.connect(_on_clawShootPause_timeout)
		#show where da hell the point is at
		
	if not claw_pause_over:
		velocity.y = 0
		
	#walking
	#todo only allow walking if no claw out or is within arm length
	#if !claw or global_position.distance_to(claw.global_position)<ARM_LENGTH:
	if direction_h:
		velocity.x = direction_h * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	pull()
	hang()
	move_and_slide()

func _on_clawShootPause_timeout()->void:
	claw_pause_over = true
	velocity.y = yvel_before_fall * .4


func _on_claw_claw_return() -> void:
	print("return")
	claw_state = ClawStates.RETURN

func _on_claw_claw_hanging() -> void:
	print("hanging on wall")
	claw_state = ClawStates.HANGING
func _on_claw_claw_ready() -> void:
	print("ready")
	claw_state = ClawStates.READY
func _is_near(pos1:Vector2, pos2:Vector2, thres:int) -> bool:
	return pos1.distance_to(pos2) < thres
