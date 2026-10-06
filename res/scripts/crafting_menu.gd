# res://scripts/crafting_menu.gd
extends CanvasLayer
class_name CraftingMenu

# Signals
signal menu_closed
signal upgrade_applied(upgrade_type: String, level: int)

# References
@onready var globals: Globals = Globals.singleton
@onready var player_manager: Node = get_node_or_null("/root/PlayerManager")

# UI References
@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var device_info_label: Label = $PanelContainer/VBoxContainer/DeviceInfoLabel
@onready var materials_label: Label = $PanelContainer/VBoxContainer/MaterialsLabel
@onready var upgrade_vbox: VBoxContainer = $PanelContainer/VBoxContainer/UpgradeOptions
@onready var close_button: Button = $PanelContainer/CloseButton

# Crafting Recipes
# Format: { "name": "Upgrade Name", "material": "material_type", "cost": amount, "stat": "device_stat", "bonus": bonus_per_level }
var recipes: Dictionary = {
    "mcu": {
        "name": "Overclocked MCU",
        "material": "Microcontrollers",
        "cost": 2,
        "stat": "processing_speed",
        "bonus": 3,
        "description": "+3 Processing Speed per level"
    },
    "battery": {
        "name": "High-Capacity Battery",
        "material": "Lithium Cells",
        "cost": 3,
        "stat": "bandwidth_capacity",
        "bonus": 15,
        "description": "+15 Bandwidth Capacity per level"
    },
    "antenna": {
        "name": "Enhanced Antenna",
        "material": "Copper Wire",
        "cost": 1,
        "stat": "signal_strength",
        "bonus": 2,
        "description": "+2 Signal Strength per level"
    },
    "heat_sink": {
        "name": "Efficient Heat Sink",
        "material": "Thermal Paste",
        "cost": 2,
        "stat": "durability",
        "bonus": 3,
        "description": "+3 Durability per level"
    },
    "firmware": {
        "name": "Exploit Firmware",
        "material": "Silicon Chips",
        "cost": 4,
        "stat": "exploit_success_rate",
        "bonus": 5,
        "description": "+5% Exploit Success Rate per level (max 95%)"
    }
}

# State
var active_device: HackingDevice = null
var is_open: bool = false

func _ready() -> void:
    panel.visible = False
    is_open = False

    # Connect signals
    if close_button:
        close_button.pressed.connect(_callable(self, _close_menu))

    # Update inventory display periodically
    yield(get_tree().create_timer(1.0), "timeout")
    _update_inventory_display()

func _open_menu(device: HackingDevice) -> void:
    """Open the crafting menu for a specific device"""
    active_device = device
    panel.visible = True
    is_open = True
    _update_device_info()
    _update_inventory_display()
    _build_upgrade_options()

func _close_menu() -> void:
    """Close the crafting menu"""
    panel.visible = False
    is_open = False
    active_device = null
    _clear_upgrade_options()
    emit_signal("menu_closed")

func _update_device_info() -> void:
    """Update the displayed device information"""
    if active_device:
        var info = "%s Lv.%d\n" % [active_device.device_name, active_device.level]
        info += "OpSec: %d/%d\n" % [active_device.opsec, 100]
        info += "BW: %d/%d\n" % [active_device.current_bandwidth, active_device.bandwidth_capacity]
        info += "Charges: %d/%d" % [active_device.exploit_charges, active_device.max_exploit_charges]
        device_info_label.text = info
    else:
        device_info_label.text = "No active device"

func _update_inventory_display() -> void:
    """Update the materials inventory display"""
    if not globals:
        return

    var text = "AVAILABLE MATERIALS:\n"
    var materials: Array[String] = ["Microcontrollers", "Lithium Cells", "Copper Wire", "Thermal Paste", "Silicon Chips", "Antennas", "Gold Plating", "Quantum Dots"]
    for material in materials:
        var count: int = globals.get_item_count(material)
        text += "%s: %d\n" % [material, count]
    materials_label.text = text

func _build_upgrade_options() -> void:
    """Build the upgrade option buttons"""
    _clear_upgrade_options()

    if not active_device:
        return

    for upgrade_key in recipes.keys():
        var recipe: Dictionary = recipes[upgrade_key]
        var current_level: int = active_device.upgrade_levels.get(upgrade_key, 0)

        # Create container for this upgrade
        var hbox: HBoxContainer = HBoxContainer.new()
        hbox.name = "%s_upgrade" % [upgrade_key]
        hbox.add_theme_constant("separation", 10)
        upgrade_vbox.add_child(hbox)

        # Add label
        var label: Label = Label.new()
        label.text = "%s (Lv.%d)" % [recipe["name"], current_level]
        label.tooltip_text = recipe["description"]
        hbox.add_child(label)

        # Add spacer
        var spacer: Control = Control.new()
        spacer.set_h_size_flag(Control.SIZE_EXPAND)
        hbox.add_child(spacer)

        # Add cost label
        var cost_label: Label = Label.new()
        cost_label.name = "cost_label"
        var material_count: int = globals.get_item_count(recipe["material"])
        var can_afford: bool = material_count >= recipe["cost"]
        cost_label.text = "%d %s" % [recipe["cost"], recipe["material"]]
        if not can_afford:
            cost_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))  # Red if can't afford
        hbox.add_child(cost_label)

        # Add upgrade button
        var upgrade_button: Button = Button.new()
        upgrade_button.name = "upgrade_button"
        upgrade_button.text = "Upgrade"
        upgrade_button.disabled = not can_afford
        upgrade_button.tooltip_text = "Spend %d %s to upgrade" % [recipe["cost"], recipe["material"]]
        upgrade_button.pressed.connect(_callable(self, _on_upgrade_pressed).bind(upgrade_key, recipe))
        hbox.add_child(upgrade_button)

func _clear_upgrade_options() -> void:
    """Clear all upgrade option UI elements"""
    var children: Array = upgrade_vbox.get_children()
    for child in children:
        child.queue_free()

func _on_upgrade_pressed(upgrade_key: String, recipe: Dictionary) -> void:
    """Handle when an upgrade button is pressed"""
    if not active_device or not globals:
        return

    var material_count: int = globals.get_item_count(recipe["material"])
    if material_count < recipe["cost"]:
        # Not enough materials
        return

    # Spend materials
    globals.remove_item(recipe["material"], recipe["cost"])

    # Apply upgrade
    var current_level: int = active_device.upgrade_levels.get(upgrade_key, 0)
    var new_level: int = current_level + 1
    active_device.upgrade_levels[upgrade_key] = new_level
    active_device._apply_upgrade_effects()

    # Update UI
    _update_inventory_display()
    _build_upgrade_options()
    _update_device_info()

    # Emit signal
    emit_signal("upgrade_applied", upgrade_key, new_level)

# --- Public API ---

func is_menu_open() -> bool:
    """Check if the crafting menu is currently open"""
    return is_open

func set_active_device(device: HackingDevice) -> void:
    """Set the active device for upgrading"""
    active_device = device
    if is_open:
        _update_device_info()
        _build_upgrade_options()