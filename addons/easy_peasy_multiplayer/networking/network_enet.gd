class_name NetworkEnet
extends Node

## The port number to use for Enet servers
const PORT = 25666

## The [MultiplayerPeer] for the Enet server. We can define this on initialization because this script should only run if we are going to be networking using ENet
var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

#region Network-Specific Functions
## Creates a game server as the host. See [Network.become_host] for more information
func become_host(_lobby_type):
	var host_port = PORT
	
	# Check if a custom port is specified in the ip_address for hosting
	if ":" in Network.ip_address:
		var parts = Network.ip_address.split(":")
		if parts.size() > 1:
			host_port = int(parts[1])
	
	print("Attempting to create server on port: %d" % host_port)
	var error = peer.create_server(host_port, Network.room_size)
	if error:
		print("Failed to create server. Error code: %d" % error)
		print("This might be due to port %d being in use or blocked" % host_port)
		return error
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer

	Network.connected_players[1] = Network.player_info
	Network.server_started.emit()
	Network.player_connected.emit(1, Network.player_info)
	Network.is_host = true
	print("ENet Server successfully hosted on port %d" % host_port)
	print("Server is ready for connections")

## Joins a game using an id in [Network]. See [Network.join_as_client] for more information
func join_as_client():
	var ip = Network.ip_address
	var port = PORT
	
	# Check if the ip_address contains a port (e.g., "192.168.1.1:8080")
	if ":" in ip:
		var parts = ip.split(":")
		ip = parts[0]
		port = int(parts[1])
	
	var error = peer.create_client(ip, port)
	if error:
		return error
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

	multiplayer.multiplayer_peer = peer
	Network.is_host = false
	
	if Network._is_verbose:
		print("ENet client connecting to %s:%d" % [ip, port])

## This does nothing as Enet does not have a lobby implementation. It is only here to prevent errors.
func list_lobbies():
	pass
#endregion
