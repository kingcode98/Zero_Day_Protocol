  # res://scenes/UI/BattleUI.gd
  @tool
  extends Control

  # ---- Exported references (set in the editor) ----
  @export var battle_manager : NodePath   # e.g., "../BattleManager"
  @export var exploit_grid   : NodePath   # "VBoxContainer/GridContainer"
  @export var battle_log     : NodePath   # "BattleLog"
  @export var device_label   : NodePath   # "VBoxContainer/Label" (optional)

  # ---- Internal cache ----
  var _bm: BattleManager          # will be set in _ready()
  var _grid: GridContainer
  var _log: Label
  var _dev_label: Label

  func _ready() -> void:
        if battle_manager:
                _bm = get_node(battle_manager)
        __grid = get_node(exploit_grid)
        _log   = get_node(battle_log)
        if device_label:
                _dev_label = get_node(device_label)

        # Request the UI to rebuild whenever the player’s active device changes.
        # For MVP we assume BattleManager exposes a signal or a getter.
        if _bm:
                _bm.connect("active_device_changed", Callable(self, "_refresh_exploit_buttons"))
                _refresh_exploit_buttons()

  func _refresh_exploit_buttons() -> void:
        # Clear any old buttons
        for child in _grid.get_children():
                child.queue_free()

        # Fetch the player's active device from BattleManager
        var active_device: HackingDevice = _bm.get_active_device() if _bm else null
        if not active_device:
                _log.text = "No active device."
                return

        # Update optional device label
        if _dev_label:
                _dev_label.text = "%s Lv.%d" % [active_device.device_name, active_device.level]

        # Create a button for each exploit
        for exploit in active_device.exploits:
                var btn = Button.new()
                btn.text = exploit.name
                # Tooltip shows description & cost
                btn.tooltip_text = "%s\nCost: %d BW\nPower: %d" % [
                        exploit.description,
                        exploit.bandwidth_cost,
                        exploit.power
                ]
                # Connect the button press to our handler
                btn.pressed.connect(_on_exploit_pressed.bind(exploit))
                _grid.add_child(btn)

  func _on_exploit_pressed(exploit: Exploit) -> void:
        # Forward to BattleManager – we’ll implement this method next
        if _bm:
                _bm.execute_player_action(exploit)
                _log.text = "Selected: %s" % exploit.name
        else:
                push_error("BattleManager not set!")

  # Optional: a simple method to log battle results from BattleManager
  func log_message(msg: String) -> void:
        if _log:
                _log.text = msg
