# res://scripts/HackingDevice.gd
extends Resource
class_name HackingDevice

# Device Stats (from GDD)
@export var device_name: String = "Unknown Device"
@export var specialty: String = "Undefined"  # Determines move pool specialization

# Core Stats
@export var processing_speed: int = 10  # Determines turn order & action cooldown reduction
@export var bandwidth_capacity: int = 100  # Max BW storage
@export var exploit_success_rate: int = 70  # Base chance for abilities to land (percentage)
@export var signal_strength: int = 1  # Range & penetration through network nodes
@export var durability: int = 10  # Resistance to counter-measures (HP/OpSec)
@export var level: int = 1

# Current Battle State
@export var current_bandwidth: int = 100  # Current BW available this turn
@export var max_bandwidth_per_turn: int = 30  # BW regen per turn
@export var exploit_charges: int = 2  # Limited uses of high-impact abilities
@export var max_exploit_charges: int = 3  # Maximum exploit charges
@export var opsec: int = 100  # Operational Security (HP in battle)

# Equipment & Upgrades
@export var exploits: Array[Exploit] = []  # Equipped exploits (abilities)
@export var upgrade_levels: Dictionary = {
    "antenna": 0,
    "mcu": 0,
    "battery": 0,
    "firmware": 0,
    "heat_sink": 0
}

# Experience & Progression
@export var expertise: int = 0
@export var expertise_to_next_level: int = 100

func _ready() -> void:
    _reset_turn_stats()

func _reset_turn_stats() -> void:
    """Reset stats at start of turn"""
    current_bandwidth = bandwidth_capacity
    # Exploit charges regen or restore based on devices/upgrades

func calculate_initiative() -> float:
    """Calculate initiative for turn order (higher = earlier turn)"""
    # Base on processing speed, with some randomness for variety
    return processing_speed + randf() * 5.0

func can_use_exploit(exploit: Exploit) -> bool:
    """Check if device can use a given exploit"""
    if exploit.current_cooldown > 0:
        return false
    if exploit.bw_cost > current_bandwidth:
        return false
    if exploit.exploit_chiyet_cost > exploit_charges:
        return false
    return true

func use_exploit(exploit: Exploit) -> void:
    """Use an exploit, consuming resources"""
    if can_use_exploit(exploit):
        current_bandwidth -= exploit.bw_cost
        exploit_charges -= exploit.exploit_chiyet_cost
        exploit.use()  # Start cooldown

def regenerate_bandwidth(amount: int) -> void:
    """Regenerate bandwidth (called at start of turn or via effects)"""
    current_bandwidth = min(bandwidth_capacity, current_bandwidth + amount)

def regenerate_exploit_charges(amount: int) -> void:
    """Regenerate exploit charges"""
    exploit_charges = min(max_exploit_charges, exploit_charges + amount)

def take_opsec_damage(amount: int) -> void:
    """Take OpSec damage (durability reduces effectiveness)"""
    # Durability reduces incoming OpSec loss
    mitigated = int(amount * (durability / 100.0))  # Simplified: higher durability = less damage taken
    actual_damage = max(1, amount - mitigated)
    opsec = max(0, opsec - actual_damage)

def is_defeated() -> bool:
    """Check if device is defeated (0 OpSec)"""
    return opsec <= 0

func gain_expertise(amount: int) -> void:
    """Gain expertise points and check for level up"""
    expertise += amount
    while expertise >= expertise_to_next_level:
        _level_up()

func _level_up() -> void:
    """Level up the device"""
    expertise -= expertise_to_next_level
    level += 1
    expertise_to_next_level = int(expertise_to_next_level * 1.5)  # Increasing curve

    # Stats increase on level up
    processing_speed += 2
    bandwidth_capacity += 10
    exploit_success_rate = min(95, exploit_success_rate + 5)
    signal_strength += 1
    durability += 2

    # Restore some OpSec on level up
    opsec = min(100, opsec + 20)

    print("%s leveled up to level %d!" % [device_name, level])

# Upgrade functions
func apply_upgrade(upgrade_type: String, level: int) -> void:
    """Apply an upgrade to the device"""
    if upgrade_levels.has(upgrade_type):
        upgrade_levels[upgrade_type] = level
        _apply_upgrade_effects()

func _apply_upgrade_effects() -> void:
    """Apply effects from equipped upgrades"""
    # Reset to base values first
    var base_processing = processing_speed
    var base_bandwidth = bandwidth_capacity
    var base_signal = signal_strength
    var base_durability = durability

    # Apply upgrade effects (simplified)
    processing_speed = base_processing + (upgrade_levels["mcu"] * 3)
    bandwidth_capacity = base_bandwidth + (upgrade_levels["battery"] * 15)
    signal_strength = base_signal + (upgrade_levels["antenna"] * 2)
    durability = base_durability + (upgrade_levels["heat_sink"] * 3)

    # Regenerate resources to new max
    current_bandwidth = bandwidth_capacity

func get_exploit_success(accuracy_modifier: int = 0) -> bool:
    """Calculate if an exploit succeeds based on skill and modifier"""
    var final_accuracy = exploit_success_rate + accuracy_modifier
    final_accuracy = clamp(final_accuracy, 5, 95)  # Clamp between 5% and 95%
    return randi() % 100 < final_accuracy

func get_debug_string() -> String:
    """Get debug string for device stats"""
    return "%s Lv.%d | OpSec: %d/%d | BW: %d/%d | Charges: %d/%d" % [
        device_name, level, opsec, 100, current_bandwidth, bandwidth_capacity,
        exploit_charges, max_exploit_charges
    ]