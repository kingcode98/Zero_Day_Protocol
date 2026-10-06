# res://scripts/workbench.gd
extends Node
class_name Workbench

# Signals
signal crafting_menu_requested

# References
@onready var interactable: Interactable = $Interaction
@onready var crafting_menu_instance: Node = $CraftingMenuInstance
@onready var globals: Globals = Globals.singleton
@onready var player_manager: Node = get_node_or_null("/root/PlayerManager")

# State
var is_menu_open: bool = false

func _ready() -> void:
    # Initially hide the crafting menu instance
    if crafting_menu_instance:
        crafting_menu_instance.visible = False

    # Setup interactable
    interactable.interaction_text = "Craft"

    # Connect signals
    interactable.connect("interacted", _callable(self, _on_interacted))

    # Get reference to crafting menu script if it exists
    var crafting_menu: Node = crafting_menu_instance
    if crafting_menu and crafting_menu.has_method("_open_menu"):
        # We'll call this method when interactable is used
        pass

func _on_interacted() -> void:
    """Handle when player interacts with the workbench"""
    print("Workbench: Player interacted!")

    # Get the player's active device
    var active_device: HackingDevice = null
    if player_manager and player_manager.has_method("get_active_device"):
        active_device = player_manager.get_active_device()
    elif globals:
        # Fallback: try to get from globals or PlayerData
        pass

    if not active_device:
        # Show message that no device is available
        _show_no_device_message()
        return

    // Open the crafting menu with the active device
    _open_crafting_menu(active_device)

func _open_crafting_menu(device: HackingDevice) -> void:
    """Open the crafting menu for the given device"""
    if crafting_menu_instance:
        var menu_script: Node = crafting_menu_instance
        if menu_script and menu_script.has_method("_open_menu"):
            menu_script.call("_open_menu", device)
            crafting_menu_instance.visible = True
            is_menu_open = true
            emit_signal("crafting_menu_requested")

func _show_no_device_message() -> void:
    """Show a message that no active device is available for crafting"""
    # In a full implementation, this would show a UI toast or notification
    print("Workbench: No active device selected for crafting!")

func _close_crafting_menu() -> void:
    """Close the crafting menu"""
    if crafting_menu_instance:
        crafting_menu_instance.visible = False
        is_menu_open = false
        if crafting_menu_instance.has_method("_close_menu"):
            crafting_menu_instance.call("_close_menu")

# --- Public API ---

func is_menu_open() -> bool:
    """Check if the crafting menu is currently open"""
    return is_menu_open

func set_player_manager(manager: Node) -> void:
    """Set the player manager reference"""
    player_manager = manager