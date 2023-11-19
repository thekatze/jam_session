extends RigidBody2D

var push_velocity : Vector2

func _process(delta):
	$Sprite2D.rotate(10 * delta)

func _on_body_entered(body):
	if body.is_in_group("player"):
		queue_free()
		body.stun()
		body.velocity = push_velocity
