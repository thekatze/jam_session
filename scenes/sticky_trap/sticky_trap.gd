extends Area2D

var remaining_stickyness = 5
var belongs_to = -1
var color: Color

func _ready():
	if belongs_to >= 0:
		$Tile0153.modulate = color
		$Tile0155.modulate = color

func _physics_process(_delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.is_on_floor() and belongs_to != body.player_id:
			body.set_stuck(self)

func is_sticky():
	return remaining_stickyness > 0

func reduce_stickyness():
	remaining_stickyness -= 1
	if remaining_stickyness <= 0:
		queue_free()

