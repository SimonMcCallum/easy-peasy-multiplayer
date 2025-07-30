# Easy Peasy Multiplayer - Extended for Education
### Multiplayer in Godot with Real-time Lecture System

This project is built upon the excellent [Easy Peasy Multiplayer](https://github.com/Skeats/easy-peasy-multiplayer) plugin by Skeats, extending it with a comprehensive lecture presentation system for educational use. The original plugin provides all the backend tools needed to quickly start making networked games in Godot, and we've added a real-time synchronized lecture system that demonstrates advanced multiplayer networking concepts.

## 🎓 Educational Extensions Added

This version includes significant additions for **2nd year game development students** to learn multiplayer networking:

### **Lecture System Features**
- **Real-time Slide Synchronization**: Instructor controls slides, students follow automatically
- **Independent Navigation**: Students can explore slides independently and return to following
- **Visual Student Tracking**: Instructors see which slides students are viewing
- **Export-Compatible**: Works in both development and exported builds
- **Comprehensive Documentation**: Detailed networking system explanation

### **Key Learning Components**
- **Client-Server Architecture**: Host authority and client synchronization
- **Remote Procedure Calls (RPCs)**: Real-time communication between instructor and students
- **State Management**: Tracking player positions and slide states
- **Error Handling**: Robust connection management and graceful failures
- **Export Deployment**: Production-ready build configuration

## 🚀 How to Use the Lecture System

### **For Instructors (Hosting a Lecture)**
1. Launch the application
2. Click **"Host Lecture"** on the main menu
3. The system will:
   - Start an ENet server on port 25666
   - Load the slide presentation (dark theme)
   - Allow up to 20 students to connect
4. Use **arrow keys** or **Enter/Space** to navigate slides
5. Students will automatically follow your presentation
6. See visual indicators showing which slides students are viewing

### **For Students (Joining a Lecture)**
1. Launch the application  
2. Click **"Join Lecture"** on the main menu
3. The system will:
   - Connect to the instructor's server
   - Load the slide presentation (synchronized with instructor)
   - Enable "Follow Mode" by default
4. **Navigation Options**:
   - **Auto-follow**: Stay synchronized with instructor's slides
   - **Independent**: Use arrow keys to explore on your own
   - **Return to following**: Click "Follow Host" button to re-sync

### **Controls**
- **Right Arrow / Enter / Space**: Next slide
- **Left Arrow**: Previous slide
- **Follow Host Button**: Return to instructor's current slide
- **Back Button**: Return to main menu

## 🎮 Original Multiplayer Game Features

The original Easy Peasy Multiplayer functionality is fully preserved:

- **ENet/IP Networking**: Traditional server-client multiplayer
- **Steam Networking**: Integration with Steam multiplayer features
- **Easy Network Switching**: Toggle between network types seamlessly
- **Lobby Management**: Create and join game sessions
- **Player Spawning**: Automatic player character management

## 📚 Learning Resources

### **Comprehensive Documentation**
👉 **[Networking System Documentation](NETWORKING_DOCUMENTATION.md)** - Detailed explanation of the networking architecture, RPC systems, and deployment guide specifically written for 2nd year game development students.

### **Topics Covered**
- Client-Server vs Peer-to-Peer architecture
- TCP vs UDP protocols and ENet hybrid approach
- Remote Procedure Calls (RPCs) implementation
- Real-time state synchronization
- Export compatibility and deployment
- Error handling and debugging
- Professional networking practices

## 🛠 Technical Implementation

### **Network Architecture**
- **ENet Protocol**: Reliable UDP for fast, guaranteed delivery
- **Port Separation**: Games use port 7000, lectures use port 25666
- **Authority Model**: Server (host) has authority over game state
- **RPC Communication**: Efficient real-time updates between clients

### **Export Compatibility**
- **Resource-based Loading**: Works in both development and exported builds
- **Diagnostic Systems**: Comprehensive error reporting for deployment issues
- **Production Ready**: Includes deployment guides and troubleshooting

### **Lecture System RPCs**
```gdscript
@rpc("authority", "call_local", "reliable")
func host_slide_changed(slide_number: int)  # Instructor → Students

@rpc("any_peer", "call_remote", "reliable") 
func player_slide_changed(slide_number: int)  # Student → Instructor

@rpc("any_peer", "call_remote", "reliable")
func request_host_slide()  # New student → Instructor
```

## 📋 Requirements

### **Dependencies (Included)**
- [GodotSteam](https://godotengine.org/asset-library/asset/2445) ✅ Included
- [SteamMultiplayerPeer](https://godotengine.org/asset-library/asset/2258) ✅ Included

### **System Requirements**
- **Godot Engine 4.4+**
- **Windows/Linux/macOS** (tested on Windows)
- **Network Access** for multiplayer features
- **Port 25666** open for lecture hosting (configurable)

## 🚀 Getting Started

### **Development Setup**
1. Clone this repository
2. Open in Godot Engine 4.4+
3. Enable "Easy Peasy Multiplayer" plugin in Project Settings
4. Run the project and test locally

### **Hosting a Lecture**
1. Click "Host Lecture" 
2. Share your IP address with students
3. Students click "Join Lecture"
4. Use arrow keys to present slides

### **Export for Distribution**
1. Go to **Project → Export**
2. Select **Windows Desktop** preset
3. **Resources Tab**: Set to "Export all resources in the project"
4. **Features Tab**: Enable "Export With Debug" for testing
5. Export and distribute to students

## 🔧 Troubleshooting

### **Common Issues**
- **Can't host lecture**: Check Windows Firewall for port 25666
- **Students can't connect**: Verify instructor's IP address
- **Exported build fails**: See [Networking Documentation](NETWORKING_DOCUMENTATION.md) export guide

### **Debug Information**
Run exported builds from command line to see detailed error messages:
```bash
your_exported_game.exe
```

## 📖 Original Plugin Information

This project extends the **Easy Peasy Multiplayer** plugin:
- **Original Author**: [Skeats](https://github.com/Skeats)
- **Original Repository**: [easy-peasy-multiplayer](https://github.com/Skeats/easy-peasy-multiplayer)
- **License**: Original plugin licensing preserved

### **Original Features Maintained**
- All original multiplayer game functionality
- Steam networking integration
- ENet networking support
- Lobby creation and management
- Player spawning systems

## 🏫 Educational Use

This extended version is specifically designed for:
- **CGRA252**: Computer Graphics and Game Development
- **2nd Year Students**: Learning multiplayer networking concepts
- **Victoria University of Wellington**: Game development curriculum
- **Real-world Skills**: Production deployment and networking

## 📝 Additional Resources

- **[Original Plugin Wiki](https://github.com/Skeats/easy-peasy-multiplayer/wiki/Getting-Started)**: Getting started with the base plugin
- **[High Level Multiplayer | Godot](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)**: Official Godot networking documentation
- **[Remote Procedure Calls/RPCs | Godot](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls)**: Understanding RPCs
- **[Getting Started | GodotSteam](https://godotsteam.com/getting_started/introduction/)**: Steam integration guide

---

## 🤝 Contributing

This educational extension maintains compatibility with the original Easy Peasy Multiplayer plugin while adding comprehensive lecture system functionality. Contributions that enhance the educational value or improve the networking demonstrations are welcome.

**Original Plugin**: [Easy Peasy Multiplayer by Skeats](https://github.com/Skeats/easy-peasy-multiplayer)  
**Educational Extensions**: Added for CGRA252 coursework at Victoria University of Wellington
