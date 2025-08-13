extends Control

func _ready():
	print("Start screen loaded")
	print("Project path: %s" % ProjectSettings.globalize_path("res://"))
	print("Executable path: %s" % OS.get_executable_path())
	
	# Test if key scenes exist
	if ResourceLoader.exists("res://levels/slides/slides.tscn"):
		print("✓ Slides scene found")
	else:
		print("✗ Slides scene NOT found - export issue!")
		
	if ResourceLoader.exists("res://levels/main/main.tscn"):
		print("✓ Main scene found") 
	else:
		print("✗ Main scene NOT found - export issue!")

func _on_lecture_button_pressed():
	print("Joining lecture mode...")
	# Set up networking for lecture mode
	Network.active_network_type = Network.MultiplayerNetworkType.ENET
	Network.ip_address = "103.224.130.189:25666"
	
	# Connect to network signals if not already connected
	if not Network.connection_fail.is_connected(_on_connection_failed):
		Network.connection_fail.connect(_on_connection_failed)
	if not Network.player_connected.is_connected(_on_connected_to_lecture):
		Network.player_connected.connect(_on_connected_to_lecture)
	
	# Try to connect to the lecture server
	Network.join_as_client()

func _on_host_lecture_button_pressed():
	print("Starting lecture server...")
	# Set up networking for hosting lecture using the same system as multiplayer
	Network.active_network_type = Network.MultiplayerNetworkType.ENET
	# Set the IP address with port 25666 so the server knows which port to host on
	Network.ip_address = "0.0.0.0:25666"
	Network.room_size = 20  # Allow up to 20 students in lecture
	
	# Connect to network signals if not already connected
	if not Network.server_started.is_connected(_on_lecture_server_started):
		Network.server_started.connect(_on_lecture_server_started)
	if not Network.player_connected.is_connected(_on_lecture_player_connected):
		Network.player_connected.connect(_on_lecture_player_connected)
	
	# Host the lecture server on port 25666 - same as multiplayer game hosting
	Network.become_host()

func _on_lecture_server_started():
	print("Lecture server started! Loading slides as host...")
	print("Students can connect to this lecture server")
	# Load the slides scene - it will auto-detect lecture mode
	var result = get_tree().change_scene_to_file("res://levels/slides/slides.tscn")
	if result != OK:
		print("ERROR: Failed to load slides scene. Error code: %d" % result)
		print("Make sure slides.tscn is included in the export")

func _on_lecture_player_connected(peer_id: int, player_info: Dictionary):
	print("Student connected to lecture: %s (ID: %d)" % [player_info.get("name", "Unknown"), peer_id])
	# The slides scene will handle sending the current slide position to new students

func _on_multiplayer_button_pressed():
	print("Loading multiplayer game...")
	# Load the main multiplayer scene
	var result = get_tree().change_scene_to_file("res://levels/main/main.tscn")
	if result != OK:
		print("ERROR: Failed to load main scene. Error code: %d" % result)
		print("Make sure main.tscn is included in the export")

func _on_connected_to_lecture(peer_id, player_info):
	print("Connected to lecture server! Loading slides...")
	# Load the slides scene - it will auto-detect lecture mode
	var result = get_tree().change_scene_to_file("res://levels/slides/slides.tscn")
	if result != OK:
		print("ERROR: Failed to load slides scene. Error code: %d" % result)
		print("Make sure slides.tscn is included in the export")

func _on_connection_failed():
	print("Failed to connect to lecture server")
	# Could show an error dialog here
	var error_label = Label.new()
	error_label.text = "Failed to connect to lecture server"
	error_label.add_theme_color_override("font_color", Color.RED)
	add_child(error_label)
	
	# Remove the error message after 3 seconds
	await get_tree().create_timer(3.0).timeout
	error_label.queue_free()
