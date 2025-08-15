extends CharacterBody2D

@export var claw_speed_curve: Curve
##add a pause before pulling

## how to limit 
const GRAVITY = Vector2(0,5500)
@export var SPEED = 500.0
@export var JUMP_VELOCITY = -1500.0
@export var TERM_VEL = 5000
var isLeft = true
#detect up or down with direction v
var direction_v:float = 0 #up is negative
var direction_h:float = 0
@onready var anim: AnimatedSprite2D = $anim

const CLAW_TIME = 2#time to shoot to max dist!!!!!!!!!!!!!!!!!1
var arm_origin: Marker2D
@onready var claw: CharacterBody2D = $claw
@onready var arm_left: Marker2D = $armLeft
@onready var arm_right: Marker2D = $armRight
signal shoot_claw(location, isLeft)
signal retract_claw()
enum ClawStates {READY, SHOOT, FLYING, LAND,HANGING, MISS, RETURN}
@export var claw_state := ClawStates.READY
var claw_timer:=0.0
@export var ARM_LENGTH = 600
var ARM_LENGTH_DIAGONAL = ARM_LENGTH/sqrt(2)
@export var SHOOT_SPEED = 5700
@export var RETURN_SPEED = 6000

var THRES=SHOOT_SPEED*0.01 
#determine if can shoot (unused
const CLAW_CD = 0.1
var claw_coolover = true
#det the time player holds in the air when it shoots
@export var CLAW_SHOOT_PAUSE = 0.001
var yvel_before_fall = 0
var claw_pause_over = true

#now with less claws!
@onready var claws: Node2D = $claws
@onready var debug_point: Sprite2D = $debugPoint

##jump buffer
@export var JUMP_BUFFER_TIME := 0.1
var jump_buffer := 0.0
##coyote time
@export var COYOTE_TIME := 0.1
var coyote_timer := 0.0

func _ready() -> void:
	claw_state = ClawStates.READY
	debug_point.top_level = true
	claw.top_level = true
	debug_point.z_index = 999
	#arms
	for c in claws.get_children():
		c.target_position = Vector2(ARM_LENGTH,0)
	
func _process(delta):
	#handle anims
	#shoulda made left and right separately??
	if Input.is_action_just_pressed("ui_left"):
		isLeft = true
	elif Input.is_action_just_pressed("ui_right"):
		isLeft = false
		
	if jump_buffer > 0:
		jump_buffer -= delta
	if coyote_timer > 0:
		print(coyote_timer)
		coyote_timer -= delta
	#determine ray direction
	if direction_v:
		#up or down first
		if direction_v <0:
			if direction_h < 0:
				#upleft
				claws.set_rotation_degrees(180+45)
			elif direction_h == 0:
				#up
				claws.set_rotation_degrees(270)
			else:
				#upright
				claws.set_rotation_degrees(360-45)
		else:
			if direction_h < 0:
				#downleft
				claws.set_rotation_degrees(90+45)
			elif direction_h == 0:
				#down
				claws.set_rotation_degrees(90)
			else:
				#downright
				claws.set_rotation_degrees(45)
	else:
		if isLeft:
			#left
			claws.set_rotation_degrees(180)
		else:
			#right
			claws.set_rotation_degrees(0)
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
		
		arm_origin = arm_left if isLeft else arm_right
		#print(arm_origin.position, arm_origin.global_position)
		
		#choose where to shoot at
		var target_ray := claws.get_child(0)
		for ray in claws.get_children():
			#might want to make a middle one as first in list
			if ray.is_colliding():
				target_ray = ray
				break
			
		#claw.connect("claw_ready", _on_claw_claw_ready)
		#claw.connect("claw_return", _on_claw_claw_return)
		#claw.connect("claw_hanging", _on_claw_claw_hanging)
		
		claw_timer = 0
		claw.set_visible(true)
		claw_state = ClawStates.FLYING
		claw.global_position = arm_origin.global_position
		claw.z_index = 2
		
		if target_ray.is_colliding():
			claw.goal = target_ray.get_collision_point()
			print(claw.goal, target_ray.get_collider())
			catch_land = true
		else:
			claw.goal = global_position + target_ray.target_position.rotated(claws.rotation)
			catch_land = false
			#claw_state = ClawStates.MISS
		#claw.goal.x += claw.get_node("sprite").texture.get_width()/2
		debug_point.visible = true
		debug_point.global_position = claw.goal
func retract():
	print("retract")
	if claw_state != ClawStates.READY:
		#if claw_state == ClawStates.HANGING:
			#print("drop")
			#claw_state = ClawStates.READY
		#else:
		claw_state = ClawStates.RETURN
	#await get_tree().create_timer(CLAW_CD).timeout
func pull(delta):
	#pull by the claw to the wall/pull obj
	#only pull if no x button and state is landed
	#pull to wall
	if claw_state == ClawStates.LAND:
		print("pulling")
		claw_timer += delta/CLAW_TIME
		#claw_timer = clamp(claw_timer, 0, CLAW_TIME)
		#need a way to jus tweak the claw_speed_curve and max time to control timing :(
		if _is_near(position, claw.goal,THRES):
			#print("owowwowoow ",position, "goal: ", claw.goal)
			print("hanging on the wall/floor")
			claw_state = ClawStates.HANGING
		else:
			if not Input.is_action_pressed("hold"):
				claw_state = ClawStates.LAND
				velocity = position.direction_to(claw.global_position)*SHOOT_SPEED
				velocity *= claw_speed_curve.sample(claw_timer)
			else:
				claw_state = ClawStates.HANGING
				#goto hang()
				claw_timer = 0 #?? iino
			print(claw_timer, claw_speed_curve.sample(claw_timer), velocity)

func hang():
	if claw_state == ClawStates.HANGING:
		if Input.is_action_just_released("hold"):
			claw_state = ClawStates.LAND
			return
		velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	direction_v = Input.get_axis("ui_up", "ui_down")
	direction_h = Input.get_axis("ui_left", "ui_right")
	# Add the gravity, no higher than the terminal vel.
	if not is_on_floor() or velocity.y < TERM_VEL:
		velocity += GRAVITY * delta
	if velocity.y > TERM_VEL:
		velocity.y = TERM_VEL

	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER_TIME
	
	# consume buffer when grounded, then jump
	if (is_on_floor() or coyote_timer > 0) and jump_buffer > 0.0 :
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote_timer = 0
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
		
	pull(delta)
	hang()
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	if was_on_floor and not is_on_floor() and velocity.y > 0:
		coyote_timer = COYOTE_TIME

func _on_clawShootPause_timeout()->void:
	claw_pause_over = true
	velocity.y = yvel_before_fall * .4


func _on_claw_claw_return() -> void:
	print("return")
	claw_state = ClawStates.RETURN

func _on_claw_claw_hanging() -> void:
	print("hanging on wall")
	position = claw.global_position
	claw_state = ClawStates.HANGING
func _on_claw_claw_ready() -> void:
	print("ready")
	claw_state = ClawStates.READY
func _is_near(pos1:Vector2, pos2:Vector2, thres:int) -> bool:
	return pos1.distance_to(pos2) < thres
