extends CharacterBody3D

const SPEED: float = 6.0
const JUMP_SPEED: float = 7.0
const GRAVITY: float = 20.0
const MOUSE_SENSITIVITY: float = 0.0025
const MAX_STEP_HEIGHT: float = 0.35

var controls_active: bool = true
var crouching := false
var sprinting := false
var sprint_toggled := false
var sliding := false
var slide_remaining := 0.0
var slide_direction := Vector3.ZERO
var slide_cooldown := 0.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	for binding in [["sprint",KEY_SHIFT],["crouch",KEY_CTRL]]:
		if not InputMap.has_action(binding[0]):
			InputMap.add_action(binding[0])
			var key := InputEventKey.new()
			key.physical_keycode = binding[1]
			InputMap.action_add_event(binding[0],key)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	floor_snap_length = 0.4

func _unhandled_input(event: InputEvent) -> void:
	if self.get_meta("dead", false) or (get_parent().has_node("Rounds") and get_parent().get_node("Rounds").phase == "results"):
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		controls_active = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not controls_active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		controls_active = true
		get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and controls_active:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY * get_node("/root/GameSettings").sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * MOUSE_SENSITIVITY * get_node("/root/GameSettings").sensitivity, deg_to_rad(-85), deg_to_rad(85))

func reset_movement() -> void:
	sprint_toggled = false
	sprinting = false
	sliding = false
	slide_remaining = 0.0
	slide_cooldown = 0.0
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not get_parent().get_meta("round_active",true) or get_meta("dead",false):
		reset_movement()
		return
	slide_cooldown = maxf(0,slide_cooldown-delta)
	if not controls_active:
		reset_movement()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var direction := Vector3.ZERO
	var crouch_held := controls_active and Input.is_action_pressed("crouch")
	if controls_active:
		var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		direction = (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
		if Input.is_action_just_pressed("sprint"):
			sprint_toggled = not sprint_toggled
			if sprint_toggled:
				sliding = false
				crouch_held = false
		if Input.is_action_just_pressed("crouch"):
			if sprinting and is_on_floor() and slide_cooldown == 0 and Vector2(velocity.x,velocity.z).length() > 6:
				sliding = true
				slide_remaining = .85
				slide_direction = Vector3(velocity.x,0,velocity.z).normalized()
				slide_cooldown = 1.2
			sprint_toggled = false
		if Input.is_action_just_pressed("jump") and is_on_floor():
			sliding = false
			velocity.y = JUMP_SPEED
	if sliding:
		slide_remaining = maxf(0,slide_remaining-delta)
		if slide_remaining == 0 or not is_on_floor():
			sliding = false
	_update_crouch(sliding or (crouch_held and not sprint_toggled))
	sprinting = controls_active and sprint_toggled and not crouching and not sliding and direction.length_squared() > 0
	var pace: float = 2.8 if crouching else (9.0 if sprinting else SPEED)
	if sliding:
		# Preserve momentum direction while allowing independent mouse look.
		direction = slide_direction
		pace = lerpf(3.0,11.5,slide_remaining/.85)
	velocity.x = direction.x * pace
	velocity.z = direction.z * pace
	_try_step_up(Vector3(velocity.x,0,velocity.z) * delta)
	move_and_slide()
	if sliding and is_on_wall():
		sliding = false
	camera.position.y = lerpf(camera.position.y,0.0 if crouching else 0.65,1.0-exp(-delta*14.0))
	if global_position.y < -12.0:
		global_position = Vector3(0, 1.0, 6)
		reset_movement()
func _try_step_up(motion: Vector3) -> bool:
	if not is_on_floor() or velocity.y > 0.0 or motion.length_squared() < 0.000001:
		return false
	var obstacle := KinematicCollision3D.new()
	if not test_move(global_transform,motion,obstacle):
		return false
	# Only step over edges; ordinary walkable slopes already work with sliding.
	if obstacle.get_normal().dot(Vector3.UP) >= cos(floor_max_angle):
		return false
	var lifted: Transform3D = global_transform
	var lift := Vector3.UP * MAX_STEP_HEIGHT
	if test_move(lifted,lift):
		return false
	lifted.origin += lift
	var probe_motion: Vector3 = motion.normalized() * maxf(motion.length(),0.42)
	if test_move(lifted,probe_motion):
		return false
	lifted.origin += probe_motion
	var landing := KinematicCollision3D.new()
	if not test_move(lifted,Vector3.DOWN * (MAX_STEP_HEIGHT + 0.06),landing):
		return false
	if landing.get_normal().dot(Vector3.UP) < cos(floor_max_angle):
		return false
	var height: float = lifted.origin.y + landing.get_travel().y - global_position.y
	if height < 0.015 or height > MAX_STEP_HEIGHT + 0.001:
		return false
	global_position.y += height + 0.002
	# Keep the view continuous while the collision body steps up.
	camera.position.y -= height
	return true


func _update_crouch(wanted: bool) -> void:
	if wanted == crouching:
		return
	var collision: CollisionShape3D = $CollisionShape3D
	if not wanted:
		var full := CapsuleShape3D.new()
		full.radius = 0.35
		full.height = 1.72
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = full
		query.transform = global_transform
		query.transform.origin.y += 0.04
		query.exclude = [get_rid()]
		query.margin = 0.001
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
			return
	crouching = wanted
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.15 if crouching else 1.8
	collision.shape = capsule
	collision.position.y = -0.325 if crouching else 0.0