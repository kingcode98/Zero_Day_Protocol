# res://scenes/player.gd
extends CharacterBody2D
class_name OverworldPlayer

# Signals
signal position_changed(new_position: Vector2i)
signal interaction_attempted(position: Vector2i)
signal device_scanned(device_info: Dictionary)

# Movement Settings
@export var speed: float = 150.0
@export var stamina: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 10.0  # Per second while dashing
@export var dash_speed_multiplier: float = 2.0

# State Variables
var is_dashing: bool = false
var stamina_regen_timer: float = 0.0
var interaction_range: int = 64  # Pixels for interaction range

# Cached References
var sprite: Sprite2D
var collision_shape: CollisionShape2D

func _ready() -> void:
    sprite = $Sprite2D
    collision_shape = $CollisionShape2D
    if not sprite:
        push_warning("OverworldPlayer: No Sprite2D node found!")
    if not collision_shape:
        push_warning("OverworldPlayer: No CollisionShape2D node found!")

func _physics_process(delta: float) -> void:
    _handle_stamina(delta)
    _handle_movement(delta)
    _handle_interaction()

func _handle_stamina(delta: float) -> void:
    """Manage stamina regeneration and dash consumption"""
    if is_dashing:
        stamina = max(0, stamina - stamina_drain_rate * delta)
        if stamina <= 0:
            _end_dash()
    else:
        # Regenerate stamina when not dashing
        if stamina < max_stamina:
            stamina_regen_timer += delta
            if stamina_regen_timer >= 0.5:  # Regen every 0.5 seconds
                stamina = min(max_stamina, stamina + 5.0)
                stamina_regen_timer = 0.0

func _handle_movement(delta: float) -> void:
    """Handle player movement based on input"""
    var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    if input_dir.length() > 0:
        var is_dash_attempt: bool = Input.is_action_just_pressed("ui_dash") and stamina >= 20.0

        if is_dash_attempt:
            _start_dash(input_dir)
        else:
            _end_dash()  # Ensure we're not dashing if dash wasn't pressed

        var effective_speed: float = speed
        if is_dashing:
            effective_speed *= dash_speed_multiplier

        velocity = input_dir * effective_speed
        move_and_slide()

        # Update facing direction based on movement
        if input_dir.x != 0:
            sprite.flip_h = input_dir.x < 0
    else:
        velocity = Vector2.ZERO
        _end_dash()  # Stop dashing if no input

func _start_dash(direction: Vector2) -> void:
    """Start dashing in the given direction"""
    if not is_dashing and stamina >= 20.0:
        is_dashing = true
        # Could add dash visual effects here

func _end_dash() -> void:
    """End the dash state"""
    is_dashing = false

func _handle_interaction() -> void:
    """Handle interaction input (scan/long-press equivalent)"""
    if Input.is_action_just_pressed("ui_interact"):  # Would be set up in project settings
        var mouse_pos: Vector2 = get_global_mouse_position()
        var player_pos: Vector2 = global_position
        var distance_to_mouse: float = player_pos.distance_to(mouse_pos)

        if distance_to_mouse <= interaction_range:
            emit_signal("interaction_attempted", mouse_pos.floor())
            # In full version, would raycast or check for interactable objects

# --- Public API ---

func set_position_grid(pos: Vector2i) -> void:
    """Set position using grid coordinates (for tile-based movement)"""
    # Assuming 32x32 tiles - adjust based on your tileset
    var world_pos: Vector2 = pos * 32.0
    global_position = world_pos
    emit_signal("position_changed", pos)

func get_position_grid() -> Vector2i:
    """Get position in grid coordinates"""
    var world_pos: Vector2 = global_position
    return Vector2i(int(world_pos.x / 32), int(world_pos.y / 32))

func add_stamina(amount: float) -> void:
    """Add stamina (for items, resting, etc.)"""
    stamina = min(max_stamina, stamina + amount)

func consume_stamina(amount: float) -> bool:
    """Consume stamina if available"""
    if stamina >= amount:
        stamina -= amount
        return true
    return false

func is_stamina_full() -> bool:
    """Check if stamina is at maximum"""
    return stamina >= max_stamina

# --- Debug ---

func _log_player(message: String) -> void:
    """Log a player-related message"""
    print("[OVERWORLD PLAYER] %s" % [message])