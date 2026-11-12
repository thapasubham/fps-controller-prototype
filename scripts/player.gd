extends CharacterBody3D
@export_category("Player")

@export_group("Movement")
@export_range(5.0, 20.0, 0.5, "suffix:m/s") var walk_speed: float = 5.0
@export_range(1.0, 25.0, 0.1, "suffix:m/s²") var ground_acceleration: float = 12.0
@export_range(1.0, 5.0, 0.1, "suffix:m/s²") var air_acceleration: float = 2.0
@export_range(5.0, 20.0, 0.5, "suffix:m/s") var forward_push: float = 5.0

@export_range(0.001, 0.01, 0.0001) var mouse_sensitivity: float = 0.003

@export_subgroup("Jump")
@export_range(0.5, 4.0, 0.1, "suffix:m") var jump_height: float = 1.5
@export_range(1, 3,1) var max_air_Jump: int = 2
@export_range(3.0, 5.0, 0.1, "suffix:s") var wall_run_time: float = 3.0
var current_jump =0

@export_group("Camera")
@export var base_fov: float = 75.0
@export var fov_zoom_multiplier: float = 1.5
@onready var cameraObt: Camera3D = $head/Camera3D 

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
	if not is_on_floor():
		on_air= true	
		velocity.y -= gravity * delta
	if is_on_floor():
		on_air= false	

		current_jump = 0
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
	move_and_slide()
	
func jump():
	if is_on_floor() or current_jump<max_air_Jump:
		var is_air_jump = not is_on_floor()
		if is_air_jump:
			velocity.y =0
			velocity.x *= forward_push
			velocity.z *= forward_push
		velocity.y = sqrt(2* gravity + jump_height)
		current_jump+=1
