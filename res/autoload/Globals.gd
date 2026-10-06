# res://autoload/Globals.gd
extends Node

# Global game constants and state
const GAME_VERSION := "0.1.0"
const GAME_NAME := "Zero-Day: Protocol"

# Difficulty settings
var difficulty: String = "normal"  # easy, normal, hard, nightmare

# World state
var current_district: String = "Residential Sprawl"
var heat_level: float = 0.0  # 0.0 to 1.0, affects raid probability
var notoriety: float = 0.0   # 0.0 to 1.0, affects enemy difficulty

# Economic state (simplified)
var market_update_timer: float = 0.0
var market_update_interval: float = 900.0  # 15 minutes in seconds

# Player progression
var total_credibility_earned: int = 0
var total_opsec_lost: int = 0
var battles_won: int = 0
var battles_lost: int = 0

# Player Resources (Wallet, OpSec, Credibility, etc.)
var wallet: Dictionary = {
    "SEC": 0.0,   # SecurCoin
    "ANM": 0.0,   # AnonMonero
    "DOGE": 0.0,  # MemeDoge
    "ZD": 0.0,    # ZeroDay
    "NET": 0.0    # NetCoin
}

# Crafting Materials Inventory
var inventory: Dictionary = {
    "Microcontrollers": 0,
    "Lithium Cells": 0,
    "Copper Wire": 0,
    "Antennas": 0,
    "Thermal Paste": 0,
    "Silicon Chips": 0,
    "Gold Plating": 0,
    "Quantum Dots": 0
}

# Player Devices (Hacking devices the player owns)
var player_devices: Array = []

var opsec: int = 100  # Operational Security (0-100)
var credibility: int = 0  # Reputation/Street Cred (0-1000+)
var stamina: float = 100.0  # Current stamina
var max_stamina: float = 100.0  # Maximum stamina

# Save/Load slots
var current_save_slot: int = 1
var max_save_slots: int = 3

func _ready() -> void:
    # Initialize any global systems
    pass

# --- Wallet Methods ---

func add_coin(coin_type: String, amount: float) -> void:
    """Add cryptocurrency to wallet"""
    if wallet.has(coin_type):
        wallet[coin_type] = max(0.0, wallet[coin_type] + amount)
    else:
        wallet[coin_type] = max(0.0, amount)

func remove_coin(coin_type: String, amount: float) -> bool:
    """Remove cryptocurrency from wallet"""
    if not wallet.has(coin_type) or wallet[coin_type] < amount:
        return false
    wallet[coin_type] -= amount
    return true

func get_coin_amount(coin_type: String) -> float:
    """Get amount of specific cryptocurrency"""
    return wallet.get(coin_type, 0.0)

# --- Inventory Methods ---

func add_item(item: String, amount: int) -> void:
    """Add crafting material to inventory"""
    if inventory.has(item):
        inventory[item] = max(0, inventory[item] + amount)
    else:
        inventory[item] = max(0, amount)

func remove_item(item: String, amount: int) -> bool:
    """Remove crafting material from inventory"""
    if not inventory.has(item) or inventory[item] < amount:
        return false
    inventory[item] -= amount
    return true

def get_item_count(item: String) -> int:
    """Get amount of specific inventory item"""
    return inventory.get(item, 0)

# --- OpSec Methods ---

func add_opsec(amount: int) -> void:
    """Add OpSec (operational security)"""
    opsec = clamp(opsec + amount, 0, 100)

def remove_opsec(amount: int) -> void:
    """Remove OpSec (increases raid risk)"""
    opsec = clamp(opsec - amount, 0, 100)

def get_opsec() -> int:
    """Get current OpSec"""
    return opsec

# --- Credibility Methods ---

func add_credibility(amount: int) -> void:
    """Add credibility/reputation"""
    credibility = max(0, credibility + amount)

def remove_credibility(amount: int) -> void:
    """Remove credibility/reputation"""
    credibility = max(0, credibility - amount)

def get_credibility() -> int:
    """Get current credibility"""
    return credibility

# --- Stamina Methods ---

func add_stamina(amount: float) -> void:
    """Add stamina"""
    stamina = min(max_stamina, stamina + amount)

def consume_stamina(amount: float) -> bool:
    """Consume stamina if available"""
    if stamina >= amount:
        stamina -= amount
        return true
    return false

def get_stamina() -> float:
    """Get current stamina"""
    return stamina

def get_max_stamina() -> float:
    """Get maximum stamina"""
    return max_stamina

# --- Device Methods ---

func add_device(device_resource) -> void:
    """Add a hacking device to the player's collection"""
    if device_resource:
        player_devices.append(device_resource)

def remove_device(device_index: int) -> bool:
    """Remove a hacking device from the player's collection"""
    if device_index >= 0 and device_index < player_devices.size():
        player_devices.remove_at(device_index)
        return true
    return false

def get_device_count() -> int:
    """Get the number of devices the player owns"""
    return player_devices.size()

def get_device(index: int):
    """Get a device at the specified index"""
    if index >= 0 and index < player_devices.size():
        return player_devices[index]
    return null

# --- Save/Load System ---

func save_game(save_slot: int = 1) -> void:
    """Save the game state to a file"""
    var save_data = {
        "version": GAME_VERSION,
        "wallet": wallet,
        "inventory": inventory,
        "player_devices": player_devices,
        "opsec": opsec,
        "credibility": credibility,
        "stamina": stamina,
        "max_stamina": max_stamina,
        "current_district": current_district,
        "heat_level": heat_level,
        "notoriety": notoriety,
        "total_credibility_earned": total_credibility_earned,
        "total_opsec_lost": total_opsec_lost,
        "battles_won": battles_won,
        "battles_lost": battles_lost,
        "difficulty": difficulty,
        "timestamp": get_timestamp()
    }

    var save_file = FileAccess.open("user://savegame_%d.json" % save_slot, FileAccess.WRITE)
    if save_file:
        var json_string = JSON.print(save_data)
        save_file.store_string(json_string)
        save_file.close()
        print("Game saved to slot %d" % save_slot)
    else:
        print("ERROR: Could not save game to slot %d" % save_slot)

func load_game(save_slot: int = 1) -> void:
    """Load the game state from a file"""
    var save_file = FileAccess.open("user://savegame_%d.json" % save_slot, FileAccess.READ)
    if save_file:
        var json_string = save_file.get_as_text()
        save_file.close()

        var parse_result = JSON.parse_string(json_string)
        if parse_result.error != OK:
            print("ERROR: Could not parse save file")
            return

        var save_data = parse_result.result

        # Validate save data version
        if save_data.has("version"):
            # Optional: Handle version differences here
            pass

        # Load all game state
        if save_data.has("wallet"):
            wallet = save_data.wallet
        if save_data.has("inventory"):
            inventory = save_data.inventory
        if save_data.has("player_devices"):
            player_devices = save_data.player_devices
        if save_data.has("opsec"):
            opsec = save_data.opsec
        if save_data.has("credibility"):
            credibility = save_data.credibility
        if save_data.has("stamina"):
            stamina = save_data.stamina
        if save_data.has("max_stamina"):
            max_stamina = save_data.max_stamina
        if save_data.has("current_district"):
            current_district = save_data.current_district
        if save_data.has("heat_level"):
            heat_level = save_data.heat_level
        if save_data.has("notoriety"):
            notoriety = save_data.notoriety
        if save_data.has("total_credibility_earned"):
            total_credibility_earned = save_data.total_credibility_earned
        if save_data.has("total_opsec_lost"):
            total_opsec_lost = save_data.total_opsec_lost
        if save_data.has("battles_won"):
            battles_won = save_data.battles_won
        if save_data.has("battles_lost"):
            battles_lost = save_data.battles_lost
        if save_data.has("difficulty"):
            difficulty = save_data.difficulty

        print("Game loaded from slot %d" % save_slot)
    else:
        print("ERROR: Could not load game from slot %d (file not found)" % save_slot)

func get_timestamp() -> String:
    """Get current timestamp for saves/logs"""
    var time := OS.get_datetime()
    return "%04d-%02d-%02d %02d:%02d:%02d" % [
        time.year, time.month, time.day,
        time.hour, time.minute, time.second
    ]

# --- Utility Functions ---

func clamp(value: float, min_val: float, max_val: float) -> float:
    """Clamp a value between min and max"""
    return max(min_val, min(value, max_val))

func percent_to_value(percent: float, max_value: float) -> float:
    """Convert a percentage (0-100) to a value"""
    return (percent / 100.0) * max_value

func value_to_percent(value: float, max_value: float) -> float:
    """Convert a value to a percentage (0-100)"""
    if max_value == 0:
        return 0.0
    return clamp((value / max_value) * 100.0, 0.0, 100.0)

func format_currency(amount: float) -> String:
    """Format currency amount for display"""
    if amount >= 1000.0:
        return "%.1fK" % [amount / 1000.0]
    elif amount >= 1.0:
        return "%.2f" % [amount]
    else:
        return "%.4f" % [amount]