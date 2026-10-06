 # res://autoload/PlayerData.gd
  extends Node

  # ---- Singleton accessor ----
  var _instance: PlayerData = null
  func _ready() -> void:
        if _instance:
                push_error("PlayerData singleton already instantiated!")
                queue_free()
        else:
                _instance = self

  # ---- Player‑party (HackingDevice resources) ----
  # These are *references* to resources saved elsewhere (e.g. res://devices/flipper_zero.tres)
  var devices: Array[HackingDevice] = []      # owned devices
  var active_device_index: int = 0            # which device is currently equipped

  func get_active_device() -> HackingDevice:
        return devices.size() > 0 ? devices[active_device_index] : null

  func set_active_device(idx: int) -> void:
        if devices.size() == 0: return
        active_device_index = wrap(idx, 0, devices.size())
        emit_signal("active_device_changed")

  signal active_device_changed   # emitted whenever the equipped device swaps

  # ---- Crafting‑material inventory ----
  # Key = material name (String), Value = amount (int)
  var inventory: Dictionary = {
        "Microcontrollers": 0,
        "Lithium Cells": 0,
        "Copper Wire": 0,
        "Antennas": 0,
        "Thermal Paste": 0
        # add more as needed
  }

  func add_item(item: String, amount: int) -> void:
        if not inventory.has(item):
                inventory[item] = 0
        inventory[item] = max(0, inventory[item] + amount)   # never go below 0

  func remove_item(item: String, amount: int) -> bool:
        if not inventory.has(item) or inventory[item] < amount:
                return false
        inventory[item] -= amount
        return true

  # ---- Cryptocurrency wallet ----
  # Key = coin ticker (String), Value = amount (float – we allow fractional coins)
  var wallet: Dictionary = {
        "SEC": 0.0,   # SecurCoin
        "ANM": 0.0,   # AnonMonero
        "DOGE": 0.0   # MemeDoge
  }

  func add_coin(coin: String, amount: float) -> void:
        if not wallet.has(coin):
                wallet[coin] = 0.0
        wallet[coin] = max(0.0, wallet[coin] + amount)

  func remove_coin(coin: String, amount: float) -> bool:
        if not wallet.has(coin) or wallet[coin] < amount:
                return false
        wallet[coin] -= amount
        return true

  func get_coin(coin: String) -> float:
        return wallet.has(coin) ? wallet[coin] : 0.0
