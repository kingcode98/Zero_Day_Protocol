extends Node

# Prices
const WIFI_PINEAPPLE_PRICE_ANM = 500
const USB_RUBBER_DUCKY_PRICE_SEC = 300

func buy_wifi_pineapple():
	if Globals.ANM >= WIFI_PINEAPPLE_PRICE_ANM:
		Globals.ANM -= WIFI_PINEAPPLE_PRICE_ANM
		var item = preload("res://items/wi_fi_pineapple.tres")
		Globals.player_devices.append(item)
		return true
	else:
		push_error("Not enough ANM to buy Wi-Fi Pineapple")
		return false

func buy_usb_rubber_ducky():
	if Globals.SEC >= USB_RUBBER_DUCKY_PRICE_SEC:
		Globals.SEC -= USB_RUBBER_DUCKY_PRICE_SEC
		var item = preload("res://items/usb_rubber_ducky.tres")
		Globals.player_devices.append(item)
		return true
	else:
		push_error("Not enough SEC to buy USB Rubber Ducky")
		return false

func load_ui():
	var ui_scene = preload("res://scenes/UI/DarkWebMenu.tscn")
	if ui_scene:
		var ui_instance = ui_scene.instantiate()
		get_tree().root.add_child(ui_instance)
	else:
		push_error("Failed to load DarkWebMenu scene")