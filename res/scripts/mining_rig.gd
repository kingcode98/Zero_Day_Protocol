# res://scripts/mining_rig.gd
extends Node
class_name MiningRig

# Signals
signal hashrate_upgraded(new_hashrate: float)
signal crypto_earned(coin_type: String, amount: float)

# References
@onready var interactable: Interactable = $Interaction
@onready var globals: Globals = Globals.singleton

# Mining Configuration
@export var base_hashrate: float = 0.1  # Base amount per cycle
@export var hashrate: float = 0.1      # Current hashrate (can be upgraded)
@export var cycle_time: float = 5.0    # Seconds between mining cycles
@export var mine_sec: bool = true      # Whether to mine SEC (if false, mines DOGE)
@export var mine_doge: bool = false    # Whether to mine DOGE

# State
var mining_timer: Timer = null
var is_mining: bool = false
var upgrade_cost_base: float = 10.0    # Base cost for hashrate upgrade
var upgrade_cost_multiplier: float = 1.5 # Cost increases exponentially

func _ready() -> void:
    # Setup interactable
    interactable.interaction_text = "Mine"

    # Connect signals
    interactable.connect("interacted", _callable(self, _on_interacted))

    # Create and setup mining timer
    _setup_mining_timer()

    # Start mining automatically
    start_mining()

func _setup_mining_timer() -> void:
    """Create and configure the mining timer"""
    mining_timer := Timer.new()
    mining_timer.name = "MiningTimer"
    mining_timer.wait_time = cycle_time
    mining_timer.autostart = false
    mining_timer.one_shot = false
    mining_timer.connect("timeout", _callable(self, _on_mining_cycle))
    add_child(mining_timer)

func _on_interacted() -> void:
    """Handle when player interacts with the mining rig"""
    print("MiningRig: Player interacted!")

    // Show upgrade UI or toggle mining state
    _attempt_hashrate_upgrade()

func _on_mining_cycle() -> void:
    """Handle each mining cycle - earn crypto"""
    if not is_mining or not globals:
        return

    var earned_amount: float = hashrate
    var coin_type: String = ""

    if mine_sec:
        coin_type = "SEC"
    elif mine_doge:
        coin_type = "DOGE"
    else:
        // Default to SEC if neither is set
        coin_type = "SEC"

    // Add earned crypto to wallet
    globals.add_coin(coin_type, earned_amount)

    // Emit signal
    emit_signal("crypto_earned", coin_type, earned_amount)

    // Optional: Log mining activity
    print("MiningRig: Earned %.4f %s" % [earned_amount, coin_type])

func _attempt_hashrate_upgrade() -> void:
    """Attempt to upgrade hashrate if player can afford the cost"""
    if not globals:
        return

    var upgrade_cost: int = int(upgrade_cost_base * pow(upgrade_cost_multiplier, hashrate / base_hashrate - 1.0))
    var doge_amount: float = globals.get_coin_amount("DOGE")

    if doge_amount >= upgrade_cost:
        // Spend DOGE to upgrade
        if globals.remove_coin("DOGE", upgrade_cost):
            // Increase hashrate
            var old_hashrate: float = hashrate
            hashrate += base_hashrate * 0.5  // 50% increase per upgrade

            // Update timer if needed (faster cycles with higher hashrate)
            // Actually, let's keep cycle time constant and just increase amount per cycle

            emit_signal("hashrate_upgraded", hashrate)
            print("MiningRig: Hashrate upgraded to %.4f (cost: %d DOGE)" % [hashrate, upgrade_cost])
        else:
            print("MiningRig: Failed to spend DOGE for upgrade")
    else:
        print("MiningRig: Need %d DOGE to upgrade hashrate (have %.2f)" % [upgrade_cost, doge_amount])

func start_mining() -> void:
    """Start the mining operation"""
    is_mining = true
    if mining_timer:
        mining_timer.start()

func stop_mining() -> void:
    """Stop the mining operation"""
    is_mining = false
    if mining_timer:
        mining_timer.stop()

# --- Public API ---

func get_hashrate() -> float:
    """Get current hashrate"""
    return hashrate

func set_mine_sec(value: boolean) -> void:
    """Set whether to mine SEC"""
    mine_sec = value
    mine_doge = not value  # Toggle opposite

func set_mine_doge(value: boolean) -> void:
    """Set whether to mine DOGE"""
    mine_doge = value
    mine_sec = not value  # Toggle opposite

func get_cycle_time() -> float:
    """Get current cycle time"""
    return cycle_time