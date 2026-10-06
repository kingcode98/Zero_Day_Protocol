# res://scripts/joystick.gd
extends Control
class_name Joystick

# Signals
signal joystick_moved(direction: Vector2)
signal joystick_pressed
signal joystick_released

# Joystick Settings
@export var dead_zone: float = 0.2
@export var snap_back_speed: float = 10.0

# Knob References
@onready var knob: TextureRect = $JoystickKnob
@onready var bg_rect: TextureRect = $JoystickBG

# State Variables
var is_pressed: bool = false
var knob_offset: Vector2 = Vector2.ZERO
var original_knob_position: Vector2

func _ready() -> void:
    original_knob_position = knob.position
    _set_mouse_filter(MOUSE_FILTER_PASS)  # Allow clicks to pass through

func _gui_input(event) -> void:
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            if event.pressed:
                _on_joystick_pressed(event.position)
            else:
                _on_joystick_released()
    elif event is InputEventMouseMotion and is_pressed:
        _on_joystick_drag(event.position)

func _on_joystick_pressed(screen_pos: Vector2) -> void:
    is_pressed = true
    emit_signal("joystick_pressed")
    _update_knob_position(screen_pos)

func _on_joystick_released() -> void:
    is_pressed = false
    emit_signal("joystick_released")
    _snap_knob_back()

func _on_joystick_drag(screen_pos: Vector2) -> void:
    if is_pressed:
        _update_knob_position(screen_pos)

func _update_knob_position(screen_pos: Vector2) -> void:
    # Convert screen position to local coordinates relative to joystick center
    var joystick_center: Vector2 = bg_rect.get_global_center()
    var local_pos: Vector2 = screen_pos - joystick_center

    # Clamp to joystick radius
    var radius: float = bg_rect.size.x * 0.5
    var clamped_pos: Vector2 = local_pos.clamped(radius)

    # Apply dead zone
    if clamped_pos.length() < radius * dead_zone:
        clamped_pos = Vector2.ZERO

    knob.offset = clamped_pos
    knob_offset = clamped_pos

    # Normalize to -1 to 1 range for game input
    if radius > 0:
        var normalized: Vector2 = clamped_pos / radius
        emit_signal("joystick_moved", normalized)
    else:
        emit_signal("joystick_moved", Vector2.ZERO)

func _snap_knob_back() -> void:
    # Snap knob back to center with smooth animation would be done via tween
    # For simplicity, we'll just set it directly
    knob.offset = Vector2.ZERO
    knob_offset = Vector2.ZERO
    emit_signal("joystick_moved", Vector2.ZERO)

# --- Public API ---

func get_direction() -> Vector2:
    """Get current joystick direction (-1 to 1 range)"""
    if knob_offset.length() > 0:
        var radius: float = bg_rect.size.x * 0.5
        if radius > 0:
            return knob_offset / radius
    return Vector2.ZERO

func is_active() -> bool:
    """Check if joystick is currently being pressed"""
    return is_pressed