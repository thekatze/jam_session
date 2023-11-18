extends Area2D

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.dropped_in_jam()


func _on_body_exited(body):
	if body.is_in_group("player"):
		body.left_jam()
	
