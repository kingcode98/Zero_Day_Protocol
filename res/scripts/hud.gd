# res://scripts/hud.gd
extends CanvasLayer
class_name HUD

# Signals
signal joystick_moved(direction: Vector2)
signal interaction_requested
signal overworld_menu_toggled
signal battle_menu_toggled

# References
@onready var opsec_label: Label = $MarginContainer/VBoxContainer/OpSecFrame/OpSecLabel
@onready var cred_label: Label = $MarginContainer/VBoxContainer/CredFrame/CredLabel
@onready var stamina_label: Label = $MarginContainer/VBoxContainer/StaminaFrame/StaminaLabel
@onready var sec_label: Label = $MarginContainer/VBoxContainer/CurrencyFrame/CurrencyHBox/SECLabel
@onready var anm_label: Label = $MarginContainer/VBoxContainer/CurrencyFrame/CurrencyHBox/ANMLabel
@onready var doge_label: Label = $MarginContainer/VBoxContainer/CurrencyFrame/CurrencyHBox/DOGELabel
@onready var zd_label: Label = $MarginContainer/VBoxContainer/CurrencyFrame/CurrencyHBox/ZDLabel
@onready var minimap: TextureRect = $MarginContainer/VBoxContainer/MinimapFrame/Minimap
@onready var combat_ui: CanvasLayer = $CombatUI
@onready var exploit_grid: GridContainer = $CombatUI/CombatPanel/ActionPanel/ActionVBox/ExploitGrid
@onready var battle_log: TextEdit = $CombatUI/CombatPanel/ActionPanel/ActionVBox/BattleLog
@onready var action_label: Label = $CombatUI/CombatPanel/ActionPanel/ActionVBox/ActionLabel

# State
var player_manager: PlayerManager
var battle_manager: BattleManager
var is_in_combat: bool = false

func _ready() -> void:
    player_manager = get_node("/root/PlayerManager")
    battle_manager = get_node("/root/Main/BattleInstance/BattleManager")

    if player_manager:
        player_manager.connect("opsec_changed", _callable(self, _update_opsec))
        player_manager.connect("credibility_changed", _callable(self, _update_cred))
        player_manager.connect("coins_updated", _callable(self, _update_coins))

    if battle_manager:
        battle_manager.connect("action_used", _callable(self, _on_action_used))
        battle_manager.connect("battle_ended", _callable(self, _on_battle_ended))
        battle_manager.connect("device_defeated", _callable(self, _on_device_defeated))

    _update_all_displays()
    _hide_combat_ui()  # Start in overworld mode

func _update_opsec(value: int) -> void:
    if opsec_label:
        opsec_label.text = "OpSec: %d/100" % [value]

func _update_cred(value: int) -> void:
    if cred_label:
        cred_label.text = "Cred: %d" % [value]

func _update_coins(coin_type: String, amount: float) -> void:
    match coin_type:
        "SEC":
            if sec_label: sec_label.text = "SEC: %.1f" % [amount]
        "ANM":
            if anm_label: anm_label.text = "ANM: %.1f" % [amount]
        "DOGE":
            if doge_label: doge_label.text = "DOGE: %.1f" % [amount]
        "ZD":
            if zd_label: zd_label.text = "ZD: %.1f" % [amount]

func _update_all_displays() -> void:
    if player_manager:
        _update_opsec(player_manager.opsec)
        _update_cred(player_manager.credibility)
        _update_coins("SEC", player_manager.get_coin_amount("SEC"))
        _update_coins("ANM", player_manager.get_coin_amount("ANM"))
        _update_coins("DOGE", player_manager.get_coin_amount("DOGE"))
        _update_coins("ZD", player_manager.get_coin_amount("ZD"))

func _show_combat_ui() -> void:
    if combat_ui:
        combat_ui.visible = true
        is_in_combat = true
        _update_combat_ui()

func _hide_combat_ui() -> void:
    if combat_ui:
        combat_ui.visible = false
        is_in_combat = false

func _update_combat_ui() -> void:
    if not battle_manager or not is_in_combat:
        return

    # Update action label
    var state: BattleManager.BattleState = battle_manager.get_battle_state()
    match state:
        BattleManager.BattleState.PLAYER_TURN:
            action_label.text = "Select Action"
        BattleManager.BattleState.ENEMY_TURN:
            action_label.text = "Enemy Turn..."
        BattleManager.BattleState.RESOLVE_ACTION:
            action_label.text = "Resolving Action..."
        default:
            action_label.text = "Battle Active"

    # Update exploit buttons
    _update_exploit_buttons()

    # Update battle log
    if battle_log:
        var log_text: String = battle_manager.get_battle_log().join("\n")
        battle_log.text = log_text
        # Scroll to bottom
        battle_log.scroll_to_line(battle_log.get_line_count())

func _update_exploit_buttons() -> void:
    if not exploit_grid:
        return

    # Clear existing buttons (except first 6 which we'll reuse)
    var children: Array = exploit_grid.get_children()
    for i in children.size():
        if i >= 6:  # Keep only first 6 buttons
            children[i].queue_free()

    # Get available exploits
    var exploits: Array[Exploit] = battle_manager.get_available_exploits()

    # Update button texts
    for i in min(exploits.size(), 6):
        var button: Button = exploit_grid.get_child(i) as Button
        if button and exploits[i]:
            button.text = exploits[i].name
            button.set_tooltip_text(exploits[i].get_tooltip())
            button.disabled = false

    # Disable unused buttons
    for i in exploits.size():  # Start from where we left off
        if i < children.size():
            var button: Button = exploit_grid.get_child(i) as Button
            if button:
                button.disabled = true
                button.text = ""

func _on_action_used(exploit: Exploit, target_pos: Vector2i) -> void:
    _update_combat_ui()
    # In full version, would show animation/effect at target position

func _on_battle_ended(result: int) -> void:
    var result_text: String = ""
    match result:
        BattleManager.BattleState.PLAYER_WIN:
            result_text = "VICTORY!"
        BattleManager.BattleState.PLAYER_LOSS:
            result_text = "DEFEAT!"
        default:
            result_text = "Battle Ended"

    action_label.text = result_text
    # Show result for a moment then return to overworld
    yield(get_tree().create_timer(2.0), "timeout")
    _hide_combat_ui()

func _on_device_defeated(device: HackingDevice) -> void:
    if device:
        action_label.text = "%s neutralized!" % [device.device_name]

func _on_joystick_moved(direction: Vector2) -> void:
    emit_signal("joystick_moved", direction)

func _on_interaction_requested() -> void:
    emit_signal("interaction_requested")

func _on_overworld_menu_toggled() -> void:
    emit_signal("overworld_menu_toggled")

func _on_battle_menu_toggled() -> void:
    emit_signal("battle_menu_toggled")

# --- Public API ---

func set_player_manager(manager: PlayerManager) -> void:
    player_manager = manager
    if player_manager:
        player_manager.connect("opsec_changed", _callable(self, _update_opsec))
        player_manager.connect("credibility_changed", _callable(self, _update_cred))
        player_manager.connect("coins_updated", _callable(self, _update_coins))
    _update_all_displays()

func set_battle_manager(manager: BattleManager) -> void:
    battle_manager = manager
    if battle_manager:
        battle_manager.connect("action_used", _callable(self, _on_action_used))
        battle_manager.connect("battle_ended", _callable(self, _on_battle_ended))
        battle_manager.connect("device_defeated", _callable(self, _on_device_defeated))