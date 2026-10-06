# res://scripts/npc_hacker.gd
extends Node
class_name NPC_Hacker

# References
@onready var interactable: Interactable = $Interaction
@onready var sprite: Sprite2D = $Sprite2D

# Enemy Configuration
@export var enemy_device_scene: String = "res://devices/wi_fi_pineapple.tres"
@export var enemy_level: int = 2
@export var enemy_count: int = 1  # Number of enemy devices in encounter
@export var battle_description: String = "Corporate ICE Node"

# State
var enemy_device_template: HackingDevice = null
var battle_manager: BattleManager = null

func _ready() -> void:
    # Load the enemy device template
    var resource_loader: ResourceLoader = ResourceLoader.singleton
    enemy_device_template = resource_loader.load(enemy_device_scene) as HackingDevice

    if not enemy_device_template:
        push_error("NPC_Hacker: Failed to load enemy device from %s" % [enemy_device_scene])
        return

    # Configure the interactable
    interactable.interaction_text = "Hack Node (%d)" % [enemy_count]

    # Connect signals
    interactable.connect("interacted", _callable(self, _on_interacted))

    # Find the BattleManager in the scene
    _find_battle_manager()

    # Optional: Add visual indicator for interactable
    _setup_visual_indicator()

func _find_battle_manager() -> void:
    """Find the BattleManager in the current scene tree"""
    # Search up the tree for a node named BattleInstance/BattleManager
    var current: Node = self
    while current:
        if current.name == "BattleInstance":
            var bm: Node = current.get_node_or_null("BattleManager")
            if bm and bm is BattleManager:
                battle_manager = bm as BattleManager
                return
        current = current.get_parent()
    # If not found by name, try to get it from root/Main/BattleInstance/BattleManager
    var root: Node = get_tree().get_current_scene()
    while root and root.get_parent():
        root = root.get_parent()
    if root:
        battle_manager = root.get_node_or_null("Main/BattleInstance/BattleManager") as BattleManager

func _setup_visual_indicator() -> void:
    """Add a simple visual indicator that this is interactable"""
    # Could add a glowing effect, particles, etc.
    # For now, just make sure sprite is visible
    if sprite:
        sprite.modulate = Color(1, 1, 1, 1)  # Full opacity

func _on_interacted() -> void:
    """Handle when player interacts with this NPC"""
    print("NPC_Hacker: Player interacted!")

    if not battle_manager:
        push_error("NPC_Hacker: BattleManager not found! Cannot start battle.")
        return

    # Create enemy devices from template
    var enemy_devices: Array[HackingDevice] = []
    for i in enemy_count:
        # Duplicate the template for each enemy device
        var enemy_device: HackingDevice = enemy_device_template.duplicate() as HackingDevice

        # Apply level scaling
        enemy_device.level = enemy_level
        _apply_level_scaling(enemy_device, enemy_level)

        enemy_devices.append(enemy_device)

    # Start the battle with these enemy devices
    battle_manager.set_enemy_devices(enemy_devices)

    # Switch to combat mode by showing the combat UI
    var hud: CanvasLayer = get_node("/root/Main/HUD")
    if hud:
        hud.call("_show_combat_ui")  # Call the private method to show combat UI

    # Optional: Play interaction sound or effect
    _play_interaction_effect()

func _apply_level_scaling(device: HackingDevice, level: int) -> void:
    """Apply level-based stat scaling to a device"""
    if level <= 1:
        return

    var level_multiplier: float = 1.0 + (level - 1) * 0.2  # 20% increase per level after 1

    device.processing_speed = int(device.processing_speed * level_multiplier)
    device.bandwidth_capacity = int(device.bandwidth_capacity * level_multiplier)
    device.exploit_success_rate = min(95, int(device.exploit_success_rate * level_multiplier))
    device.signal_strength = int(device.signal_strength * level_multiplier)
    device.durability = int(device.durability * level_multiplier)

    # Scale exploit powers and costs
    for exploit in device.exploits:
        exploit.power = int(exploit.power * level_multiplier)
        exploit.bw_cost = int(exploit.bw_cost * level_multiplier)
        # Keep exploit_chiyet_cost the same or increase slightly
        exploit.exploit_chiyet_cost = min(5, exploit.exploit_chiyet_cost + (level - 1) * 0.5)

func _play_interaction_effect() -> void:
    """Play a visual/audio effect when interacted with"""
    # Flash the sprite briefly
    if sprite:
        var original_modulate: Color = sprite.modulate
        sprite.modulate = Color(1, 0.5, 0.5)  # Reddish flash
        yield(get_tree().create_timer(0.1), "timeout")
        sprite.modulate = original_modulate

# --- Public API ---

func set_enemy_device(device_scene: String) -> void:
    """Change the enemy device type"""
    enemy_device_scene = device_scene
    var resource_loader: ResourceLoader = ResourceLoader.singleton
    enemy_device_template = resource_loader.load(device_scene) as HackingDevice

func get_battle_description() -> String:
    """Get description for this encounter"""
    return battle_description