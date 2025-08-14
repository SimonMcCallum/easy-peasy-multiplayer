extends CharacterBody2D


const SPEED = 500.0
const ACCELERATION = 45.0
const JUMP_VELOCITY = -900.0

@onready var nametag: Label = %Nametag
@onready var player_camera: Camera2D = %PlayerCamera
@onready var hello_audio: AudioStreamPlayer2D = %HelloAudio

# Audio mute control
var audio_muted = false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int(), true)
	add_to_group("Players")

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

	# Handle audio mute toggle
	if Input.is_action_just_pressed("ui_select"):  # Spacebar to mute/unmute
		audio_muted = !audio_muted
		print("Audio muted: ", audio_muted)

	# Handle hello audio input
	if Input.is_action_just_pressed("hello"):
		print("H key pressed! Playing hello audio...")
		if multiplayer.has_multiplayer_peer():
			play_hello_audio_at_source.rpc()
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
func play_hello_audio_at_source():
	var sender_id = multiplayer.get_remote_sender_id()
	var receiver_name = nametag.text
	var receiver_id = name.to_int()
	var player_identifier = receiver_name + " (ID: " + str(receiver_id) + ")"
	
	# Debug: Print that this player received the request
	print("DEBUG: Player '", player_identifier, "' received audio request from sender ID: ", sender_id)
	
	# Find the source player who sent the audio request
	var source_player = null
	var source_player_id = sender_id
	
	if sender_id == 0:  # Local call (call_local)
		source_player = self
		source_player_id = receiver_id
		print("DEBUG: Local RPC call - source is self")
	else:
		# Find the sender player in the scene
		for player in get_tree().get_nodes_in_group("Players"):
			if player.name.to_int() == sender_id:
				source_player = player
				break
		print("DEBUG: Remote RPC call from player ID: ", sender_id)
	
	if source_player == null:
		print("DEBUG: Source player not found!")
		return
	
	# Calculate and print distance between receiving player and source player
	var distance = global_position.distance_to(source_player.global_position)
	print("DEBUG: Distance between receiver '", player_identifier, "' and source (ID: ", source_player_id, "): ", distance, " pixels")
	print("DEBUG: Source position: ", source_player.global_position, ", Receiver position: ", global_position)
	
	# Check if audio is muted for this player
	if audio_muted:
		print("DEBUG: Audio muted for player '", player_identifier, "' - not playing sound")
		return
	
	# Only the source player actually plays the audio - others just receive debug info
	if source_player == self:
		print("DEBUG: Playing hello audio from source player '", player_identifier, "'")
		hello_audio.play()
	else:
		print("DEBUG: Player '", player_identifier, "' will hear audio from source player at distance ", distance, " pixels")
