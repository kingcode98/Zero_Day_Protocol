# res://scripts/casino_terminal.gd
extends Node
class_name CasinoTerminal

# Signals
signal crypto_won(coin_type: String, amount: float)
signal crypto_lost(coin_type: String, amount: float)
signal bet_placed(coin_type: String, amount: float)

# References
@onready var interactable: Interactable = $Interaction
@onready var globals: Globals = Globals.singleton
@onready var ui_panel: Node = $UICasinoPanel
@onready var bet_amount_label: Label = $UICasinoPanel/BetAmountLabel
@onready var coin_type_label: Label = $UICasinoPanel/CoinTypeLabel
@onready var result_label: Label = $UICasinoPanel/ResultLabel
@onready var hack_button: Button = $UICasinoPanel/HackButton
@onready var sec_button: Button = $UICasinoPanel/SECBetButton
@onready var doge_button: Button = $UICasiniPanel/DOGEBetButton
@onready var anm_button: Button = $UICasinoPanel/ANMBetButton

# Casino Configuration
@export var win_chance: float = 0.48  # 48% win chance
@export var bet_options: Array = [1, 5, 10, 25, 50, 100]  # Available bet amounts
@export var current_bet_index: int = 2  # Default to 10
@export var current_coin_type: String = "DOGE"  # Default coin type

# State
var is_betting: bool = false
var current_bet_amount: float = 0

func _ready() -> void:
    # Setup interactable
    interactable.interaction_text = "Gamble"

    # Connect signals
    interactable.connect("interacted", _callable(self, _on_interacted))
    hack_button.connect("pressed", _callable(self, _on_hack_button_pressed))
    sec_button.connect("pressed", _callable(self, _on_sec_button_pressed))
    doge_button.connect("pressed", _callable(self, _on_doge_button_pressed))
    anm_button.connect("pressed", _callable(self, _on_anm_button_pressed))

    # Initialize UI
    _update_ui()
    ui_panel.visible = False  # Start hidden

func _on_interacted() -> void:
    """Handle when player interacts with the casino terminal"""
    print("CasinoTerminal: Player interacted!")

    # Toggle UI visibility
    ui_panel.visible = not ui_panel.visible
    is_betting = ui_panel.visible

    if is_betting:
        # Reset to default bet when opening
        _reset_bet()
    else:
        # Clear result when closing
        result_label.text = ""

func _on_sec_button_pressed() -> void:
    """Handle SEC bet button pressed"""
    current_coin_type = "SEC"
    _update_ui()

func _on_doge_button_pressed() -> void:
    """Handle DOGE bet button pressed"""
    current_coin_type = "DOGE"
    _update_ui()

func _on_anm_button_pressed() -> void:
    """Handle ANM bet button pressed"""
    current_coin_type = "ANM"
    _update_ui()

func _on_hack_button_pressed() -> void:
    """Handle hack button pressed - play the game"""
    if not globals or is_betting == false:
        return

    var bet_amount: float = bet_options[current_bet_index]

    # Check if player can afford the bet
    var coin_balance: float = globals.get_coin_amount(current_coin_type)
    if coin_balance < bet_amount:
        result_label.text = "INSUFFICIENT FUNDS"
        result_label.color = Color(1, 0.3, 0.3)  # Reddish
        return

    # Place the bet (deduct from wallet)
    if globals.remove_coin(current_coin_type, bet_amount):
        emit_signal("bet_placed", current_coin_type, bet_amount)
        current_bet_amount = bet_amount

        # Determine win/loss
        var rand: float = randf()  # Random float between 0 and 1
        if rand < win_chance:
            # Win! Double the bet
            var winnings: float = bet_amount * 2.0
            globals.add_coin(current_coin_type, winnings)

            result_label.text = "WIN! +%.0f %s" % [winnings, current_coin_type]
            result_label.color = Color(0.3, 1, 0.3)  # Greenish
            emit_signal("crypto_won", current_coin_type, winnings)
            print("CasinoTerminal: Won %.0f %s" % [winnings, current_coin_type])
        else:
            # Lose
            result_label.text = "LOSS! -%.0f %s" % [bet_amount, current_coin_type]
            result_label.color = Color(1, 0.3, 0.3)  # Reddish
            emit_signal("crypto_lost", current_coin_type, bet_amount)
            print("CasinoTerminal: Lost %.0f %s" % [bet_amount, current_coin_type])

        # Brief delay before allowing another bet
        yield(get_tree().create_timer(0.5), "timeout")
        result_label.text = ""
    else:
        result_label.text = "BET FAILED"
        result_label.color = Color(1, 0.3, 0.3)  # Reddish

func _update_ui() -> void:
    """Update the UI elements"""
    if bet_amount_label:
        bet_amount_label.text = "BET: %d" % bet_options[current_bet_index]
    if coin_type_label:
        coin_type_label.text = current_coin_type
    # Reset result label when changing bet/coin
    result_label.text = ""

func _next_bet() -> void:
    """Cycle to the next bet option"""
    current_bet_index = (current_bet_index + 1) % bet_options.size()
    _update_ui()

func _previous_bet() -> void:
    """Cycle to the previous bet option"""
    current_bet_index = (current_bet_index - 1 + bet_options.size()) % bet_options.size()
    _update_ui()

func _reset_bet() -> void:
    """Reset bet to default values"""
    current_bet_index = 2  # Default to 10
    current_coin_type = "DOGE"
    _update_ui()

# --- Public API ---

func get_win_chance() -> float:
    """Get the current win chance"""
    return win_chance

func set_win_chance(chance: float) -> void:
    """Set the win chance (0.0 to 1.0)"""
    win_chance = clamp(chance, 0.0, 1.0)

func is_ui_visible() -> bool:
    """Check if the casino UI is currently visible"""
    return ui_panel.visible if ui_panel else false