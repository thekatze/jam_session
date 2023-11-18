extends CharacterBody2D

@export var player_id : int = 0

var stuck_counter = 0
var sticky_trap

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func set_stuck(trap):
	sticky_trap = trap
	velocity.x = 0

func is_stuck():
	return is_instance_valid(sticky_trap) and sticky_trap.is_sticky()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	if not is_stuck():
		# Handle Jump.
		if Input.is_action_just_pressed("jump_%s" % player_id) and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("move_left_%s" % player_id, "move_right_%s" % player_id)
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		if Input.is_action_just_pressed("move_left_%s" % player_id) \
		or Input.is_action_just_pressed("move_right_%s" % player_id):
			sticky_trap.reduce_stickyness()

	move_and_slide()
