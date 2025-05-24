extends CharacterBody2D


const SPEED = 500.0
const ACCELERATION = 45.0
const JUMP_VELOCITY = -900.0

@onready var nametag: Label = %Nametag
@onready var player_camera: Camera2D = %PlayerCamera

func _ready() -> void:
	var player_id := name.to_int()
	set_multiplayer_authority(player_id, true)
	if nametag.text == "Player":
		nametag.text = Network.player_info.name
	else:
		nametag.text = Network.connected_players[player_id].name

	if is_multiplayer_authority():
		player_camera.make_current()

func _physics_process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority(): return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * 1.5 * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, ACCELERATION)

	move_and_slide()
