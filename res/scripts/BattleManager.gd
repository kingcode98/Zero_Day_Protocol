# res://scripts/BattleManager.gd
extends Node
class_name BattleManager

# Signals
signal battle_started
signal battle_ended
signal turn_started
signal turn_ended
signal device_defeated
signal action_used
signal exploit_ready
signal opsec_changed

# Battle State
enum BattleState {
    PLAYER_TURN,
    ENEMY_TURN,
    RESOLVE_ACTION,
    BATTLE_END,
    PLAYER_WIN,
    PLAYER_LOSS
}

var current_state: BattleState = BattleState.PLAYER_TURN

# Battlefield
var grid_size: Vector2i = Vector2i(5, 5)  # 5x5 grid for MVP
var player_devices: Array[HackingDevice] = []
var enemy_devices: Array[HackingDevice] = []
var grid: Array[Array[HackingDevice]]  # 2D array representing battlefield

# Turn Management
var turn_order: Array[HackingDevice] = []
var current_turn_index: int = 0
var current_device: HackingDevice:

# Selected Action
var selected_exploit: Exploit = null
var selected_target: Vector2i = null
var action_in_progress: bool = false

# Battle Log
var battle_log: Array[String] = []

func _ready() -> void:
    randomize()
    _initialize_battle()

func _initialize_battle() -> void:
    """Set up the battlefield for a new encounter"""
    _create_empty_grid()
    _spawn_player_devices()
    _spawn_enemy_devices()
    _calculate_turn_order()
    _start_battle()

    emit_signal("battle_started")
    _log_battle("--- SYSTEM BREACH INITIATED ---")

func _create_empty_grid() -> void:
    """Create an empty grid for the battlefield"""
    grid = []
    for y in grid_size.y:
        var row: Array[HackingDevice] = []
        for x in grid_size.x:
            row.append(null)
        grid.append(row)

func _spawn_player_devices() -> void:
    """Spawn player devices at starting positions"""
    # For MVP, place player devices at bottom of grid
    var start_y: int = grid_size.y - 1
    for i in player_devices.size():
        if i < grid_size.x:  # Don't exceed grid width
            var x_pos: int = i
            grid[start_y][x_pos] = player_devices[i]
            # Set device position for reference
            player_devices[i].grid_position = Vector2i(x_pos, start_y)

func _spawn_enemy_devices() -> void:
    """Spawn enemy devices at starting positions"""
    # For MVP, place enemy devices at top of grid
    var start_y: int = 0
    for i in enemy_devices.size():
        if i < grid_size.x:  # Don't exceed grid width
            var x_pos: int = i
            grid[start_y][x_pos] = enemy_devices[i]
            # Set device position for reference
            enemy_devices[i].grid_position = Vector2i(x_pos, start_y)

func _calculate_turn_order() -> void:
    """Calculate turn order based on processing speed"""
    turn_order.clear()
    turn_order.append_array(player_devices)
    turn_order.append_array(enemy_devices)
    # Sort by processing speed (higher = earlier turn)
    turn_order.sort_custom(self, "_compare_by_processing")
    current_turn_index = 0
    _update_current_device()

func _compare_by_processing(device_a: HackingDevice, device_b: HackingDevice) -> int:
    """Comparison function for sorting by processing speed"""
    if device_a.processing_speed > device_b.processing_speed:
        return -1  # a comes before b
    elif device_a.processing_speed < device_b.processing_speed:
        return 1   # b comes before a
    else:
        return 0   # equal

func _update_current_device() -> void:
    """Update the current device reference"""
    if turn_order.size() > 0 and current_turn_index < turn_order.size():
        current_device = turn_order[current_turn_index]
        # Reset device stats for new turn
        if current_device:
            current_device._reset_turn_stats()
            emit_signal("turn_started", current_device)
    else:
        current_device = null

func _start_battle() -> void:
    """Start the battle"""
    current_state = BattleState.PLAYER_TURN
    _update_current_device()

func end_turn() -> void:
    """End the current device's turn and move to next"""
    if current_device:
        # Apply turn-end effects (cooldown reduction, etc.)
        for exploit in current_device.exploits:
            exploit.update_cooldown()

        # Regenerate resources
        current_device.regenerate_bandwidth(current_device.max_bandwidth_per_turn)

        emit_signal("turn_ended", current_device)

    # Move to next device in turn order
    current_turn_index += 1

    # Check if we've gone through all devices
    if current_turn_index >= turn_order.size():
        # Check if battle should continue
        var player_alive: bool = _count_alive_devices(player_devices) > 0
        var enemy_alive: bool = _count_alive_devices(enemy_devices) > 0

        if not player_alive:
            _end_battle(BattleState.PLAYER_LOSS)
        elif not enemy_alive:
            _end_battle(BattleState.PLAYER_WIN)
        else:
            # Start new round
            current_turn_index = 0
            # Alternate between player and enemy turns for simplicity
            # In a more complex version, we'd continue through the sorted order
            if turn_order.size() > 0:
                # Simple approach: even indices = player turn, odd = enemy turn
                # Actually, let's just alternate teams for MVP
                var is_player_turn: bool = (current_turn_index % 2 == 0)
                current_state = is_player_turn ? BattleState.PLAYER_TURN : BattleState.ENEMY_TURN
            else:
                current_state = BattleState.PLAYER_TURN
    else:
        # Still devices left in current round
        current_state = BattleState.PLAYER_TURN  # Simplified for MVP

    _update_current_device()

func _count_alive_devices(devices: Array[HackingDevice]) -> int:
    """Count how many devices in an array are still alive"""
    var count: int = 0
    for device in devices:
        if device and not device.is_defeated():
            count += 1
    return count

func _end_battle(result: BattleState) -> void:
    """End the battle with a result"""
    current_state = result
    emit_signal("battle_ended", result)

    if result == BattleState.PLAYER_WIN:
        _log_battle("VICTORY: System breach successful!")
        _award_victory_rewards()
    elif result == BattleState.PLAYER_LOSS:
        _log_battle("DEFEAT: Connection terminated by countermeasures.")
        _apply_defeat_penalties()

    # Reset for next battle
    _reset_battle_state()

func _award_victory_rewards() -> void:
    """Award rewards for winning the battle"""
    # Award expertise to participating devices
    for device in player_devices:
        if device and not device.is_defeated():
            var expertise_gained: int = 10 + device.level * 2
            device.gain_expertise(expertise_gained)
            _log_battle("%s gained %d expertise" % [device.device_name, expertise_gained])

    # Award cryptocurrency (simplified)
    var player_data: PlayerData = get_node("/root/PlayerData")
    if player_data:
        player_data.add_coin("ANM", 25.0 + randf() * 15.0)  # 25-40 ANM
        _log_battle("Earned %d ANM" % [int(25.0 + randf() * 15.0)])

func _apply_defeat_penalties() -> void:
    """Apply penalties for losing the battle"""
    _log_battle("OpSec compromised due to defeat.")
    # In a full game, this would increase heat/attract attention

func _reset_battle_state() -> void:
    """Reset battle state for next encounter"""
    current_state = BattleState.PLAYER_TURN
    turn_order.clear()
    current_turn_index = 0
    current_device = null
    selected_exploit = null
    selected_target = null
    action_in_progress = false

func execute_player_action(exploit: Exploit, target_pos: Vector2i) -> void:
    """Execute a player-selected action"""
    if current_state != BattleState.PLAYER_TURN or not current_device:
        _log_battle("Not player's turn or no active device!")
        return

    if not current_device.can_use_exploit(exploit):
        _log_battle("Cannot use %s: insufficient resources" % [exploit.name])
        return

    # Validate target
    if !_is_valid_target(target_pos):
        _log_battle("Invalid target position")
        return

    # Use the exploit
    current_device.use_exploit(exploit)
    selected_exploit = exploit
    selected_target = target_pos
    action_in_progress = true

    _log_battle("Player uses %s" % [exploit.name])
    emit_signal("action_used", exploit, target_pos)

    # Resolve the action
    _resolve_action(exploit, target_pos)

    # End turn after action
    end_turn()

func _is_valid_target(pos: Vector2i) -> bool:
    """Check if a target position is valid"""
    return pos.x >= 0 and pos.x < grid_size.x and \
           pos.y >= 0 and pos.y < grid_size.y

func _resolve_action(exploit: Exploit, target_pos: Vector2i) -> void:
    """Resolve the action effect"""
    var target_device: HackingDevice = grid[target_pos.y][target_pos.x]

    if not target_device:
        _log_battle("No target at position (%d, %d)" % [target_pos.x, target_pos.y])
        return

    # Check if exploit hits (based on accuracy)
    var hit_chance: int = exploit.accuracy
    # Modify based on distance, signal strength, etc.
    var distance: float = _calculate_distance(current_device.grid_position, target_pos)
    var distance_penalty: int = int(distance * 5)  # 5% penalty per tile
    hit_chance = max(5, hit_chance - distance_penalty)

    if exploit.get_exploit_success(0):  # Using device's exploit success method
        _apply_exploit_effect(exploit, target_device)
        _log_battle("%s hits %s for %d %s!" % [
            exploit.name,
            target_device.device_name,
            exploit.power,
            exploit.effect_type
        ])
    else:
        _log_battle("%s misses %s!" % [exploit.name, target_device.device_name])

func _apply_exploit_effect(exploit: Exploit, target: HackingDevice) -> void:
    """Apply the effect of an exploit to a target"""
    match exploit.effect_type:
        "damage":
            target.take_opsec_damage(exploit.power)
            if target.is_defeated():
                _on_device_defeated(target)
        "stun":
            # For simplicity, we'll apply a temporary effect
            # In full version, we'd have a stun status effect
            _log_battle("%s is stunned!" % [target.device_name])
        "buff":
            # Apply buff to attacker or ally
            _log_battle("Buff applied!")
        "debuff":
            # Apply debuff to target
            _log_battle("Debuff applied!")
        "heal":
            # Healing would increase OpSec (up to max)
            var old_opsec: int = target.opsec
            target.opsec = min(100, target.opsec + int(exploit.effect_value))
            _log_battle("%s recovered %d OpSec" % [target.device_name, target.opsec - old_opsec])
        "bw_drain":
            # Drain bandwidth from target
            var drain_amount: int = int(exploit.effect_value)
            target.current_bandwidth = max(0, target.current_bandwidth - drain_amount)
            _log_battle("%s BW drained by %d" % [target.device_name, drain_amount])
        "charge_drain":
            # Drain exploit charges
            var drain_amount: int = int(exploit.effect_value)
            target.exploit_charges = max(0, target.exploit_charges - drain_amount)
            _log_battle("%s exploit charges drained by %d" % [target.device_name, drain_amount])
        else:
            _log_battle("Unknown effect type: %s" % [exploit.effect_type])

func _on_device_defeated(device: HackingDevice) -> void:
    """Handle when a device is defeated"""
    _log_battle("%s has been neutralized!" % [device.device_name])
    emit_signal("device_defeated", device)

    # Remove from grid
    if device.grid_position:
        var pos: Vector2i = device.grid_position
        grid[pos.y][pos.x] = null

    # Remove from respective arrays
    if device in player_devices:
        player_devices.erase(device)
    elif device in enemy_devices:
        enemy_devices.erase(device)

    # Recalculate turn order if battle continues
    if current_state != BattleState.BATTLE_END:
        _calculate_turn_order()

func _calculate_distance(pos_a: Vector2i, pos_b: Vector2i) -> float:
    """Calculate distance between two positions"""
    return sqrt(pow(pos_a.x - pos_b.x, 2) + pow(pos_a.y - pos_b.y, 2))

func _log_battle(message: String) -> void:
    """Add a message to the battle log"""
    battle_log.append(message)
    print("[BATTLE] %s" % [message])
    # In full version, would also update UI

# --- Public API for UI to call ---

func get_battle_state() -> BattleState:
    """Get current battle state"""
    return current_state

func get_current_device() -> HackingDevice:
    """Get the device whose turn it is"""
    return current_device

func get_player_devices() -> Array[HackingDevice]:
    """Get player's devices"""
    return player_devices

func get_enemy_devices() -> Array[HackingDevice]:
    """Get enemy devices"""
    return enemy_devices

func get_grid() -> Array[Array[HackingDevice]]:
    """Get the battle grid"""
    return grid

func get_battle_log() -> Array[String]:
    """Get the battle log"""
    return battle_log

func clear_battle_log() -> void:
    """Clear the battle log"""
    battle_log.clear()

func is_player_turn() -> bool:
    """Check if it's the player's turn"""
    return current_state == BattleState.PLAYER_TURN

func get_available_exploits() -> Array[Exploit]:
    """Get exploits usable by current device"""
    if not current_device:
        return []
    var usable: Array[Exploit] = []
    for exploit in current_device.exploits:
        if current_device.can_use_exploit(exploit):
            usable.append(exploit)
    return usable

# --- Device Management ---

func set_player_devices(devices: Array[HackingDevice]) -> void:
    """Set the player's device party"""
    player_devices = devices.duplicate()
    # Limit to 4 active devices for battle
    if player_devices.size() > 4:
        player_devices.resize(4)

func set_enemy_devices(devices: Array[HackingDevice]) -> void:
    """Set the enemy devices for this encounter"""
    enemy_devices = devices.duplicate()

func add_player_device(device: HackingDevice) -> void:
    """Add a device to the player's party"""
    if player_devices.size() < 4:
        player_devices.append(device)

func remove_player_device(device: HackingDevice) -> void:
    """Remove a device from the player's party"""
    player_devices.erase(device)