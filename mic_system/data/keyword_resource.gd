extends Node

class KeywordFreqPair:
	var keyword: String
	var freq: float
	
	func _init(k: String = "", f: float = 0.0):
		keyword = k
		freq = f
