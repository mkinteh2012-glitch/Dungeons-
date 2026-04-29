extends Node

signal coins_changed(new_amount) # 1. Make sure this exists at the top

var coins: int = 0

func add_coins(amount: int):
	coins += amount
	print("Coins in terminal: ", coins) # This is working for you!
	coins_changed.emit(coins)	
