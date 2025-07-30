extends Control

@export var dark_path: String = "res://images/Slides/dark"
@export var light_path: String = "res://images/Slides/light"

@onready var slide_rect: TextureRect = $SlideRect
@onready var follow_button: Button = $UI/TopPanel/FollowButton
@onready var back_button: Button = $UI/TopPanel/BackButton
@onready var meeple_container: HBoxContainer = $UI/BottomPanel/MeepleContainer

var slides: Array[Texture2D] = []
var current := 0
var is_lecture_mode := false
var is_host := false
var is_following_host := true
var host_slide := 0
var player_slides := {} # Dictionary mapping peer_id to slide_number
var stored_slide_position := 0 # Store position when switching between game and slides

func _ready() -> void:
	# Check if we should be in lecture mode based on network state
	if multiplayer.get_unique_id() == 1 or Network.active_network_type == Network.MultiplayerNetworkType.ENET:
		is_lecture_mode = true
		is_host = multiplayer.get_unique_id() == 1
		print("Auto-detected lecture mode - Host: %s" % is_host)
	
	# Set up UI based on host status
	if is_host:
		follow_button.visible = false
	else:
		# Connect to host slide changes
		if not Network.player_connected.is_connected(_on_player_joined):
			Network.player_connected.connect(_on_player_joined)
	
	# Restore slide position if returning from game
	if stored_slide_position > 0:
		current = stored_slide_position
		print("Restored slide position: %d" % current)
	
	# Load slides based on whether this is lecture mode or multiplayer
	var folder := dark_path if is_lecture_mode or multiplayer.get_unique_id() == 1 else light_path
	
	# For exported builds, we need to load slides by trying sequential numbers
	# since DirAccess doesn't work with packed resources
	var slide_index = 0
	while true:
		var slide_path = "%s/slides-%d.png" % [folder, slide_index]
		var slide_resource = load(slide_path)
		if slide_resource == null:
			# Try alternative naming (slide-X.png)
			slide_path = "%s/slide-%d.png" % [folder, slide_index]
			slide_resource = load(slide_path)
		
		if slide_resource == null:
			# No more slides found
			break
		
		slides.append(slide_resource)
		slide_index += 1
		
		# Safety limit to prevent infinite loops
		if slide_index > 100:
			break
	
	if slides.size() > 0:
		slide_rect.texture = slides[current]
		print("Loaded %d slides in %s mode" % [slides.size(), "lecture" if is_lecture_mode else "multiplayer"])
		
		# If joining as client, request current host slide
		if is_lecture_mode and not is_host:
			request_host_slide.rpc_id(1)

func _input(event: InputEvent) -> void:
	if slides.size() == 0:
		return
		
	# Arrow key navigation for moving through slides
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		next_slide()
	elif event.is_action_pressed("ui_left"):
		previous_slide()

func next_slide():
	if slides.size() > 0:
		current = (current + 1) % slides.size()
		slide_rect.texture = slides[current]
		print("Slide %d/%d" % [current + 1, slides.size()])
		_handle_slide_change()

func previous_slide():
	if slides.size() > 0:
		current = (current - 1) % slides.size()
		slide_rect.texture = slides[current]
		print("Slide %d/%d" % [current + 1, slides.size()])
		_handle_slide_change()

func _handle_slide_change():
	if is_lecture_mode:
		if is_host:
			# Host broadcasts slide change to all clients
			host_slide = current
			host_slide_changed.rpc(current)
		else:
			# Client updates their position and notifies host
			is_following_host = (current == host_slide)
			follow_button.visible = not is_following_host
			player_slide_changed.rpc_id(1, current)

func set_lecture_mode(lecture_mode: bool):
	is_lecture_mode = lecture_mode

func goto_slide(slide_number: int):
	if slide_number >= 0 and slide_number < slides.size():
		current = slide_number
		slide_rect.texture = slides[current]
		print("Moved to slide %d/%d" % [current + 1, slides.size()])

# Button callbacks
func _on_follow_button_pressed():
	is_following_host = true
	follow_button.visible = false
	goto_slide(host_slide)
	# Notify host of position change
	if not is_host:
		player_slide_changed.rpc_id(1, current)

func _on_back_button_pressed():
	stored_slide_position = current
	print("Storing slide position: %d" % stored_slide_position)
	get_tree().change_scene_to_file("res://levels/main/main.tscn")

func _on_player_joined(peer_id, player_info):
	if is_host:
		print("New student joined lecture: %s (ID: %d)" % [player_info.get("name", "Unknown"), peer_id])
		# Send current slide to new player immediately
		host_slide_changed.rpc_id(peer_id, current)
		# Initialize their position tracking
		player_slides[peer_id] = current
		# Update meeple display to show the new student
		_update_meeple_display()
		print("Sent current slide position (%d) to new student" % (current + 1))

# RPC functions for host-client communication
@rpc("authority", "call_local", "reliable")
func host_slide_changed(slide_number: int):
	if not is_host:
		host_slide = slide_number
		if is_following_host:
			goto_slide(slide_number)
			follow_button.visible = false
		else:
			follow_button.visible = true
	_update_meeple_display()

@rpc("any_peer", "call_remote", "reliable")
func player_slide_changed(slide_number: int):
	if is_host:
		var sender_id = multiplayer.get_remote_sender_id()
		player_slides[sender_id] = slide_number
		# Broadcast updated positions to all clients
		update_player_positions.rpc(player_slides)

@rpc("any_peer", "call_remote", "reliable")
func request_host_slide():
	if is_host:
		var sender_id = multiplayer.get_remote_sender_id()
		host_slide_changed.rpc_id(sender_id, current)
		player_slides[sender_id] = current

@rpc("authority", "call_local", "reliable")
func update_player_positions(positions: Dictionary):
	player_slides = positions
	_update_meeple_display()

func _update_meeple_display():
	# Clear existing meeples
	for child in meeple_container.get_children():
		child.queue_free()
	
	if not is_lecture_mode:
		return
	
	# Count players at each slide
	var slide_counts := {}
	for peer_id in player_slides:
		var slide_num = player_slides[peer_id]
		if not slide_counts.has(slide_num):
			slide_counts[slide_num] = 0
		slide_counts[slide_num] += 1
	
	# Add host to current slide count
	if is_host:
		if not slide_counts.has(current):
			slide_counts[current] = 0
		slide_counts[current] += 1
	
	# Create meeple indicators for current slide
	var current_slide_count = slide_counts.get(current, 0)
	for i in range(current_slide_count):
		var meeple = ColorRect.new()
		meeple.size = Vector2(20, 30)
		meeple.color = Color.CYAN if i == 0 and is_host else Color.WHITE
		meeple_container.add_child(meeple)
	
	# Add slide number indicator
	if current_slide_count > 0:
		var label = Label.new()
		label.text = "Slide %d: %d viewers" % [current + 1, current_slide_count]
		label.add_theme_color_override("font_color", Color.WHITE)
		meeple_container.add_child(label)

func _extract_slide_number(filename: String) -> int:
	# Extract number from filenames like "slides-1.png", "slides-10.png", etc.
	var regex = RegEx.new()
	regex.compile(r"slides?-(\d+)\.png")
	var result = regex.search(filename)
	if result:
		return result.get_string(1).to_int()
	else:
		# Fallback: try to extract any number from the filename
		regex.compile(r"(\d+)")
		result = regex.search(filename)
		if result:
			return result.get_string(1).to_int()
		else:
			return 0

func connect_to_lecture_server():
	# Set network to ENet and connect to the lecture server
	Network.active_network_type = Network.MultiplayerNetworkType.ENET
	Network.ip_address = "103.224.130.189:25666"
	print("Connecting to lecture server at %s..." % Network.ip_address)
	Network.join_as_client()
