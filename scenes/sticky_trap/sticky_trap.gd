extends Area2D

var remaining_stickyness = 5

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.is_on_floor():
			body.set_stuck(self)

func is_sticky():
	return remaining_stickyness > 0

func reduce_stickyness():
	remaining_stickyness -= 1
	if remaining_stickyness <= 0:
		queue_free()

