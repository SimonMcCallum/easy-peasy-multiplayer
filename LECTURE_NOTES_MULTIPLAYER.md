# CGRA252 - Multiplayer Gaming Lecture Notes
**Dr Simon McCallum - Game Engine Programming**

---

## Table of Contents
1. [Why Multiplayer Games?](#why-multiplayer-games)
2. [Types of Multiplayer](#types-of-multiplayer)
3. [Building Communities](#building-communities)
4. [Networking Fundamentals](#networking-fundamentals)
5. [Game Networking Models](#game-networking-models)
6. [Godot Networking Implementation](#godot-networking-implementation)
7. [Practical Examples from Codebase](#practical-examples-from-codebase)
8. [Advanced Topics](#advanced-topics)

---

## Why Multiplayer Games?

### Competition Benefits
- **Balance**: Creating fair and challenging gameplay
- **Worthy Opponents**: Human unpredictability vs AI patterns
- **Interesting Problems**: Complex strategic decisions
- **Status**: Rankings, leaderboards, achievements
- **Complexity and Meaning**: Emergent gameplay from interactions

### Cooperation Benefits
- **Shared Experiences**: Creating memories together
- **Teamwork**: Being part of a winning team
- **Social Connection**: Meeting and interacting with others

### Modern Motivations
- **Esports Integration**: Streaming and competitive scenes
- **Metaverse/AR/VR**: Shared virtual spaces
- **Community Building**: Long-term player engagement

**Code Example from Repository:**
```gdscript
# From levels/main/main.gd - Player spawning for cooperative gameplay
func _on_player_connected(player_id: int, _player_info: Dictionary) -> void:
    if multiplayer.is_server() and not get_tree().current_scene.find_child("Player" + str(player_id)):
        player_spawner.spawn(player_id)  # Each player gets their own character
```

---

## Types of Multiplayer

### Local vs Remote
- **Local**: Same screen, split-screen, hot-seat
- **Remote**: Network-based, client-server, P2P

### Synchronous vs Asynchronous
- **Synchronous**: Real-time, simultaneous play
- **Asynchronous**: Turn-based, different time periods

### Cooperative vs Competitive
- **Cooperative**: Shared goals and objectives
- **Competitive**: Opposing goals
- **Team Games**: Mix of cooperation within teams, competition between teams

**Implementation Example:**
```gdscript
# From levels/slides/slides.gd - Synchronous lecture system
@rpc("authority", "call_local", "reliable")
func host_slide_changed(slide_number: int):
    if not is_host:
        host_slide = slide_number
        if is_following_host:
            goto_slide(slide_number)  # Synchronous slide updates
```

---

## Building Communities

### Community Features
1. **Membership**: Clear boundaries of who belongs
2. **Influence**: Members can affect the community
3. **Needs**: Community fulfills member needs
4. **Shared Emotional Connection**: Common experiences and history
5. **User Generated Content**: Web 2.0 principles

### Ways to Create Community

#### Communication Systems
- **Allow Talking**: Chat systems, voice communication
- **Finding People**: Matchmaking, friend systems
- **Conversation Starters**: Ice-breaker mechanics

**Code Example:**
```gdscript
# From addons/easy_peasy_multiplayer/networking/network.gd - Player connection tracking
signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)

# Building community through connection awareness
var connected_players = {}
```

#### Friendship Building
- **Breaking the Ice**: Tutorial co-op, shared challenges
- **Friending Systems**: Friend lists, player profiles
- **Staying Friends**: Guilds, persistent groups

#### Community Mechanics
- **Shared Enemy**: PvE content, common opponents
- **Geography/Architecture**: Persistent spaces, clubhouses
- **Shared Resources**: Guild banks, collective achievements
- **Express Personality**: Customization, uniforms, symbols

### Community Levels
1. **Newbie**: Learning the ropes, needs guidance
2. **The Player**: Active participant, core community
3. **The Elder**: Experienced leader, mentor role

### Creating Dependence and Events
- **Dependence**: Mechanics requiring cooperation (like Farmville gifting)
- **Community Support**: Foster small, tight-knit groups
- **Obligation**: Social contracts and commitments
- **Events**: Regular gatherings, competitions, social activities

**Example from Lecture System:**
```gdscript
# From levels/slides/slides.gd - Community through shared lecture experience
func _on_player_joined(peer_id, player_info):
    if is_host:
        print("New student joined lecture: %s (ID: %d)" % [player_info.get("name", "Unknown"), peer_id])
        # Send current slide to new player immediately - creates shared experience
        host_slide_changed.rpc_id(peer_id, current)
```

---

## Networking Fundamentals

### Networking Vocabulary
- **Sockets**: Combination of IP address and port
- **Packets**: How data is transmitted across networks
- **Headers**: Metadata describing packet contents
- **IP Address**: Protocol for identifying machines
- **Protocols**: Rules describing how systems interact
- **Firewalls**: Security systems blocking communication
- **NAT**: Network Address Translation for routing

### OSI Model vs Reality
The lecture notes mention "No network protocols fit this model" - networking is more practical than theoretical.

### Packet Structure
```
[IP Header][TCP/UDP Header][Application Data]
```

**Code Implementation:**
```gdscript
# From addons/easy_peasy_multiplayer/networking/network_enet.gd
const PORT = 25666  # Specific port for lecture system

func become_host(_lobby_type):
    var host_port = PORT
    print("Attempting to create server on port: %d" % host_port)
    var error = peer.create_server(host_port, Network.room_size)
    if error:
        print("Failed to create server. Error code: %d" % error)
        return error
```

---

## Game Networking Models

### Peer-to-Peer (P2P)
- **Direct Communication**: Players talk directly to each other
- **Discovery Challenge**: Finding other players' IP addresses
- **Firewall Issues**: NAT traversal and hole punching

#### P2P Discovery Scenarios
1. **Easy**: Both endpoints have public IP addresses
2. **Best**: Server has public IP, clients connect
3. **Difficult**: Server behind firewall

#### Hole Punching
- **Problem**: Firewalls block incoming connections
- **Solution**: Use known server to mediate initial connection
- **UDP NAT**: Creates IP/port translations for communication

### Client-Server Model
- **Centralized Hub**: All communication goes through server
- **Server Authority**: Server defines what is true
- **Scalability**: Handles many clients efficiently

**Repository Implementation:**
```gdscript
# From addons/easy_peasy_multiplayer/networking/network_enet.gd
func join_as_client():
    var ip = Network.ip_address
    var port = PORT
    
    # Check if the ip_address contains a port (e.g., "192.168.1.1:8080")
    if ":" in ip:
        var parts = ip.split(":")
        ip = parts[0]
        port = int(parts[1])
    
    var error = peer.create_client(ip, port)
    multiplayer.multiplayer_peer = peer
    Network.is_host = false
```

### Server Types
1. **Dedicated Server**: Separate machine running only server
2. **Listening Server**: One player also acts as server
3. **Migrating Server**: Server role can transfer between players

**Code Example - Listen Server:**
```gdscript
# From levels/start_screen/start_screen.gd
func _on_host_lecture_button_pressed():
    print("Starting lecture server...")
    Network.active_network_type = Network.MultiplayerNetworkType.ENET
    Network.ip_address = "0.0.0.0:25666"  # Listen on all interfaces
    Network.room_size = 20  # Allow up to 20 students
    Network.become_host()  # This player becomes the server
```

---

## Godot Networking Implementation

### Godot Networking Layers
1. **High-Level**: Scene tree synchronization
2. **Mid-Level**: MultiplayerPeer (not recommended for direct use)
3. **Low-Level**: PacketPeer (low-level networking)

### Key Networking Concepts
- **UDP Underneath**: Godot uses UDP with reliability layer
- **Server ID = 1**: Server always has peer ID 1
- **RPC System**: Remote Procedure Calls for communication
- **Authority System**: Who controls what objects

### Basic Networking Setup
```gdscript
# From the lecture notes and our implementation
var error = peer.create_server(PORT, MAX_CONNECTIONS)
# Connect to server - server ID = 1
# RPC call functions
# Know your ID and change execution based on ID
```

### Network Signals
```gdscript
# From addons/easy_peasy_multiplayer/networking/network.gd
signal server_started()
signal connection_fail()
signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)

# Usage in levels/start_screen/start_screen.gd
if not Network.server_started.is_connected(_on_lecture_server_started):
    Network.server_started.connect(_on_lecture_server_started)
```

### Player Loading Example
```gdscript
# From the lecture notes, adapted with our code structure
# Load my player
var my_player = preload("res://prefabs/player/player.tscn").instantiate()
my_player.set_name(str(selfPeerID))
my_player.set_multiplayer_authority(selfPeerID)  # The player belongs to this peer
get_node("/root/world/players").add_child(my_player)

# Load other players  
for p in player_info:
    var player = preload("res://prefabs/player/player.tscn").instantiate()
    player.set_name(str(p))
    player.set_multiplayer_authority(p)  # Each peer has authority over their own player
    get_node("/root/world/players").add_child(player)
```

---

## Practical Examples from Codebase

### RPC Implementation
Our lecture system demonstrates three key RPC patterns:

#### 1. Authority RPC (Host → All Clients)
```gdscript
# From levels/slides/slides.gd
@rpc("authority", "call_local", "reliable")
func host_slide_changed(slide_number: int):
    if not is_host:
        host_slide = slide_number
        if is_following_host:
            goto_slide(slide_number)  # Auto-follow instructor
```

#### 2. Any Peer RPC (Client → Host)
```gdscript
@rpc("any_peer", "call_remote", "reliable")
func player_slide_changed(slide_number: int):
    if is_host:
        var sender_id = multiplayer.get_remote_sender_id()
        player_slides[sender_id] = slide_number
        update_player_positions.rpc(player_slides)  # Broadcast to all
```

#### 3. Targeted RPC (Host → Specific Client)
```gdscript
@rpc("any_peer", "call_remote", "reliable")
func request_host_slide():
    if is_host:
        var sender_id = multiplayer.get_remote_sender_id()
        host_slide_changed.rpc_id(sender_id, current)  # Send only to requester
```

### Network State Management
```gdscript
# From levels/slides/slides.gd - Managing distributed state
var player_slides := {}  # Dictionary mapping peer_id to slide_number
var is_following_host := true
var host_slide := 0

func _handle_slide_change():
    if is_lecture_mode:
        if is_host:
            # Host broadcasts slide change to all clients
            host_slide = current
            host_slide_changed.rpc(current)
        else:
            # Client updates their position and notifies host
            is_following_host = (current == host_slide)
            player_slide_changed.rpc_id(1, current)
```

### Connection Management
```gdscript
# From levels/start_screen/start_screen.gd
func _on_connection_failed():
    print("Failed to connect to lecture server")
    var error_label = Label.new()
    error_label.text = "Failed to connect to lecture server"
    error_label.add_theme_color_override("font_color", Color.RED)
    add_child(error_label)
```

### Visual Feedback System
```gdscript
# From levels/slides/slides.gd - Community visualization
func _update_meeple_display():
    # Count players at each slide
    var slide_counts := {}
    for peer_id in player_slides:
        var slide_num = player_slides[peer_id]
        if not slide_counts.has(slide_num):
            slide_counts[slide_num] = 0
        slide_counts[slide_num] += 1
    
    # Create visual indicators showing community presence
    var current_slide_count = slide_counts.get(current, 0)
    for i in range(current_slide_count):
        var meeple = ColorRect.new()
        meeple.color = Color.CYAN if i == 0 and is_host else Color.WHITE
        meeple_container.add_child(meeple)
```

---

## Advanced Topics

### Game Theory in Multiplayer
- **Zero-Sum Games**: Winners and losers (competitive)
- **Nash Equilibrium**: Best local decision for each player
- **Dominant Strategies**: Single best option regardless of others
- **Bounded Rationality**: Limited information decision making
- **Uncertainty**: Dealing with incomplete information

### Griefing Prevention
Two main approaches:
1. **Police the Community**: Trust factors, reporting systems
2. **Remove Opportunities**: Design out griefable mechanics

#### Community Mechanics That Enable Griefing
- **PvP Systems**: Player vs player combat
- **Stealing**: Taking other players' items
- **P2P Trading**: Item exchange systems
- **Language Filters**: Chat moderation
- **Blocking**: Movement interference

#### Technical Solutions
```gdscript
# From our networking system - Authority prevents many griefing vectors
func become_host(_lobby_type):
    # Server has authority over game state
    Network.is_host = true
    multiplayer.multiplayer_peer = peer
    # Only server can spawn/despawn players, preventing griefing
```

### Synchronous vs Asynchronous Games

#### Synchronous Games
- **All players run local simulation**
- **Deterministic states**: Same inputs = same outputs
- **Problem**: Game pauses if one player hangs

```gdscript
# From levels/slides/slides.gd - Synchronous lecture system
func _handle_slide_change():
    if is_lecture_mode and is_host:
        host_slide_changed.rpc(current)  # All students get update simultaneously
```

#### Asynchronous Games
- **Updates occur at different times**
- **Local simulation ahead of server state**
- **Network prediction**: "Bending the world to fit"

### Optimizations

#### Minimizing Communication
```gdscript
# From our codebase - Only send updates when needed
func _handle_slide_change():
    if is_lecture_mode:
        if is_host:
            host_slide = current
            host_slide_changed.rpc(current)  # Only broadcast on actual change
```

#### Data Quantization
- **Cut off useless precision**: FVector_NetQuantize in Unreal
- **Relevance filtering**: Only send data players can see
- **Update frequency**: Adapt based on importance

#### Dormancy and Update Frequency
- **Dormancy**: Inactive agents don't update
- **Data-Driven Frequency**: Fixed update rates per object type
- **Adaptive Frequency**: Dynamic updates based on importance

### Cheating Prevention

#### Types of Cheating
1. **View Cheats**: Seeing information you shouldn't
   - **Solution**: Only send viewable data
2. **Local Value Changing**: Modifying client-side values
   - **Solution**: Server authority, validation
3. **Score Manipulation**: Fake achievements/progress
   - **Solution**: Server-side scoring, hashes

**Code Example - Server Authority:**
```gdscript
# From our networking system - Server validates all important state
func _on_player_connected(player_id: int, _player_info: Dictionary) -> void:
    if multiplayer.is_server():  # Only server can spawn players
        player_spawner.spawn(player_id)
```

### Seamless Travel
- **Loading new data from server**
- **State migration between areas**
- **Handover mechanics to avoid duplication**

---

## Libraries and Tools

### Why Use Libraries?
- **Networking is hard**: Complex protocols and edge cases
- **Don't reinvent the wheel**: Proven solutions exist
- **Benefits of reuse**:
  - Find the best tool for the job
  - Benefit from tutorials and documentation
  - Already tested and debugged

### Messaging Systems
- **Text-based networking**: JSON, XML protocols
- **Easy to customize**: Human-readable formats
- **Not optimal for games**: Higher latency, larger packets
- **Good for middleware**: Configuration, lobby systems

**Example from our system:**
```gdscript
# We use Godot's built-in RPC system which handles serialization
@rpc("authority", "call_local", "reliable")
func host_slide_changed(slide_number: int):  # Simple integer, efficient
```

### Data Structures: Queues
Game updates often use queue structures for:
- **Buffering network packets**
- **Handling out-of-order messages**
- **Smoothing network jitter**

---

## Comparison with Other Engines

### Unreal Engine Networking
- **Actor Replication**: Automatic state synchronization
- **Movement Replication**: Built-in position/rotation sync
- **Update Frequency Control**: NetUpdateFrequency settings
- **Dormancy**: Automatic optimization for inactive objects

### Unity Networking
- **New Networking System**: Explicit networked data definition
- **NetCode**: Data-oriented networking
- **Explicit Control**: Manual definition of what syncs

### Godot Advantages
- **Scene Tree Integration**: Natural fit with Godot's architecture
- **Built-in RPC System**: Easy remote procedure calls
- **MultiplayerSynchronizer**: Automatic variable synchronization
- **Free and Open Source**: No licensing costs

---

## Conclusion

This lecture covers the full spectrum of multiplayer game development, from social motivations to technical implementation. Our repository demonstrates these concepts with:

1. **Real-world networking code** showing client-server architecture
2. **RPC systems** for real-time communication
3. **Community building** through shared lecture experiences
4. **Error handling** and robust networking practices
5. **Export-ready deployment** for production use

The key takeaway is that multiplayer games are fundamentally about **connecting people** - whether for competition, cooperation, or learning. The technical networking is just the foundation that enables these human connections.

**Next Steps for Students:**
1. Study the [NETWORKING_DOCUMENTATION.md](NETWORKING_DOCUMENTATION.md) for detailed technical analysis
2. Experiment with the lecture system to understand RPC patterns
3. Modify the code to implement your own multiplayer features
4. Consider the social aspects - how does your networking design affect player behavior and community building?

---

*These notes are based on Dr. Simon McCallum's CGRA252 lecture on Multiplayer Gaming, with practical examples from the Easy Peasy Multiplayer educational extension.*
