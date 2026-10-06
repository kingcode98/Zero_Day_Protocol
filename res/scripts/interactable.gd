# res://scripts/interactable.gd
extends Area2D
class_name Interactable

# Signals
signal interacted

# Configuration
@export var interaction_radius: float = 32.0  # Radius for interaction detection
@export var interaction_text: String = "Interact"  # Text to show when in range
@export var show_interaction_prompt: bool = true  # Whether to show prompt UI

# State
var player_in_range: bool = false
var interaction_prompt: Control = null

func _ready() -> void:
    # Setup collision shape if not present (should be added in inheriting scenes)
    if not get_node_or_null("CollisionShape2D"):
        # Create a circular collision shape for interaction radius
        var collision_shape: CircleShape2D = CircleShape2D.new()
        collision_shape.radius = interaction_radius
        var collision_shape_node: CollisionShape2D = CollisionShape2D.new()
        collision_shape_node.shape = collision_shape
        add_child(collision_shape_node)
        collision_shape_node.name = "InteractionCollision"

    # Connect body enter/exit signals
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    # Create interaction prompt if enabled
    if show_interaction_prompt:
        _create_interaction_prompt()

func _create_interaction_prompt() -> void:
    """Create a simple text prompt that appears when player is in range"""
    interaction_prompt = Label.new()
    interaction_prompt.name = "InteractionPrompt"
    interaction_prompt.text = interaction_text
    interaction_prompt.align = 2  # Center
    interaction_prompt.valign = 2  # Center
    interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 0.8))  # Light yellow
    interaction_prompt.add_theme_font_size_override("font_size", 16)
    interaction_prompt.visible = False
    add_child(interaction_prompt)

    # Position above the interactable
    interaction_prompt.position = Vector2(0, -40)

func _on_body_entered(body: Node) -> void:
    """Called when a body enters the interaction area"""
    # Check if it's the player (you could use groups or specific checks)
    if body.has_method("get_position_grid"):  # Simple check for player-like node
        player_in_range = True
        if interaction_prompt:
            interaction_prompt.visible = True
        _log_interactable("Player entered interaction range")

func _on_body_exited(body: Node) -> void:
    """Called when a body exits the interaction area"""
    if body.has_method("get_position_grid"):  # Simple check for player-like node
        player_in_range = False
        if interaction_prompt:
            interaction_prompt.visible = False
        _log_interactable("Player exited interaction range")

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
    """Handle input events (for mouse clicks on the area)"""
    if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
        if player_in_range:
            _try_interact()

func _try_interact() -> void:
    """Attempt to trigger interaction"""
    if player_in_range:
        emit_signal("interacted")
        _log_interactable("Interaction triggered")
        # Hide prompt briefly to prevent spam
        if interaction_prompt:
            interaction_prompt.visible = False
            yield(get_tree().create_timer(0.5), "timeout")
            if player_in_range:  # Show again if still in range
                interaction_prompt.visible = True

func _log_interactable(message: String) -> void:
    """Log interactable-related messages"""
    print("[INTERACTABLE] %s" % [message])

# --- Public API ---

func is_player_in_range() -> bool:
    """Check if player is currently in interaction range"""
    return player_in_range

func set_interaction_text(text: String) -> void:
    """Update the interaction prompt text"""
    interaction_text = text
    if interaction_prompt:
        interaction_prompt.text = text