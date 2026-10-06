# res://scripts/Player.gd
extends Node
class_name PlayerManager

# Signals
signal overworld_position_changed
signal device_swapped
signal opsec_changed
signal credibility_changed
signal coins_updated

# Player State (Overworld)
@export var overworld_position: Vector2i = Vector2i(0, 0)
@export var opsec: int = 100  # Operational Security (affects raid risk)
@export var credibility: int = 0  # Reputation (affects job availability)
@export var stamina: float = 100.0
@export var max_stamina: float = 100.0

# Reference to PlayerData (singleton)
var player_data: PlayerData

func _ready() -> void:
    player_data = get_node("/root/PlayerData")
    if not player_data:
        push_error("PlayerManager: Could not find PlayerData singleton!")
    _sync_with_player_data()

func _sync_with_player_data() -> void:
    """Sync this manager's state with PlayerData"""
    if player_data:
        # Sync wallet
        # Note: We're not syncing devices/inventory here as PlayerData is the source of truth
        pass

func get_active_device() -> HackingDevice:
    """Get the player's currently active device"""
    return player_data.get_active_device()

func set_overworld_position(pos: Vector2i) -> void:
    """Set the player's position in the overworld"""
    overworld_position = pos
    emit_signal("overworld_position_changed", pos)

func move_overworld(direction: Vector2i) -> void:
    """Move the player in the overworld (to be used with pathfinding)"""
    var new_pos: Vector2i = overworld_position + direction
    # In full version, would check for obstacles, etc.
    set_overworld_position(new_pos)

    # Consume stamina for movement
    stamina = max(0, stamina - 10.0)
    if stamina <= 0:
        _trigger_fatigue()

func _trigger_fatigue() -> void:
    """Handle when player runs out of stamina"""
    _log_player("Need to rest to recover stamina.")
    # In full version, would force rest or reduce effectiveness

func regenerate_stamina(amount: float) -> void:
    """Regenerate stamina over time or when resting"""
    stamina = min(max_stamina, stamina + amount)

func get_stamina() -> float:
    """Get current stamina"""
    return stamina

func get_max_stamina() -> float:
    """Get maximum stamina"""
    return max_stamina

def add_opsec(amount: int) -> void:
    """Add OpSec (operational security)"""
    opsec = clamp(opsec + amount, 0, 100)
    emit_signal("opsec_changed", opsec)

def remove_opsec(amount: int) -> void:
    """Remove OpSec (increases raid risk)"""
    opsec = clamp(opsec - amount, 0, 100)
    emit_signal("opsec_changed", opsec)
    if opsec < 20:
        _log_player("OpSec low! Increased risk of raids.")

def add_credibility(amount: int) -> void:
    """Add credibility/reputation"""
    credibility = max(0, credibility + amount)
    emit_signal("credibility_changed", credibility)

def remove_credibility(amount: int) -> void:
    """Remove credibility/reputation"""
    credibility = max(0, credibility - amount)
    emit_signal("credibility_changed", credibility)

def add_coins(coin_type: String, amount: float) -> void:
    """Add cryptocurrency to wallet"""
    player_data.add_coin(coin_type, amount)
    emit_signal("coins_updated", coin_type, player_data.get_coin(coin_type))

def remove_coins(coin_type: String, amount: float) -> bool:
    """Remove cryptocurrency from wallet"""
    var success: bool = player_data.remove_coin(coin_type, amount)
    if success:
        emit_signal("coins_updated", coin_type, player_data.get_coin(coin_type))
    return success

def get_coin_amount(coin_type: String) -> float:
    """Get amount of specific cryptocurrency"""
    return player_data.get_coin(coin_type)

def get_active_device_name() -> String:
    """Get the name of the active device"""
    var device: HackingDevice = get_active_device()
    return device ? device.device_name : "None"

func _log_player(message: String) -> void:
    """Log a player-related message"""
    print("[PLAYER] %s" % [message])
    # In full version, would also feed to UI/log system