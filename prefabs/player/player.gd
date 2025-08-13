extends CharacterBody2D


const SPEED = 500.0
const ACCELERATION = 45.0
const JUMP_VELOCITY = -900.0

@onready var nametag: Label = %Nametag
@onready var player_camera: Camera2D = %PlayerCamera
@onready var hello_audio: AudioStreamPlayer2D = %HelloAudio

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int(), true)

func _ready() -> void:
	if nametag.text == "Player":
		nametag.text = Network.player_info.name
	else:
		nametag.text = Network.connected_players[name.to_int()].name

	if is_multiplayer_authority():
		player_camera.make_current()
	
	# Test audio node
	print("Hello audio node exists: ", hello_audio != null)
	if hello_audio != null:
		print("Hello audio stream: ", hello_audio.stream)
		print("Hello audio can play: ", hello_audio.stream != null)

func _physics_process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority(): return

	# Handle hello audio input
	if Input.is_action_just_pressed("hello"):
		print("H key pressed! Playing hello audio...")
		if multiplayer.has_multiplayer_peer():
			play_hello_audio.rpc()
		else:
			# Single player mode - play directly
			play_hello_audio_local()

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

func play_hello_audio_local():
	print("Playing hello audio locally...")
	hello_audio.volume_db = -5.0
	hello_audio.play()

@rpc("any_peer", "call_local", "reliable")
func play_hello_audio():
	print("RPC play_hello_audio called")
	var sender_id = multiplayer.get_remote_sender_id()
	var sender_player = null
	
	# Find the sender player
	if sender_id == 0:  # Local call
		sender_player = self
		print("Local RPC call")
	else:
		print("Remote RPC call from player: ", sender_id)
		for player in get_tree().get_nodes_in_group("Players"):
			if player.name.to_int() == sender_id:
				sender_player = player
				break
	
	if sender_player == null:
		print("Sender player not found!")
		return
	
	# Calculate distance-based volume
	var distance = global_position.distance_to(sender_player.global_position)
	var max_distance = 1000.0  # Maximum hearing distance
	var volume_db = -5.0
	
	if distance > max_distance:
		print("Too far to hear (distance: ", distance, ")")
		return  # Too far to hear
	
	# Linear volume falloff based on distance
	if distance > 0:
		var volume_factor = 1.0 - (distance / max_distance)
		volume_db = linear_to_db(volume_factor) - 5.0
	
	print("Playing hello audio with volume: ", volume_db, " distance: ", distance)
	# Play the audio with calculated volume
	hello_audio.volume_db = volume_db
	hello_audio.play()
