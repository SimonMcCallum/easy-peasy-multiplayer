# Networking System Documentation

## Overview

This Godot project demonstrates a comprehensive multiplayer networking system using **ENet** (Reliable UDP) networking. The system supports both multiplayer gaming and lecture presentation modes, showcasing how to implement real-time synchronization between multiple clients.

## Architecture

### Network Types

The system supports three network types defined in [`addons/easy_peasy_multiplayer/networking/network.gd`](addons/easy_peasy_multiplayer/networking/network.gd):

```gdscript
enum MultiplayerNetworkType { DISABLED, ENET, STEAM }
```

- **DISABLED**: No networking
- **ENET**: TCP-like reliability over UDP (primary method)
- **STEAM**: Steam networking (fallback if Steam unavailable)

### Core Network Components

#### 1. Network Manager
**File**: [`addons/easy_peasy_multiplayer/networking/network.gd`](addons/easy_peasy_multiplayer/networking/network.gd)

The central hub that manages all networking operations:

```gdscript
# Key variables
var active_network_type : MultiplayerNetworkType = MultiplayerNetworkType.DISABLED
var active_network : Node  # The actual network implementation
var connected_players = {}  # Dictionary of all connected players
var room_size: int = 4      # Maximum players (can be increased for lectures)
```

**Key Functions**:
- `become_host()` - Start hosting a server
- `join_as_client()` - Connect to existing server
- `disconnect_from_server()` - Leave current session

#### 2. ENet Implementation
**File**: [`addons/easy_peasy_multiplayer/networking/network_enet.gd`](addons/easy_peasy_multiplayer/networking/network_enet.gd)

Handles the actual ENet networking:

```gdscript
var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
```

**Host Creation**:
```gdscript
func become_host(_lobby_type):
    var host_port = PORT  # Default 7000, or custom port from Network.ip_address
    var error = peer.create_server(host_port, Network.room_size)
    multiplayer.multiplayer_peer = peer
    Network.is_host = true
```

**Client Connection**:
```gdscript
func join_as_client():
    var ip = Network.ip_address.split(":")[0]  # Extract IP
    var port = int(Network.ip_address.split(":")[1])  # Extract port
    var error = peer.create_client(ip, port)
    multiplayer.multiplayer_peer = peer
```

## How Multiplayer Gaming Works

### 1. Starting a Game Server
**File**: [`prefabs/ui/network_ui/network_ui.gd`](prefabs/ui/network_ui/network_ui.gd)

When a player clicks "Host Game":
1. Sets `Network.active_network_type = MultiplayerNetworkType.ENET`
2. Calls `Network.become_host()`
3. Creates ENet server on port 7000
4. Spawns player characters via [`levels/main/main.gd`](levels/main/main.gd)

### 2. Player Spawning System
**File**: [`levels/main/main.gd`](levels/main/main.gd)

```gdscript
func _on_player_connected(player_id: int, _player_info: Dictionary) -> void:
    if multiplayer.is_server() and not get_tree().current_scene.find_child("Player" + str(player_id)):
        player_spawner.spawn(player_id)
```

Each connected player gets a unique character spawned at the designated spawn point.

### 3. Real-time Synchronization

Players are automatically synchronized using Godot's built-in multiplayer system:
- **Position updates**: Sent automatically via `MultiplayerSynchronizer`
- **Input handling**: Each client controls their own player
- **Authority**: Server has authority over spawning/despawning

## How Lecture Mode Works

### 1. Starting a Lecture Server
**File**: [`levels/start_screen/start_screen.gd`](levels/start_screen/start_screen.gd)

When instructor clicks "Host Lecture":

```gdscript
func _on_host_lecture_button_pressed():
    Network.active_network_type = Network.MultiplayerNetworkType.ENET
    Network.ip_address = "0.0.0.0:25666"  # Custom port for lectures
    Network.room_size = 20  # Allow up to 20 students
    Network.become_host()
```

### 2. Student Connection
**File**: [`levels/start_screen/start_screen.gd`](levels/start_screen/start_screen.gd)

When student clicks "Join Lecture":
```gdscript
func _on_lecture_button_pressed():
    Network.active_network_type = Network.MultiplayerNetworkType.ENET
    Network.ip_address = "103.224.130.189:25666"  # Instructor's server
    Network.join_as_client()
```

### 3. Slide Synchronization System
**File**: [`levels/slides/slides.gd`](levels/slides/slides.gd)

#### Host (Instructor) Responsibilities:
```gdscript
func _handle_slide_change():
    if is_lecture_mode and is_host:
        host_slide = current
        host_slide_changed.rpc(current)  # Broadcast to all students
```

#### Client (Student) Responsibilities:
```gdscript
@rpc("authority", "call_local", "reliable")
func host_slide_changed(slide_number: int):
    if not is_host:
        host_slide = slide_number
        if is_following_host:
            goto_slide(slide_number)  # Auto-follow instructor
```

#### Student Position Reporting:
```gdscript
func _handle_slide_change():
    if is_lecture_mode and not is_host:
        is_following_host = (current == host_slide)
        follow_button.visible = not is_following_host
        player_slide_changed.rpc_id(1, current)  # Tell instructor our position
```

## Remote Procedure Calls (RPCs)

### What are RPCs?

RPCs allow you to call functions on remote machines. In this system:

- **Host → All Clients**: Broadcast slide changes
- **Client → Host**: Report individual positions
- **Host → Specific Client**: Send initial state to new joiners

### RPC Decorators Explained

```gdscript
@rpc("authority", "call_local", "reliable")
```

- **authority**: Only the server can call this RPC
- **call_local**: Also call the function locally (on sender)
- **reliable**: Guarantee delivery (use UDP with acknowledgment)

```gdscript
@rpc("any_peer", "call_remote", "reliable")
```

- **any_peer**: Any connected peer can call this RPC
- **call_remote**: Only call on remote machines (not sender)
- **reliable**: Guarantee delivery

### Example RPC Flow

1. **Instructor changes slide** (slides.gd:88)
   ```gdscript
   host_slide_changed.rpc(current)
   ```

2. **All students receive update** (slides.gd:158)
   ```gdscript
   func host_slide_changed(slide_number: int):
       if is_following_host:
           goto_slide(slide_number)
   ```

3. **Student reports their position** (slides.gd:104)
   ```gdscript
   player_slide_changed.rpc_id(1, current)
   ```

## Visual Feedback System

### Meeple Indicators
**File**: [`levels/slides/slides.gd`](levels/slides/slides.gd) (lines 184-210)

Shows how many students are viewing each slide:

```gdscript
func _update_meeple_display():
    # Count players at each slide
    var slide_counts := {}
    for peer_id in player_slides:
        var slide_num = player_slides[peer_id]
        slide_counts[slide_num] += 1
    
    # Create visual indicators
    for i in range(current_slide_count):
        var meeple = ColorRect.new()
        meeple.color = Color.CYAN if is_host else Color.WHITE
```

## Error Handling & Fallbacks

### Steam Initialization
**File**: [`addons/easy_peasy_multiplayer/steam_info.gd`](addons/easy_peasy_multiplayer/steam_info.gd)

If Steam fails to initialize:
```gdscript
func initialize_steam() -> bool:
    if initialize_response['status'] > 0:
        print("Steam features will be disabled. You can still use ENet networking.")
        return false
```

The system gracefully falls back to ENet networking.

### Connection Failures
**File**: [`levels/start_screen/start_screen.gd`](levels/start_screen/start_screen.gd)

```gdscript
func _on_connection_failed():
    print("Failed to connect to lecture server")
    # Show error message to user
```

## Port Configuration

- **Multiplayer Game**: Port 7000 (default ENet port)
- **Lecture Mode**: Port 25666 (custom port for lectures)

This separation allows:
- Multiple servers running simultaneously
- Different firewall configurations
- Clear distinction between game/lecture traffic

## Key Learning Points for Students

### 1. Client-Server Architecture
- **Server Authority**: The server (host) has final say over game state
- **Client Prediction**: Clients can act immediately but server confirms
- **State Synchronization**: All clients must stay in sync with server

### 2. Network Protocols
- **TCP vs UDP**: TCP is reliable but slow, UDP is fast but unreliable
- **ENet**: Combines UDP speed with TCP reliability
- **Port Management**: Different services use different ports

### 3. Real-time Systems
- **Event-driven**: React to network events (player joined, slide changed)
- **State management**: Track who's where and what they're doing
- **Graceful degradation**: Handle disconnections and errors

### 4. User Experience
- **Visual feedback**: Show connection status and other players
- **Error handling**: Inform users when things go wrong
- **Responsive design**: Adapt UI to different screen sizes

## Testing the System

### Local Testing
1. Run project
2. Click "Host Lecture" on one instance
3. Run second instance
4. Click "Join Lecture" 
5. Test slide synchronization with arrow keys

### Network Testing
1. Host on one machine (note IP address)
2. Update `ip_address` in start_screen.gd to host's IP
3. Connect from other machines on same network

## Advanced Features

### Position Persistence
**File**: [`levels/slides/slides.gd`](levels/slides/slides.gd) (lines 36-39)

```gdscript
# Restore slide position if returning from game
if stored_slide_position > 0:
    current = stored_slide_position
```

Students can switch between game and lecture modes without losing their place.

### Follow Mode
**File**: [`levels/slides/slides.gd`](levels/slides/slides.gd) (lines 99-105)

Students can:
- Auto-follow instructor slides
- Navigate independently
- Return to following with "Follow Host" button

This demonstrates **loose coupling** - students maintain autonomy while staying connected to the instructor.

## Export Compatibility & Deployment

### Export-Compatible Slide Loading
**File**: [`levels/slides/slides.gd`](levels/slides/slides.gd) (lines 42-63)

The system uses resource-based loading instead of file system access for exported builds:

```gdscript
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
        break  # No more slides found
    
    slides.append(slide_resource)
    slide_index += 1
```

**Key Benefits**:
- Works in both development and exported builds
- Uses Godot's resource system (.pck files)
- Supports flexible naming conventions
- Maintains numerical ordering automatically

### Enhanced Error Handling & Debugging
**File**: [`levels/start_screen/start_screen.gd`](levels/start_screen/start_screen.gd) (lines 3-17)

The system includes comprehensive diagnostics for exported builds:

```gdscript
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
```

### Network Server Diagnostics
**File**: [`addons/easy_peasy_multiplayer/networking/network_enet.gd`](addons/easy_peasy_multiplayer/networking/network_enet.gd) (lines 15-29)

Enhanced server creation with detailed logging:

```gdscript
func become_host(_lobby_type):
    print("Attempting to create server on port: %d" % host_port)
    var error = peer.create_server(host_port, Network.room_size)
    if error:
        print("Failed to create server. Error code: %d" % error)
        print("This might be due to port %d being in use or blocked" % host_port)
        return error
    
    print("ENet Server successfully hosted on port %d" % host_port)
    print("Server is ready for connections")
```

## Export Configuration Guide

### Godot Export Settings

1. **Project → Export → Add → Windows Desktop**
2. **Resources Tab**:
   - Set Export Mode to "Export all resources in the project"
   - Ensure all .tscn, .gd, and .png files are included
3. **Features Tab**:
   - Enable "Export With Debug" for initial testing
   - Use .exe + .pck format for easier debugging

### Common Export Issues & Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Scene Loading Failure** | Cannot move beyond main menu | Check console for "✗ Scene NOT found" messages. Verify .tscn files in export. |
| **Network Hosting Failure** | Can join but not host lectures | Check port 25666 isn't blocked by firewall. Run as Administrator. |
| **Resource Loading Failure** | Slides don't display | Verify .png files and .import files are included in export. |
| **Working Directory Issues** | Only works in project folder | Ensure "Export all resources" is enabled, not relying on external files. |

### Debugging Exported Builds

1. **Run from Command Line**: 
   ```bash
   your_exported_game.exe
   ```
   View console output for detailed error messages.

2. **Check for Common Errors**:
   - `✗ Slides scene NOT found - export issue!`
   - `Failed to create server. Error code: X`
   - `ERROR: Failed to load X scene. Error code: Y`

3. **Network Testing**:
   - Temporarily disable Windows Firewall
   - Test locally first (same machine, different folder)
   - Check if port 25666 is available

### Deployment Checklist

- [ ] Export with "Export all resources in the project"
- [ ] Include debug information in test builds
- [ ] Test executable in clean folder (no project files)
- [ ] Verify all scene files load correctly
- [ ] Test network functionality (hosting and joining)
- [ ] Check firewall settings for port 25666
- [ ] Ensure no dependency on external files

---

## Summary

This networking system demonstrates professional-grade multiplayer architecture suitable for both gaming and educational applications. Key concepts include:

- **Modular design**: Separate network types and implementations  
- **Real-time synchronization**: RPCs and state management
- **Export compatibility**: Resource-based loading for deployed builds
- **Comprehensive diagnostics**: Error handling and debugging features
- **User experience**: Visual feedback and graceful error handling
- **Scalability**: Support for multiple users and different use cases

The code serves as an excellent example of how to implement robust multiplayer systems in Godot, suitable for both game development and educational software, with production-ready export compatibility and comprehensive debugging features for deployment troubleshooting.
