extends KinematicBody

var direction = Vector3.FORWARD
var velocity = Vector3.ZERO
var acceleration = 6

var vertical_velocity = 0
var gravity = 28

var weight_on_ground = 4

var movement_speed = 6
var walk_speed = 1.5
var run_speed = 5
var angular_acceleration = 7
var running = false

var jump_magnitude = 12
var jump_stop = Input.is_action_just_released("jump")
var backdash_magnitude = -12

var ag_transition = "parameters/ag_transition/current"
var jump_blend = "parameters/jump_blend/blend_position"
export var can_move = true
export var can_slide = true


var crouching = false
var cs_transition = "parameters/cs_transition/current"

onready var sword = $Mesh/Skeleton/Sword
onready var swordslashtimer = $swordslashtimer
var swordslash = "parameters/swordslash_shot/active"


#var superun_toggle = false
#var superun_speed = 12

#onready var cam = $Camroot/h
#onready var cam = $Camroot02

onready var cam = get_node("/root/LevelNode/Localcam/h_rotate/Plr_reference")
onready var level_node = get_node("LevelNode")
func some_function():
	var camera_name = "h_rotate"
	var camera_path = "/root/Localcam/" + camera_name
	var camera_global_transform = level_node.get_node(camera_path).global_transform
	var h_rot = camera_global_transform.basis.get_euler().y

#===============================================


func _ready():

	direction = Vector3.BACK.rotated(Vector3.UP, cam.global_transform.basis.get_euler().y)
	
	

#=============MAPEAMENTO NA TELA=================

func _input(event):
	
	#if event is InputEventKey:
	#	if event.as_text() == "W" || event.as_text() == "A" || event.as_text() == "S" || event.as_text() == "D" || event.as_text() == "Kp 2" || event.as_text() == "Kp 1"|| event.as_text() == "Kp 0":

	#			if event.pressed:
	#				get_node("Status/" + event.as_text()).color = Color("0000f1")
	#			else:
	#				get_node("Status/" + event.as_text()).color = Color("ffffff")

	if event.is_action_pressed("run"):
		running = true if running else true
	else:
		running = Input.is_action_pressed("run")


#______isso é um switch!!____
#sword.set("visible", !sword.get("visible"))
#___________________________


#=============BACKDASH=================

	if is_on_floor():
		
		if !$AnimationTree.get("parameters/backdash/active"):
			if Input.is_action_pressed("backdash"):
				if $backdashtimer.is_stopped():
					$backdashtimer.start()
		
				if !$backdashtimer.is_stopped():
					velocity = direction * backdash_magnitude
					$backdashtimer.stop()
					$AnimationTree.set("parameters/backdash/active", true)
					$backdashtimer.start()


	#==========MAPEAMENTO CONTROLE============
	if Input.get_connected_joypads().size() > 0:

		for i in range(26):
			if Input.is_joy_button_pressed(0,i):
				print(str(i) + Input.get_joy_button_string(i))


#===============TECLADO E CONTROLE======PRECISA DESATIVAR A PARTIR DAQUI, ATE O FINAL=======

func _physics_process(delta):

	if can_move:

		#var h_rot = cam2.global_transform.basis.get_euler().y
		#var h_rot = global_transform.basis.get_euler().y
		var h_rot = cam.global_transform.basis.get_euler().y
		
		
		if Input.is_action_pressed("rgt") || Input.is_action_pressed("lft") || Input.is_action_pressed("dwn") || Input.is_action_pressed("up"):
			
			direction = Vector3(Input.get_action_strength("lft") - Input.get_action_strength("rgt"),
						0,
						Input.get_action_strength("up") - Input.get_action_strength("dwn"))


			direction = direction.rotated(Vector3.UP, h_rot).normalized()
			
			if running && $AnimationTree.get("parameters/iwr_blend/blend_amount"):
				movement_speed = run_speed
			else:
				movement_speed = walk_speed
				
		else:
			movement_speed = 0


		velocity = lerp(velocity, direction * movement_speed, delta * acceleration)
	
	if can_slide:
		move_and_slide(velocity + Vector3.UP * vertical_velocity - get_floor_normal() * weight_on_ground, Vector3.UP)


#============GRAVIDADE=========

	if !is_on_floor():
		vertical_velocity -= gravity * delta
	else:
		if vertical_velocity < -9:
			landing()
		if vertical_velocity <-17:
			herolanding()
		vertical_velocity = 0


#=======SMOOTH ANIMACAO VIRAR CORPO=========

	$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(direction.x, direction.z), delta * angular_acceleration)

	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)

	if velocity.length() <= walk_speed:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , iw_blend)
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , wr_blend)

#=============MOVEMENTS SYSTEM=================

#	if is_on_floor() || $RayCast.is_colliding() || $RayCastb.is_colliding():
	if is_on_floor():
		if !$AnimationTree.get("parameters/backdash/active"):
			$AnimationTree.set(ag_transition, 1)
			if Input.is_action_just_pressed("jump"):
				vertical_velocity = jump_magnitude
				#$Soundjump.play()

		if Input.is_action_just_pressed("backdash"):
			$AnimationTree.set("parameters/backdash/active", true)
			$backdashtimer.start()
			velocity = (direction + get_floor_normal()) * backdash_magnitude

		if Input.is_action_pressed("crouch"):
			$AnimationTree.set(cs_transition, 1)
			velocity = (direction + get_floor_normal()) * 0
			can_move = false
			can_slide = false
		else:
			if Input.is_action_just_released("crouch"):
				$AnimationTree.set(cs_transition, 0)
				can_move = true
				can_slide = true

		if Input.is_action_pressed("action"):
			$AnimationTree.set("parameters/action_shot/active", 1)
			$actiontimer.start()
			can_move = can_move
			can_slide = can_slide
		

#		if Input.is_action_pressed("action"):
#			$AnimationTree.set("parameters/action_shot/active", 1)
#			$actiontimer.start()
#			can_move = ($actiontimer.start(5))
#			can_slide = ($actiontimer.start(5))
#		else:
#			$actiontimer.stop()
#			can_move = true
#			can_slide = true

		if Input.is_action_just_pressed("swordslash"):
			$swordslashtimer.start(5)
			$AnimationTree.set("parameters/swordslash_shot/active", 1)
			movement_speed = walk_speed
			running = false

	elif Input.is_action_just_released("jump") and vertical_velocity > 0.0:
			vertical_velocity = 0.5

	else:
		$AnimationTree.set(ag_transition, 0)
		$AnimationTree.set(cs_transition, 0)
		$AnimationTree.set(jump_blend, lerp($AnimationTree.get(jump_blend), vertical_velocity/jump_magnitude, delta * 10))

#_____________________________________________

	$Status/Label.text = "direction : " + String(direction)
	$Status/Label2.text = "direction.length() : " + String(direction.length())
	$Status/Label3.text = "velocity : " + String(velocity)
	$Status/Label4.text = "velocity.length() : " + String(velocity.length())
	$Status/Label5.text = "$RayCast_floor : " + String($RayCast.is_colliding())
	$Status/Label6.text = "RayCast2 : " + String($Mesh/RayCast2.is_colliding())
	$Status/Label7.text = "velocity.length() : " + String(vertical_velocity)

func landing():
	$AnimationTree.set("parameters/landingshot/active", true)
	$landingtimer.start()
	
func herolanding():
	$AnimationTree.set("parameters/herolandingshot/active", true)
	$herolandingtimer.start()

