extends Node2D

var small_font = preload("res://assets/fonts/entity_number_font.tres")
var big_font = preload("res://assets/fonts/entity_number_big_font.tres")

onready var label = $Label

func _ready():
	if G.global_scale_factor <= 1.0:
		label.set("custom_fonts/font", small_font)
	else:
		label.set("custom_fonts/font", big_font)
