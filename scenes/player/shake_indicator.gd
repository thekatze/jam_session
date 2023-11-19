extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Left.visible = true
	$Right.visible = false



func _on_timer_timeout():
	$Left.visible = !$Left.visible
	$Right.visible = !$Right.visible
