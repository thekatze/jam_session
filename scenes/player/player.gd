extends CharacterBody2D

@export var player_id : int = 0
@export var trap_scene : PackedScene
@export var player_colors : PackedColorArray

var stuck_counter = 0
var sticky_trap
var orientation = 1 # 1 => looking right; -1 => looking left;
var is_in_air = false
var is_in_jam = true

const SPEED = 400.0
const JUMP_VELOCITY = -460.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func set_stuck(trap):
	if not is_stuck():
		$SfxStuck.play()
		sticky_trap = trap
		velocity.x = 0

func is_stuck():
	return is_instance_valid(sticky_trap) and sticky_trap.is_sticky()

func _ready():
	# set player color
	var gradient : GradientTexture2D = $Sprite2D.texture
	gradient = gradient.duplicate(true)
	gradient.gradient.colors[1] = player_colors[player_id]
	$Sprite2D.texture = gradient

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		is_in_air = true
	else:
		if is_in_air and not is_in_jam:
			# only once on land
			$SfxLand.play()
		is_in_air = false
		
	if Input.is_action_just_pressed("attack_%s" % player_id) and is_on_floor() and not is_in_jam:
		var trap = trap_scene.instantiate()
		trap.belongs_to = self.player_id
		trap.color = player_colors[player_id]
		trap.position = self.position + Vector2($TrapPlacementPosition.position.x * orientation, $TrapPlacementPosition.position.y)
		get_tree().current_scene.add_child(trap)

	if not is_stuck():
		# Handle Jump.
		if Input.is_action_just_pressed("jump_%s" % player_id) and is_on_floor():
			velocity.y = JUMP_VELOCITY
			$SfxJump.play()

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("move_left_%s" % player_id, "move_right_%s" % player_id)
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED/4)
		
		# set orientation
		if abs(velocity.x) > 0.01:
			if velocity.x > 0:
				orientation = 1
				$Sprite2D.flip_h = false
			else:
				orientation = -1
				$Sprite2D.flip_h = true
	else:
		if Input.is_action_just_pressed("move_left_%s" % player_id):
			sticky_trap.reduce_stickyness()
			$SfxFootStuckLeft.play()
		if Input.is_action_just_pressed("move_right_%s" % player_id):
			sticky_trap.reduce_stickyness()
			$SfxFootStuckRight.play()

	move_and_slide()

func dropped_in_jam():
	is_in_jam = true
	$SfxDropInJam.play()
	
func left_jam():
	is_in_jam = false
