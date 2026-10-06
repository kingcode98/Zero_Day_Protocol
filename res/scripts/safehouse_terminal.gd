extends Node

func _input(command):
	match command:
		"save":
			Globals.save_game()
		"load":
			Globals.load_game()
		_:
			pass