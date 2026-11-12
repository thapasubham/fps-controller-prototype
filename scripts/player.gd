extends CharacterBody3D
@export_category("Player")

@export_group("Movement")
@export_range(5.0, 20.0, 0.5, "suffix:m/s") var walk_speed: float = 5.0
@export_range(1.0, 25.0, 0.1, "suffix:m/s²") var ground_acceleration: float = 12.0
@export_range(1.0, 5.0, 0.1, "suffix:m/s²") var air_acceleration: float = 2.0
@export_range(2, 10, 0.5, "suffix:m/s") var forward_push: float = 2.5
@export_range(1.0, 3.0, 0.1) var wall_forward_boost: float = 0.5
@export var wall_gravity_scale: float = 0.2

@export_range(0.001, 0.01, 0.0001) var mouse_sensitivity: float = 0.003

@export_subgroup("Jump")
@export_range(0.5, 4.0, 0.1, "suffix:m") var jump_height: float = 1.5
@export_range(5.0, 20.0, 0.5, "suffix:m/s") var wall_kick_force: float = 8.0
@export_range(0.2, 1.0, 0.05) var auto_wall_kick_scale: float = 0.4

@export_range(1, 3,1) var max_jump_count: int = 2
@export_range(3.0, 5.0, 0.1, "suffix:s") var wall_run_time: float = 2.0

var current_jump =0
var current_wall_run_time: float = 0.0

@export_group("Camera")
@export var base_fov: float = 75.0
@export var fov_zoom_multiplier: float = 1.5
@onready var cameraObt: Camera3D = $head/Camera3D
@onready var wall_run_bar: ProgressBar = $UI/WallRunBar

var on_wall = false
var on_air= false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var head: Node3D = $head
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
func _physics_process(delta: float) -> void:
	
	on_air = not is_on_floor()
	on_wall = is_on_wall() and on_air

	if on_air:
		if on_wall and velocity.y<0:
			if current_wall_run_time<=wall_run_time:
				current_wall_run_time+=delta
				velocity.y -=  wall_gravity_scale * delta
			else:
				_apply_wall_kick(wall_kick_force)
				velocity.y = sqrt(2.0 * gravity * jump_height) * auto_wall_kick_scale
				current_wall_run_time = 0.0
				current_jump = 0
		else:
			velocity.y -= gravity* delta
	else:
		on_air = false
		current_wall_run_time = 0.0
		current_jump = 0

	wall_run_bar.visible = on_wall and velocity.y < 0
	wall_run_bar.value = (1.0 - (current_wall_run_time / wall_run_time)) * 100.0

	var input := Input.get_vector("left", "right", "forward", "backward")
	var direction := transform.basis * Vector3(input.x, 0, input.y)
	var target_velocity = direction * walk_speed
	var acceleration = air_acceleration if on_air else ground_acceleration
	velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)
	
	if Input.is_action_just_pressed("jump"): 
		jump()
	var horizontal_speed := Vector3(velocity.x, 0, velocity.z).length()
	var target_fov = base_fov + (horizontal_speed * fov_zoom_multiplier)
	cameraObt.fov = lerp(cameraObt.fov, target_fov, delta * 4.0)
	
	var target_roll = 0.0
	if on_wall:
		var wall_normal = get_wall_normal()
		var right_dir = transform.basis.x
		var side = sign(wall_normal.dot(right_dir))
		target_roll = deg_to_rad(-10.0 * side)
		
	cameraObt.rotation.z = lerp(cameraObt.rotation.z, target_roll, delta * 5.0)
	
	move_and_slide()
	
func jump():
	if on_wall and not is_on_floor():
		wall_jump()
	elif is_on_floor() or current_jump < max_jump_count:
		air_jump()

func air_jump():
	var is_air_jump = not is_on_floor()
	if is_air_jump:
		velocity.y = 0.0
		velocity.x *= forward_push
		velocity.z *= forward_push
	velocity.y = sqrt(2.0 * gravity * jump_height)
	current_jump += 1

func wall_jump():
	velocity.y = sqrt(2.0 * gravity * jump_height)
	_apply_wall_kick(wall_kick_force)
	current_wall_run_time = 0.0
	current_jump = 0

func _apply_wall_kick(force: float) -> void:
	var wall_normal = get_wall_normal()
	var forward_dir = -transform.basis.z
	var kick_vector = (wall_normal * force) + (forward_dir * wall_forward_boost * walk_speed)
	velocity.x = kick_vector.x
	velocity.z = kick_vector.z
